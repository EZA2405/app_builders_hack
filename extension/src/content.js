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

  chrome.runtime.onMessage.addListener((message, sender, respond) => {
    if (sender.id !== chrome.runtime.id) return;
    if (message.type === "snapshot_request") respond(snapshot(message));
  });
})();
