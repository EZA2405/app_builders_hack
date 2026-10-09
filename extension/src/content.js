(() => {
  // A same-origin parent owns this frame's DOM and listeners.
  if (window !== window.top) {
    try { if (window.parent.document) return; } catch { /* Cross-origin boundary: own this subtree. */ }
  }
  let refPrefix = "";
  let framePath = [];
  const ROLES = new Set(["button", "link", "tab", "menuitem", "menuitemcheckbox", "menuitemradio", "checkbox", "radio", "switch", "combobox", "textbox", "searchbox", "option", "slider", "treeitem"]);
  const SELECTOR = 'a[href],button,input:not([type="hidden"]),select,textarea,summary,[contenteditable="true"],[role],[onclick],[tabindex]:not([tabindex="-1"])';
  const refs = new Map();
  let serial = 0;
  const compact = (text, max) => String(text || "").replace(/\s+/g, " ").trim().slice(0, max);

  function parentElement(el) {
    return el.parentElement || el.getRootNode().host ||
      (el.ownerDocument.defaultView !== window ? el.ownerDocument.defaultView.frameElement : null);
  }

  function viewportRect(el) {
    let rect = el.getBoundingClientRect();
    let view = el.ownerDocument.defaultView;
    while (view !== window) {
      const frame = view.frameElement;
      const bounds = frame.getBoundingClientRect();
      const sx = bounds.width / frame.offsetWidth;
      const sy = bounds.height / frame.offsetHeight;
      // shortcut: axis-aligned frame transforms; rotated frames need polygon geometry.
      rect = new DOMRect(bounds.left + (frame.clientLeft + rect.x) * sx,
        bounds.top + (frame.clientTop + rect.y) * sy, rect.width * sx, rect.height * sy);
      view = frame.ownerDocument.defaultView;
    }
    return rect;
  }

  function pathTo(view) {
    const path = [];
    while (view !== view.top) {
      const parent = view.parent;
      for (let i = 0; i < parent.length; i++) if (parent.frames[i] === view) { path.unshift(i); break; }
      view = parent;
    }
    return path;
  }

  function sensitive(el) {
    return el.matches('input[type="password"],input[type="hidden"]') ||
      /cc-|password|credit.?card|card.?number|cvv|cvc|iban|payment/i.test([
        el.getAttribute("autocomplete"), el.getAttribute("name"), el.id
      ].join(" "));
  }

  function name(el) {
    const root = el.getRootNode();
    const labelled = (el.getAttribute("aria-labelledby") || "").split(/\s+/)
      .map((id) => root.getElementById?.(id)?.textContent || "").join(" ").trim();
    return compact(labelled || el.getAttribute("aria-label") ||
      Array.from(el.labels || []).map((label) => label.textContent).join(" ") ||
      // Visible words beat a tooltip, as in the browser's own accessible name; fields never use their text.
      (el.matches("input,textarea,select") || sensitive(el) ? "" : el.innerText.trim()) ||
      el.getAttribute("alt") || el.title || el.getAttribute("placeholder") ||
      (sensitive(el) ? "" : el.innerText), 80);
  }

  function role(el) {
    if (el.getAttribute("role")) return el.getAttribute("role");
    if (el.matches("a[href]")) return "link";
    if (el.matches('button,summary,input[type="button"],input[type="submit"],input[type="reset"],[onclick]')) return "button";
    if (el.matches("select")) return "combobox";
    if (el.matches('input[type="checkbox"]')) return "checkbox";
    if (el.matches('input[type="radio"]')) return "radio";
    if (el.matches('input[type="range"]')) return "slider";
    if (el.matches('input[type="search"]')) return "searchbox";
    return "textbox";
  }

  function visible(el) {
    const rect = viewportRect(el);
    if (!rect.width || !rect.height) return false;
    for (let node = el; node; node = parentElement(node)) {
      const style = getComputedStyle(node);
      if (node.getAttribute("aria-hidden") === "true" || style.display === "none" || style.visibility === "hidden" || style.visibility === "collapse") return false;
    }
    return true;
  }

  function inViewport(rect) {
    return rect.top >= 0 && rect.left >= 0 && rect.bottom <= innerHeight && rect.right <= innerWidth;
  }

  function* collect(root, documents, boundaries) {
    for (const el of root.querySelectorAll("*")) {
      if (el.tagName === "SG-OVERLAY") continue;
      if (el.matches(SELECTOR)) yield el;
      if (el.shadowRoot) {
        watchRoot(el.shadowRoot);
        yield* collect(el.shadowRoot, documents, boundaries);
      }
      if (el.matches("iframe,frame") && visible(el)) {
        if (!watchedFrames.has(el)) {
          watchedFrames.add(el);
          el.addEventListener("load", () => { if (el.contentDocument) pageChanged("navigation"); });
        }
        const child = el.contentDocument;
        if (child) {
          if (!documents.has(child)) documents.set(child, documents.size);
          watchRoot(child);
          yield* collect(child, documents, boundaries);
        } else {
          const rect = viewportRect(el);
          const sx = rect.width / el.offsetWidth;
          const sy = rect.height / el.offsetHeight;
          boundaries.push({ path: pathTo(el.contentWindow),
            rect: [rect.x + el.clientLeft * sx, rect.y + el.clientTop * sy, el.clientWidth * sx, el.clientHeight * sy],
            viewport: [el.clientWidth, el.clientHeight] });
        }
      }
    }
  }

  async function snapshot(message) {
    const start = performance.now();
    observer.disconnect();
    watchRoot(document);
    if (message._frameId) {
      refPrefix = `f${message._frameId}`;
      framePath = message._path;
    }
    const documents = new Map([[document, 0]]);
    const boundaries = [];
    const elements = [];
    const attributes = [];
    const headingCache = new Map();
    const visibility = new WeakMap();
    function hidden(node) {
      if (!node) return false;
      if (visibility.has(node)) return visibility.get(node);
      const style = getComputedStyle(node);
      const result = node.getAttribute("aria-hidden") === "true" || style.display === "none" ||
        style.visibility === "hidden" || style.visibility === "collapse" ||
        hidden(parentElement(node));
      visibility.set(node, result);
      return result;
    }
    for (const el of collect(document, documents, boundaries)) {
      if (el.hasAttribute("role") && !ROLES.has(el.getAttribute("role")) && !el.matches('a[href],button,input,select,textarea,summary,[contenteditable="true"],[onclick],[tabindex]')) continue;
      const rect = viewportRect(el);
      if (!rect.width || !rect.height || hidden(el)) continue;
      const label = name(el);
      if (el.hasAttribute("tabindex") && !label && !el.matches("a[href],button,input,select,textarea,[role],[onclick]")) continue;
      let ref = el.getAttribute("data-sg-ref");
      if (refs.get(ref) !== el) {
        do { ref = `${refPrefix}e${++serial}`; } while (refs.has(ref));
      }
      if (el.getAttribute("data-sg-ref") !== ref) attributes.push([el, ref]);
      refs.set(ref, el);
      const landmark = el.closest('nav,main,form,dialog,[role="region"]');
      let context = landmark?.getAttribute("aria-label");
      if (!context) {
        const root = landmark || el.getRootNode();
        if (!headingCache.has(root)) headingCache.set(root, Array.from(root.querySelectorAll("h1,h2,h3")).reverse());
        context = headingCache.get(root).find((heading) => heading.compareDocumentPosition(el) & Node.DOCUMENT_POSITION_FOLLOWING)?.textContent;
      }
      elements.push({ ref, role: role(el), name: label, context: compact(context, 60),
        tag: el.tagName.toLowerCase(), type: el.getAttribute("type"),
        enabled: !el.matches(":disabled") && el.getAttribute("aria-disabled") !== "true",
        visible: true, in_viewport: inViewport(rect), rect: [rect.x, rect.y, rect.width, rect.height], frame: documents.get(el.ownerDocument),
        value: !sensitive(el) && el.matches("input,select,textarea") ? compact(el.value, 40) : null });
    }
    // Batch writes after layout reads; interleaving them makes large pages reflow per element.
    for (const [el, ref] of attributes) el.setAttribute("data-sg-ref", ref);
    for (const [ref, el] of refs) if (!el.isConnected) refs.delete(ref);
    if (window === window.top && boundaries.length) {
      const remote = await chrome.runtime.sendMessage({ type: "sg_frame_snapshots", id: message.id, max_elements: message.max_elements });
      const positions = new Map(boundaries.map((frame) => [frame.path.join("/"), frame]));
      let nextFrame = documents.size;
      for (const result of (remote || []).sort((a, b) => a._path.length - b._path.length)) {
        const bounds = positions.get(result._path.join("/"));
        if (!bounds) continue;
        const [x, y, width, height] = bounds.rect;
        const sx = width / bounds.viewport[0];
        const sy = height / bounds.viewport[1];
        for (const element of result.elements) {
          const [ex, ey, ew, eh] = element.rect;
          const rect = new DOMRect(x + ex * sx, y + ey * sy, ew * sx, eh * sy);
          elements.push({ ...element, frame: nextFrame + element.frame,
            rect: [rect.x, rect.y, rect.width, rect.height], in_viewport: element.in_viewport && inViewport(rect) });
        }
        nextFrame += result._docCount;
        for (const frame of result._boundaries) {
          const [fx, fy, fw, fh] = frame.rect;
          positions.set(frame.path.join("/"), { ...frame, rect: [x + fx * sx, y + fy * sy, fw * sx, fh * sy] });
        }
      }
    }
    const distance = (e) => Math.hypot(Math.max(0, -e.rect[1] - e.rect[3], e.rect[1] - innerHeight),
      Math.max(0, -e.rect[0] - e.rect[2], e.rect[0] - innerWidth));
    elements.sort((a, b) => Number(b.in_viewport) - Number(a.in_viewport) || distance(a) - distance(b) || a.rect[1] - b.rect[1] || a.rect[0] - b.rect[0]);
    const max = Number.isInteger(message.max_elements) ? Math.max(0, Math.min(400, message.max_elements)) : 400;
    return { type: "snapshot", id: message.id, url: location.href, title: document.title, elements: elements.slice(0, max), ms: performance.now() - start,
      viewport: [innerWidth, innerHeight],
      ...(message._frameId ? { _path: framePath, _boundaries: boundaries, _docCount: documents.size } : {}) };
  }

  let overlay;
  let card;
  let rings = [];
  let spotlight;
  let highlightedRefs = new Set();
  let lastGeometry;
  let showCard = true;
  const watchedFrames = new WeakSet();
  let animation;
  let generation = 0;
  let changeTimer;
  let pendingReason;
  let changedNodes = 0;
  let mutationTimer;

  function emit(message) {
    void chrome.runtime.sendMessage(message).catch(() => {});
  }

  function clear() {
    generation++;
    cancelAnimationFrame(animation);
    overlay?.remove();
    overlay = card = spotlight = null;
    rings = [];
    highlightedRefs.clear();
    lastGeometry = null;
  }

  function pageChanged(reason) {
    if (reason === "dom_mutation" && pendingReason && pendingReason !== "dom_mutation") return;
    pendingReason = reason;
    clearTimeout(changeTimer);
    changeTimer = setTimeout(() => {
      emit({ type: "page_changed", url: location.href, title: document.title, reason: pendingReason });
      pendingReason = null;
    }, 300);
  }

  function placeCard(rect) {
    const tokens = getComputedStyle(overlay);
    const gap = parseFloat(tokens.getPropertyValue("--sg-card-gap"));
    const edge = parseFloat(tokens.getPropertyValue("--sg-edge-gap"));
    const width = Math.min(parseFloat(tokens.getPropertyValue("--sg-card-width")), innerWidth - edge * 2);
    card.style.width = `${width}px`;
    card.style.maxHeight = `${innerHeight - edge * 2}px`;
    const height = card.offsetHeight + 60;   // the action buttons appear later (hover/idle): leave room so they aren't cut off
    const clamp = (value, max) => Math.max(edge, Math.min(value, max));
    const x = clamp(rect.left, innerWidth - width - edge);
    const y = clamp(rect.top, innerHeight - height - edge);
    const choices = [
      { x, y: rect.bottom + gap, w: width, h: innerHeight - rect.bottom - gap - edge },
      { x, y: rect.top - gap - height, w: width, h: rect.top - gap - edge },
      { x: rect.right + gap, y, w: innerWidth - rect.right - gap - edge, h: innerHeight - edge * 2 },
      { x: rect.left - gap - width, y, w: rect.left - gap - edge, h: innerHeight - edge * 2 },
    ];
    let choice = choices.find((c) => c.w >= width && c.h >= height);
    if (!choice) {
      // shortcut: oversized targets may leave only a scrollable card; use a separate panel if needed.
      choice = choices.filter((c) => c.w > 32 && c.h > 32).sort((a, b) => Math.min(width, b.w) * Math.min(height, b.h) - Math.min(width, a.w) * Math.min(height, a.h))[0];
    }
    if (!choice) { card.hidden = true; return; }
    card.hidden = false;
    const w = Math.min(width, choice.w);
    const h = Math.min(height, choice.h);
    card.style.width = `${w}px`;
    card.style.maxHeight = `${h}px`;
    if (choice === choices[1]) choice.y = rect.top - gap - h;
    if (choice === choices[3]) choice.x = rect.left - gap - w;
    card.style.left = `${clamp(choice.x, innerWidth - w - edge)}px`;
    card.style.top = `${clamp(choice.y, innerHeight - h - edge)}px`;
  }

  function track() {
    if (!overlay?.isConnected || rings.some(({ el }) => !el.isConnected)) {
      clear();
      pageChanged("dom_mutation");
      return;
    }
    const rects = rings.map(({ el }) => viewportRect(el));
    const states = rings.map(({ el }) => visible(el));
    const geometry = JSON.stringify([innerWidth, innerHeight, states, rects.map((r) => [r.x, r.y, r.width, r.height])]);
    if (geometry !== lastGeometry) {
      lastGeometry = geometry;
      const pad = parseFloat(getComputedStyle(overlay).getPropertyValue("--sg-ring-padding"));
      for (let i = 0; i < rings.length; i++) {
        const node = rings[i].node;
        const rect = rects[i];
        node.hidden = !states[i];
        Object.assign(node.style, { left: `${rect.left - pad}px`, top: `${rect.top - pad}px`, width: `${rect.width + pad * 2}px`, height: `${rect.height + pad * 2}px` });
      }
      if (spotlight) {
        spotlight.hidden = !states[0];
        spotlight.style.cssText = rings[0].node.style.cssText;
      }
      card.hidden = !states[0] || !showCard;
      if (states[0] && showCard) {
        const left = Math.min(...rects.map((r) => r.left));
        const top = Math.min(...rects.map((r) => r.top));
        const right = Math.max(...rects.map((r) => r.right));
        const bottom = Math.max(...rects.map((r) => r.bottom));
        placeCard(new DOMRect(left, top, right - left, bottom - top));
      }
    }
    animation = requestAnimationFrame(track);
  }

  function instructionText(node, text) {
    for (const part of text.split(/(\*\*[^*]+\*\*)/g)) {
      const span = document.createElement(part.startsWith("**") && part.endsWith("**") ? "strong" : "span");
      span.textContent = span.tagName === "STRONG" ? part.slice(2, -2) : part;
      node.append(span);
    }
  }

  // A small "working on it" / "all done" pill, separate from the highlight so clear() leaves it alone.
  let statusHost;
  let statusTimer;
  function showStatus(text, seconds) {
    clearTimeout(statusTimer);
    statusHost?.remove();
    statusHost = null;
    if (!text) return;
    statusHost = document.createElement("sg-status");
    for (const [property, value] of Object.entries({ all: "initial", position: "fixed", left: "24px", bottom: "24px", "z-index": "2147483647", "pointer-events": "none" })) statusHost.style.setProperty(property, value, "important");
    const shadow = statusHost.attachShadow({ mode: "open" });
    const css = document.createElement("link");
    css.rel = "stylesheet";
    css.href = chrome.runtime.getURL("src/overlay.css");
    const pill = document.createElement("div");
    pill.className = "status";
    pill.setAttribute("role", "status");
    pill.textContent = text;
    shadow.append(css, pill);
    document.documentElement.append(statusHost);
    if (seconds) statusTimer = setTimeout(() => showStatus(""), seconds * 1000);
  }

  async function highlight(message) {
    clear();
    showStatus("");
    const token = generation;
    showCard = !message._hideCard;
    const selected = Array.isArray(message.candidates) && message.candidates.length ? message.candidates : [message.ref];
    const targets = selected.map((ref) => refs.get(ref));
    const el = targets[0];
    if (targets.some((node) => !node?.isConnected)) return { type: "highlight_error", id: message.id, reason: "ref_not_found" };
    if (targets.some((node) => !visible(node))) return { type: "highlight_error", id: message.id, reason: "not_visible" };
    if (!inViewport(viewportRect(el))) {
      el.scrollIntoView({ block: "center", behavior: "smooth" });
      await new Promise((resolve) => setTimeout(resolve, 400));
    }
    if (token !== generation) return { type: "highlight_error", id: message.id, reason: "ref_not_found" };
    if (!el.isConnected || !visible(el)) return { type: "highlight_error", id: message.id, reason: "not_visible" };
    highlightedRefs = new Set(selected);
    overlay = document.createElement("sg-overlay");
    for (const [property, value] of Object.entries({ all: "initial", position: "fixed", inset: "0", "z-index": "2147483647", "pointer-events": "none" })) overlay.style.setProperty(property, value, "important");
    const shadow = overlay.attachShadow({ mode: "open" });
    const css = document.createElement("link");
    css.rel = "stylesheet";
    css.href = chrome.runtime.getURL("src/overlay.css");
    const loaded = new Promise((resolve) => {
      const timer = setTimeout(() => resolve(false), 1500);
      const finish = (ready) => { clearTimeout(timer); resolve(ready); };
      css.onload = () => finish(true);
      css.onerror = () => finish(false);
    });
    shadow.append(css);
    if (message.style === "spotlight") {
      spotlight = document.createElement("div");
      spotlight.className = "spotlight";
      spotlight.setAttribute("aria-hidden", "true");
      shadow.append(spotlight);
    }
    rings = targets.map((el, index) => {
      const node = document.createElement("div");
      node.className = message.candidates?.length ? "ring candidate" : "ring";
      node.setAttribute("aria-hidden", "true");
      if (message.candidates?.length) {
        const badge = document.createElement("span");
        badge.className = "badge";
        badge.textContent = String(message._numbers?.[index] || index + 1);
        node.append(badge);
      }
      shadow.append(node);
      return { el, node };
    });
    card = document.createElement("section");
    card.className = "card";
    card.setAttribute("role", "region");
    card.setAttribute("aria-label", "Gabay instruction");
    card.setAttribute("aria-live", "polite");
    if (message.step != null) {
      const step = document.createElement("div");
      step.className = "step";
      step.textContent = `Step ${message.step}`;
      card.append(step);
    }
    const instruction = document.createElement("p");
    instructionText(instruction, sensitive(el) ? "Type your password here. I won't look." : message.instruction);
    card.append(instruction);
    if (typeof message.hint === "string") {
      const hint = document.createElement("p");
      hint.className = "hint";
      instructionText(hint, message.hint);   // "**Enter**" renders bold, not with asterisks
      card.append(hint);
    }
    const buttons = document.createElement("div");
    buttons.className = "buttons";
    for (const [action, label] of [["not_this", "Not this one"], ["stop", "Stop"], ["read_aloud", ""]]) {
      const button = document.createElement("button");
      button.type = "button";
      button.textContent = label;
      if (action === "read_aloud") {
        button.className = "icon";
        button.setAttribute("aria-label", "Say it again");
        button.innerHTML = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path fill="currentColor" d="M4 9v6h4l5 4V5L8 9H4zm12.5 3a4.5 4.5 0 0 0-2.5-4v8a4.5 4.5 0 0 0 2.5-4zM14 3.2v2.1a7 7 0 0 1 0 13.4v2.1a9 9 0 0 0 0-17.6z"/></svg>';
      }
      button.addEventListener("click", () => {
        emit({ type: "card_button", button: action });
        if (action === "again") el.scrollIntoView({ block: "center", behavior: "smooth" });
        if (action === "stop") clear();
      });
      buttons.append(button);
    }
    card.append(buttons);
    shadow.append(card);
    // Quiet until needed: actions show on hover or after 8 s; after 18 s with no progress, dim the page around the ring.
    const thisCard = card;
    setTimeout(() => thisCard.classList.add("idle"), 8000);
    if (!message.candidates?.length && message.style !== "spotlight") {
      setTimeout(() => { if (card === thisCard && thisCard.isConnected) emit({ type: "card_button", button: "stuck" }); }, 18000);
    }
    document.documentElement.append(overlay);
    const styled = await loaded;
    if (token !== generation) return { type: "highlight_error", id: message.id, reason: "ref_not_found" };
    if (!styled) { clear(); return { type: "highlight_error", id: message.id, reason: "not_visible" }; }
    track();
    return { type: "highlight_ok", id: message.id };
  }

  function focusedSensitive(doc) {
    let active = doc.activeElement;
    while (active) {
      if (active.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
      else if (active.matches("iframe,frame")) {
        if (!active.contentDocument) return true;
        active = active.contentDocument.activeElement;
      } else break;
    }
    return active && sensitive(active);
  }

  const watchedRoots = new WeakSet();
  const routeChecks = new WeakMap();
  const handledEvents = new WeakSet();
  function watchRoot(root) {
    observer.observe(root, { childList: true, subtree: true });
    if (watchedRoots.has(root)) return;
    watchedRoots.add(root);
    for (const kind of ["click", "input", "change", "submit", "keydown"]) {
      root.addEventListener(kind, (event) => {
        if (handledEvents.has(event)) return;
        handledEvents.add(event);
        if (!event.isTrusted || (kind === "keydown" && event.key !== "Escape")) return;
        const path = event.composedPath();
        if (path.includes(overlay)) return;
        if (kind !== "submit" && (focusedSensitive(root.ownerDocument || root) || path.some((node) => node?.nodeType === 1 && sensitive(node)))) return;
        const el = path.find((node) => node?.nodeType === 1 && refs.get(node.getAttribute("data-sg-ref")) === node);
        const ref = el?.getAttribute("data-sg-ref");
        emit({ type: "user_action", kind: kind === "keydown" ? "keydown_escape" : kind,
          ...(ref ? { ref } : {}), on_target: Boolean(ref && highlightedRefs.has(ref)) });
        if (kind === "keydown") clear();
      }, true);
    }
    if (root.nodeType === 9) {
      const view = root.defaultView;
      let url = view.location.href;
      const check = () => {
        if (view.location.href === url) return;
        url = view.location.href;
        clear();
        pageChanged("spa_route");
      };
      routeChecks.set(root, check);
      for (const event of ["sg-route", "popstate", "hashchange"]) view.addEventListener(event, check);
    }
  }

  const observer = new MutationObserver((records) => {
    for (const record of records) {
      routeChecks.get(record.target.ownerDocument || record.target)?.();
      for (const node of [...record.addedNodes, ...record.removedNodes]) {
        if (node?.nodeType === 1 && node.tagName === "SG-OVERLAY") continue;
        changedNodes++;
        if (node?.nodeType === 1) changedNodes += node.querySelectorAll("*").length;
      }
    }
    if (changedNodes > 20) pageChanged("dom_mutation");
    clearTimeout(mutationTimer);
    mutationTimer = setTimeout(() => { changedNodes = 0; }, 300);
  });
  watchRoot(document);
  // Some sites use History.prototype directly or replace the hook after loading.
  setInterval(() => routeChecks.get(document)?.(), 300);
  pageChanged("navigation");

  async function scrollFrame(path) {
    let doc = document;
    for (const index of path.slice(framePath.length)) {
      const view = doc.defaultView.frames[index];
      // Find frame hosts through open shadow roots as well as the light DOM.
      function find(root) {
        for (const el of root.querySelectorAll("*")) {
          if (el.matches("iframe,frame") && el.contentWindow === view) return el;
          if (el.shadowRoot && el.tagName !== "SG-OVERLAY") { const found = find(el.shadowRoot); if (found) return found; }
        }
      }
      const host = find(doc);
      if (!host) break;
      if (!inViewport(viewportRect(host))) {
        host.scrollIntoView({ block: "center", behavior: "smooth" });
        await new Promise((resolve) => setTimeout(resolve, 400));
      }
      if (!host.contentDocument) break;
      doc = host.contentDocument;
    }
  }

  chrome.runtime.onMessage.addListener((message, sender, respond) => {
    if (sender.id !== chrome.runtime.id) return;
    if (message.type === "snapshot_request") {
      void snapshot(message).then(respond).catch(() => respond({ type: "snapshot", id: message.id, url: location.href, title: document.title, elements: [], ms: 0 }));
      return true;
    }
    if (message.type === "sg_scroll_frame") {
      void scrollFrame(message.path).then(() => respond({ ok: true }));
      return true;
    }
    if (message.type === "clear") clear();
    if (message.type === "status") showStatus(message.text, message.seconds);
    if (message.type === "highlight") {
      void highlight(message).then(respond).catch(() => respond({ type: "highlight_error", id: message.id, reason: "not_visible" }));
      return true;
    }
  });
})();
