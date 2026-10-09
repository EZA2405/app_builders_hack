// Interactive-element snapshot, same rules as extension/SPEC.md (keep the two in sync).
// Returns {url, title, elements:[{ref, role, name, context, in_viewport, enabled}]}.
// Used by ml/web/crawl.py for training data; the extension's content.js should match it.
(() => {
  const MAX = 400;
  const ROLES = new Set(["button","link","tab","menuitem","menuitemcheckbox","menuitemradio","checkbox","radio",
    "switch","combobox","textbox","searchbox","option","slider","treeitem"]);
  const SEL = 'a[href],button,input:not([type=hidden]),select,textarea,summary,[contenteditable="true"],[role],[onclick],[tabindex]:not([tabindex="-1"])';
  const clean = (s, n) => (s || "").replace(/\s+/g, " ").trim().slice(0, n);

  function implicitRole(el) {
    const t = el.tagName.toLowerCase(), type = (el.getAttribute("type") || "text").toLowerCase();
    if (t === "a") return "link";
    if (t === "button" || t === "summary") return "button";
    if (t === "select") return "combobox";
    if (t === "textarea") return "textbox";
    if (t === "input") {
      if (["button","submit","reset","image"].includes(type)) return "button";
      if (type === "checkbox") return "checkbox";
      if (type === "radio") return "radio";
      if (type === "range") return "slider";
      if (type === "search") return "searchbox";
      return "textbox";
    }
    if (el.isContentEditable) return "textbox";
    return "button"; // onclick / tabindex elements act like buttons
  }

  function name(el) {
    const by = el.getAttribute("aria-labelledby");
    if (by) {
      const t = by.split(/\s+/).map(id => document.getElementById(id)?.innerText || "").join(" ");
      if (clean(t)) return clean(t, 80);
    }
    const aria = el.getAttribute("aria-label");
    if (clean(aria)) return clean(aria, 80);
    if (el.id) {
      const lab = document.querySelector(`label[for="${CSS.escape(el.id)}"]`);
      if (lab && clean(lab.innerText)) return clean(lab.innerText, 80);
    }
    const wrap = el.closest("label");
    if (wrap && clean(wrap.innerText)) return clean(wrap.innerText, 80);
    for (const a of ["alt", "title", "placeholder"]) if (clean(el.getAttribute(a))) return clean(el.getAttribute(a), 80);
    const img = el.querySelector?.("img[alt]");
    const txt = clean(el.innerText || el.value);
    if (txt) return clean(txt, 80);
    if (img) return clean(img.getAttribute("alt"), 80);
    return "";
  }

  function context(el) {
    const land = el.closest('nav,main,form,dialog,header,footer,aside,[role=region],[role=dialog],[role=navigation],[role=search]');
    if (land) {
      const l = land.getAttribute("aria-label") || (land.getAttribute("aria-labelledby") && document.getElementById(land.getAttribute("aria-labelledby"))?.innerText);
      if (clean(l)) return clean(l, 60);
      const tag = land.getAttribute("role") || land.tagName.toLowerCase();
      const h = land.querySelector("h1,h2,h3");
      return clean(h ? `${tag}: ${h.innerText}` : tag, 60);
    }
    return "";
  }

  function visible(el) {
    const r = el.getBoundingClientRect();
    if (r.width < 2 || r.height < 2) return false;
    const cs = getComputedStyle(el);
    if (cs.display === "none" || cs.visibility === "hidden" || +cs.opacity === 0) return false;
    if (el.closest('[aria-hidden="true"]')) return false;
    return true;
  }

  const all = [];
  const walk = root => {
    root.querySelectorAll(SEL).forEach(el => all.push(el));
    root.querySelectorAll("*").forEach(n => n.shadowRoot && walk(n.shadowRoot));
  };
  walk(document);

  const seen = new Set(), out = [];
  const vh = innerHeight, vw = innerWidth;
  for (const el of all) {
    if (seen.has(el)) continue; seen.add(el);
    const explicit = (el.getAttribute("role") || "").toLowerCase();
    if (explicit && !ROLES.has(explicit) && !el.matches('a[href],button,input,select,textarea')) continue;
    if (!visible(el)) continue;
    const role = ROLES.has(explicit) ? explicit : implicitRole(el);
    const nm = name(el);
    if (!nm && el.matches('[tabindex],[onclick]')) continue;
    const r = el.getBoundingClientRect();
    out.push({
      role, name: nm, context: context(el),
      in_viewport: r.bottom > 0 && r.top < vh && r.right > 0 && r.left < vw,
      enabled: !(el.disabled || el.getAttribute("aria-disabled") === "true" || el.closest("fieldset[disabled]")),
      _top: r.top, _left: r.left,
      // href only for the crawler to follow links; never part of the model's input.
      _href: el.tagName === "A" ? el.href : null,
    });
  }
  // In-viewport first (reading order), then by distance from the viewport.
  out.sort((a, b) => (b.in_viewport - a.in_viewport) || (a.in_viewport ? (a._top - b._top || a._left - b._left) : Math.abs(a._top) - Math.abs(b._top)));
  const elements = out.slice(0, MAX).map((e, i) => ({ ref: "e" + (i + 1), role: e.role, name: e.name, context: e.context, in_viewport: e.in_viewport, enabled: e.enabled, href: e._href }));
  return { url: location.href, title: document.title, elements };
})()
