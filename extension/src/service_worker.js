const ENDPOINT = "ws://127.0.0.1:47823/ext";
const BACKOFF = [1000, 2000, 5000, 10000];
let socket;
let retries = 0;
let retryTimer;
const frameTrees = new Map();

function send(message) {
  if (socket?.readyState === WebSocket.OPEN) socket.send(JSON.stringify(message));
}

async function activeTab() {
  // Keep the browser selection when the mock's terminal is in the foreground.
  return (await chrome.tabs.query({ active: true, lastFocusedWindow: true }))[0];
}

async function frameSnapshots(tabId, message) {
  const frames = await chrome.scripting.executeScript({
    target: { tabId, allFrames: true },
    func: () => {
      const path = [];
      let view = window;
      while (view !== view.top) {
        const parent = view.parent;
        for (let i = 0; i < parent.length; i++) if (parent.frames[i] === view) { path.unshift(i); break; }
        view = parent;
      }
      let boundary = false;
      if (window !== window.top) { try { void window.parent.document; } catch { boundary = true; } }
      return { path, boundary };
    },
  });
  const boundaries = frames.filter((frame) => frame.result.boundary);
  frameTrees.set(tabId, boundaries);
  return Promise.all(boundaries.map(async ({ frameId, result }) => {
    try {
      return await chrome.tabs.sendMessage(tabId, { type: "snapshot_request", id: message.id,
        max_elements: message.max_elements, _frameId: frameId, _path: result.path }, { frameId });
    } catch { return { elements: [], _path: result.path, _boundaries: [], _docCount: 1 }; }
  }));
}

async function route(message) {
  if (message?.type === "ping") return;
  if (!["snapshot_request", "highlight", "clear"].includes(message?.type) || typeof message.id !== "string") return;
  if (message.type === "highlight" && (typeof message.ref !== "string" || typeof message.instruction !== "string")) return;
  if (message.type === "highlight" && message.candidates != null &&
      (!Array.isArray(message.candidates) || message.candidates.length > 400 || message.candidates.some((ref) => typeof ref !== "string"))) return;
  // Private frame metadata is internal; never accept it from the WebSocket.
  message = { type: message.type, id: message.id,
    ...(message.type === "snapshot_request" ? { max_elements: message.max_elements } : {}),
    ...(message.type === "highlight" ? { ref: message.ref, instruction: message.instruction,
      step: message.step, hint: message.hint, style: message.style, candidates: message.candidates } : {}) };
  const tab = await activeTab();
  if (!tab?.id) return;
  try {
    if (message.type === "clear") {
      await chrome.tabs.sendMessage(tab.id, message);
      return;
    }
    if (message.type === "highlight") {
      await chrome.tabs.sendMessage(tab.id, { type: "clear", id: message.id });
      const refs = message.candidates?.length ? message.candidates : [message.ref];
      const groups = new Map();
      for (let i = 0; i < refs.length; i++) {
        const frameId = Number(/^f(\d+)e/.exec(refs[i])?.[1] || 0);
        if (!groups.has(frameId)) groups.set(frameId, []);
        groups.get(frameId).push({ ref: refs[i], number: i + 1 });
      }
      const primaryFrame = Number(/^f(\d+)e/.exec(refs[0])?.[1] || 0);
      const frame = frameTrees.get(tab.id)?.find((entry) => entry.frameId === primaryFrame);
      if (frame) {
        await chrome.tabs.sendMessage(tab.id, { type: "sg_scroll_frame", path: frame.result.path }, { frameId: 0 });
        for (const parent of frameTrees.get(tab.id).filter((entry) => entry.result.path.length < frame.result.path.length &&
          entry.result.path.every((index, i) => frame.result.path[i] === index)).sort((a, b) => a.result.path.length - b.result.path.length)) {
          await chrome.tabs.sendMessage(tab.id, { type: "sg_scroll_frame", path: frame.result.path }, { frameId: parent.frameId });
        }
      }
      const responses = await Promise.all(Array.from(groups, async ([frameId, group]) => {
        return chrome.tabs.sendMessage(tab.id, { ...message, ref: group[0].ref,
          ...(message.candidates?.length ? { candidates: group.map((item) => item.ref), _numbers: group.map((item) => item.number) } : {}),
          _hideCard: frameId !== primaryFrame }, { frameId });
      }));
      send(responses.find((response) => response.type === "highlight_error") || { type: "highlight_ok", id: message.id });
      return;
    }
    const response = await chrome.tabs.sendMessage(tab.id, message, { frameId: 0 });
    if (response) send(response);
  } catch {
    if (message.type === "highlight") send({ type: "highlight_error", id: message.id, reason: "ref_not_found" });
    if (message.type === "snapshot_request") send({ type: "snapshot", id: message.id, url: tab.url || "", title: tab.title || "", elements: [], ms: 0 });
  }
}

function connect() {
  if (socket && socket.readyState < WebSocket.CLOSING) return;
  clearTimeout(retryTimer);
  socket = new WebSocket(ENDPOINT);
  socket.onopen = () => {
    retries = 0;
    send({ type: "hello", browser: "Chrome", version: chrome.runtime.getManifest().version });
  };
  socket.onmessage = (event) => {
    try { void route(JSON.parse(event.data)).catch(console.warn); } catch { /* Ignore malformed JSON. */ }
  };
  socket.onerror = () => socket.close();
  socket.onclose = () => {
    retryTimer = setTimeout(connect, BACKOFF[Math.min(retries++, BACKOFF.length - 1)]);
  };
}

chrome.runtime.onMessage.addListener((message, sender, respond) => {
  // Only our own toolbar popup may start or stop a goal; content scripts report a web page URL here.
  if (sender.id === chrome.runtime.id && sender.url === chrome.runtime.getURL("src/popup.html")) {
    if (message?.type === "sg_status") respond({ connected: socket?.readyState === WebSocket.OPEN });
    if (message?.type === "sg_goal" && typeof message.text === "string") send({ type: "goal", text: message.text.slice(0, 300) });
    if (message?.type === "sg_stop") {
      send({ type: "card_button", button: "stop" });
      void activeTab().then((tab) => tab?.id && chrome.tabs.sendMessage(tab.id, { type: "clear", id: "popup" })).catch(() => {});
    }
    return;
  }
  if (sender.tab && sender.frameId === 0 && message?.type === "sg_frame_snapshots") {
    void frameSnapshots(sender.tab.id, message).then(respond).catch(() => respond([]));
    return true;
  }
  if (!sender.tab || !["user_action", "page_changed", "card_button"].includes(message?.type)) return;
  void activeTab().then((tab) => { if (tab?.id === sender.tab.id) send(message); }).catch(console.warn);
});

chrome.tabs.onRemoved.addListener((tabId) => frameTrees.delete(tabId));

// Extension API activity also keeps reconnection alive when the socket is down.
setInterval(() => {
  void chrome.storage.local.get("keepalive");
  send({ type: "ping" });
}, 20000);
connect();
