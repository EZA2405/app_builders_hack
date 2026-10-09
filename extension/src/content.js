(() => {
  const ROLES = new Set(["button", "link", "tab", "menuitem", "menuitemcheckbox", "menuitemradio", "checkbox", "radio", "switch", "combobox", "textbox", "searchbox", "option", "slider", "treeitem"]);
  const SELECTOR = 'a[href],button,input:not([type="hidden"]),select,textarea,summary,[contenteditable="true"],[role],[onclick],[tabindex]:not([tabindex="-1"])';
  const refs = new Map();
  let serial = 0;
  const compact = (text, max) => String(text || "").replace(/\s+/g, " ").trim().slice(0, max);

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
    const rect = el.getBoundingClientRect();
    if (!rect.width || !rect.height) return false;
    for (let node = el; node; node = node.parentElement || node.getRootNode().host) {
      const style = getComputedStyle(node);
      if (node.getAttribute("aria-hidden") === "true" || style.display === "none" || style.visibility === "hidden" || style.visibility === "collapse") return false;
    }
    return true;
  }

  function inViewport(rect) {
    return rect.top >= 0 && rect.left >= 0 && rect.bottom <= innerHeight && rect.right <= innerWidth;
  }

  function snapshot(message) {
    const start = performance.now();
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
        hidden(node.parentElement || node.getRootNode().host);
      visibility.set(node, result);
      return result;
    }
    for (const el of document.querySelectorAll(SELECTOR)) {
      if (el.hasAttribute("role") && !ROLES.has(el.getAttribute("role")) && !el.matches('a[href],button,input,select,textarea,summary,[contenteditable="true"],[onclick],[tabindex]')) continue;
      const rect = el.getBoundingClientRect();
      if (!rect.width || !rect.height || hidden(el)) continue;
      const label = name(el);
      if (el.hasAttribute("tabindex") && !label && !el.matches("a[href],button,input,select,textarea,[role],[onclick]")) continue;
      let ref = el.getAttribute("data-sg-ref");
      if (!ref || (refs.has(ref) && refs.get(ref) !== el)) ref = `e${++serial}`;
      if (el.getAttribute("data-sg-ref") !== ref) attributes.push([el, ref]);
      refs.set(ref, el);
      const landmark = el.closest('nav,main,form,dialog,[role="region"]');
      let context = landmark?.getAttribute("aria-label");
      if (!context) {
        const root = landmark || document;
        if (!headingCache.has(root)) headingCache.set(root, Array.from(root.querySelectorAll("h1,h2,h3")).reverse());
        context = headingCache.get(root).find((heading) => heading.compareDocumentPosition(el) & Node.DOCUMENT_POSITION_FOLLOWING)?.textContent;
      }
      elements.push({ ref, role: role(el), name: label, context: compact(context, 60),
        tag: el.tagName.toLowerCase(), type: el.getAttribute("type"),
        enabled: !el.matches(":disabled") && el.getAttribute("aria-disabled") !== "true",
        visible: true, in_viewport: inViewport(rect), rect: [rect.x, rect.y, rect.width, rect.height], frame: 0,
        value: !sensitive(el) && el.matches("input,select,textarea") ? compact(el.value, 40) : null });
    }
    // Batch writes after layout reads; interleaving them makes large pages reflow per element.
    for (const [el, ref] of attributes) el.setAttribute("data-sg-ref", ref);
    for (const [ref, el] of refs) if (!el.isConnected) refs.delete(ref);
    const distance = (e) => Math.max(0, -e.rect[1], e.rect[1] + e.rect[3] - innerHeight, -e.rect[0], e.rect[0] + e.rect[2] - innerWidth);
    elements.sort((a, b) => Number(b.in_viewport) - Number(a.in_viewport) || distance(a) - distance(b) || a.rect[1] - b.rect[1] || a.rect[0] - b.rect[0]);
    const max = Number.isInteger(message.max_elements) ? Math.max(0, Math.min(400, message.max_elements)) : 400;
    return { type: "snapshot", id: message.id, url: location.href, title: document.title, elements: elements.slice(0, max), ms: performance.now() - start };
  }

  let overlay;
  let card;
  let ring;
  let target;
  let highlightedRef;
  let animation;
  let generation = 0;
  let changeTimer;
  let pendingReason;
  let lastURL = location.href;
  let changedNodes = 0;
  let mutationTimer;

  function emit(message) {
    void chrome.runtime.sendMessage(message).catch(() => {});
  }

  function clear() {
    generation++;
    cancelAnimationFrame(animation);
    overlay?.remove();
    overlay = card = ring = target = highlightedRef = null;
  }

  function pageChanged(reason) {
    if (!pendingReason || reason !== "dom_mutation") pendingReason = reason;
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
    const height = card.offsetHeight;
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
    if (!target?.isConnected || !overlay?.isConnected) {
      clear();
      pageChanged("dom_mutation");
      return;
    }
    if (!visible(target)) {
      ring.hidden = card.hidden = true;
    } else {
      ring.hidden = card.hidden = false;
      const rect = target.getBoundingClientRect();
      const pad = parseFloat(getComputedStyle(overlay).getPropertyValue("--sg-ring-padding"));
      Object.assign(ring.style, { left: `${rect.left - pad}px`, top: `${rect.top - pad}px`, width: `${rect.width + pad * 2}px`, height: `${rect.height + pad * 2}px` });
      placeCard(rect);
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

  async function highlight(message) {
    clear();
    const token = generation;
    const el = refs.get(message.ref);
    if (!el?.isConnected) return { type: "highlight_error", id: message.id, reason: "ref_not_found" };
    if (!visible(el)) return { type: "highlight_error", id: message.id, reason: "not_visible" };
    if (!inViewport(el.getBoundingClientRect())) {
      el.scrollIntoView({ block: "center", behavior: "smooth" });
      await new Promise((resolve) => setTimeout(resolve, 400));
    }
    if (token !== generation) return { type: "highlight_error", id: message.id, reason: "ref_not_found" };
    if (!el.isConnected || !visible(el)) return { type: "highlight_error", id: message.id, reason: "not_visible" };
    target = el;
    highlightedRef = message.ref;
    overlay = document.createElement("sg-overlay");
    for (const [property, value] of Object.entries({ all: "initial", position: "fixed", inset: "0", "z-index": "2147483647", "pointer-events": "none" })) overlay.style.setProperty(property, value, "important");
    const shadow = overlay.attachShadow({ mode: "open" });
    const css = document.createElement("link");
    css.rel = "stylesheet";
    css.href = chrome.runtime.getURL("src/overlay.css");
    const loaded = new Promise((resolve) => { css.onload = css.onerror = resolve; });
    shadow.append(css);
    ring = document.createElement("div");
    ring.className = "ring";
    ring.setAttribute("aria-hidden", "true");
    card = document.createElement("section");
    card.className = "card";
    card.setAttribute("role", "region");
    card.setAttribute("aria-label", "ScreenGuide instruction");
    card.setAttribute("aria-live", "polite");
    if (message.step != null) {
      const step = document.createElement("div");
      step.className = "step";
      step.textContent = `Step ${message.step}`;
      card.append(step);
    }
    const instruction = document.createElement("p");
    instructionText(instruction, sensitive(el) ? "Type your password yourself — I'll look away" : message.instruction);
    card.append(instruction);
    if (typeof message.hint === "string") {
      const hint = document.createElement("p");
      hint.className = "hint";
      hint.textContent = message.hint;
      card.append(hint);
    }
    const buttons = document.createElement("div");
    buttons.className = "buttons";
    for (const [action, label] of [["again", "Show me again"], ["stuck", "I'm stuck"], ["stop", "Stop"], ["read_aloud", "🔊"]]) {
      const button = document.createElement("button");
      button.type = "button";
      button.textContent = label;
      if (action === "read_aloud") button.setAttribute("aria-label", "Read aloud");
      button.addEventListener("click", () => {
        emit({ type: "card_button", button: action });
        if (action === "again") el.scrollIntoView({ block: "center", behavior: "smooth" });
        if (action === "stop") clear();
      });
      buttons.append(button);
    }
    card.append(buttons);
    shadow.append(ring, card);
    document.documentElement.append(overlay);
    await loaded;
    if (token !== generation) return { type: "highlight_error", id: message.id, reason: "ref_not_found" };
    track();
    return { type: "highlight_ok", id: message.id };
  }

  function focusedSensitive() {
    let active = document.activeElement;
    while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
    return active && sensitive(active);
  }

  for (const kind of ["click", "input", "change", "submit", "keydown"]) {
    document.addEventListener(kind, (event) => {
      if (!event.isTrusted || (kind === "keydown" && event.key !== "Escape")) return;
      const path = event.composedPath();
      if (path.includes(overlay)) return;
      if (kind !== "submit" && (focusedSensitive() || path.some((node) => node instanceof Element && sensitive(node)))) return;
      const el = path.find((node) => node instanceof Element && refs.get(node.getAttribute("data-sg-ref")) === node);
      const ref = el?.getAttribute("data-sg-ref");
      emit({ type: "user_action", kind: kind === "keydown" ? "keydown_escape" : kind,
        ...(ref ? { ref } : {}), on_target: Boolean(ref && ref === highlightedRef) });
      if (kind === "keydown") clear();
    }, true);
  }

  function routeChanged() {
    if (location.href === lastURL) return;
    lastURL = location.href;
    clear();
    pageChanged("spa_route");
  }
  for (const event of ["sg-route", "popstate", "hashchange"]) window.addEventListener(event, routeChanged);

  const observer = new MutationObserver((records) => {
    for (const record of records) {
      for (const node of [...record.addedNodes, ...record.removedNodes]) {
        if (node instanceof Element && node.tagName === "SG-OVERLAY") continue;
        changedNodes++;
        if (node instanceof Element) changedNodes += node.querySelectorAll("*").length;
      }
    }
    if (changedNodes > 20) pageChanged("dom_mutation");
    clearTimeout(mutationTimer);
    mutationTimer = setTimeout(() => { changedNodes = 0; }, 300);
  });
  observer.observe(document.body || document.documentElement, { childList: true, subtree: true });
  pageChanged("navigation");

  chrome.runtime.onMessage.addListener((message, sender, respond) => {
    if (sender.id !== chrome.runtime.id) return;
    if (message.type === "snapshot_request") respond(snapshot(message));
    if (message.type === "clear") clear();
    if (message.type === "highlight") {
      void highlight(message).then(respond).catch(() => respond({ type: "highlight_error", id: message.id, reason: "not_visible" }));
      return true;
    }
  });
})();
