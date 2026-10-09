// History must be observed in the page's world; content scripts have separate JS globals.
for (const method of ["pushState", "replaceState"]) {
  const original = history[method];
  history[method] = function (...args) {
    const result = original.apply(this, args);
    window.dispatchEvent(new Event("sg-route"));
    return result;
  };
}
