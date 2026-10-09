const ENDPOINT = "ws://127.0.0.1:47823/ext";
const BACKOFF = [1000, 2000, 5000, 10000];
let socket;
let retries = 0;
let retryTimer;

function send(message) {
  if (socket?.readyState === WebSocket.OPEN) socket.send(JSON.stringify(message));
}

async function activeTab() {
  // Keep the browser selection when the mock's terminal is in the foreground.
  return (await chrome.tabs.query({ active: true, lastFocusedWindow: true }))[0];
}

async function route(message) {
  if (message?.type === "ping") return;
  if (!["snapshot_request", "highlight", "clear"].includes(message?.type) || typeof message.id !== "string") return;
  if (message.type === "highlight" && (typeof message.ref !== "string" || typeof message.instruction !== "string")) return;
  const tab = await activeTab();
  if (!tab?.id) return;
  try {
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

chrome.runtime.onMessage.addListener((message, sender) => {
  if (!sender.tab || !["user_action", "page_changed", "card_button"].includes(message?.type)) return;
  void activeTab().then((tab) => { if (tab?.id === sender.tab.id) send(message); }).catch(console.warn);
});

// Extension API activity also keeps reconnection alive when the socket is down.
setInterval(() => {
  void chrome.storage.local.get("keepalive");
  send({ type: "ping" });
}, 20000);
connect();
