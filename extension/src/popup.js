const goal = document.getElementById("goal");
const go = document.getElementById("go");
const status = document.getElementById("status");

function show(connected) {
  go.disabled = !connected;
  status.style.setProperty("--dot", connected ? "#2FA35A" : "#F08A24");
  if (connected) status.textContent = "Ready. I'll point; you click.";
  else {
    status.textContent = "The guide isn't running on this Mac. In Terminal, start: ";
    const code = document.createElement("code");
    code.textContent = "extension/.venv/bin/python extension/mock/mock_app.py --orderer claude";
    status.append(code);
  }
}

chrome.runtime.sendMessage({ type: "sg_status" }).then((reply) => show(reply?.connected)).catch(() => show(false));

document.getElementById("ask").addEventListener("submit", async (event) => {
  event.preventDefault();
  const text = goal.value.trim();
  if (!text) return goal.focus();
  await chrome.runtime.sendMessage({ type: "sg_goal", text });
  status.textContent = "Got it. Working out the first step…";
  setTimeout(() => window.close(), 900);
});

goal.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && !event.shiftKey) { event.preventDefault(); document.getElementById("ask").requestSubmit(); }
});

document.getElementById("stop").addEventListener("click", async () => {
  await chrome.runtime.sendMessage({ type: "sg_stop" });
  window.close();
});
