#!/usr/bin/env python3
"""
Codex Island Hook
- Sends Codex CLI session state to ClaudeIsland.app via Unix socket
- For PreToolUse: notifies the app but does NOT block - user goes to terminal for approval
  (Codex CLI only supports 'deny' via hook, 'allow' requires user interaction in terminal)
"""
import json
import os
import socket
import subprocess
import sys

SOCKET_PATH = "/tmp/claude-island.sock"
TIMEOUT_SECONDS = 5  # Short timeout for non-blocking notification


def get_tty():
    """Get the TTY for the Codex parent process when available."""
    ppid = os.getppid()

    try:
        result = subprocess.run(
            ["ps", "-p", str(ppid), "-o", "tty="],
            capture_output=True,
            text=True,
            timeout=2
        )
        tty = result.stdout.strip()
        if tty and tty != "??" and tty != "-":
            if not tty.startswith("/dev/"):
                tty = "/dev/" + tty
            return tty
    except Exception:
        pass

    try:
        return os.ttyname(sys.stdin.fileno())
    except (OSError, AttributeError):
        pass
    try:
        return os.ttyname(sys.stdout.fileno())
    except (OSError, AttributeError):
        pass
    return None


def send_event(state):
    """Send event to app (fire and forget - no response expected)."""
    try:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(TIMEOUT_SECONDS)
        sock.connect(SOCKET_PATH)
        sock.sendall(json.dumps(state).encode())
        sock.close()
    except (socket.error, OSError):
        pass


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(1)

    session_id = data.get("session_id", "unknown")
    event = data.get("hook_event_name", "")
    cwd = data.get("cwd") or os.getcwd()
    tool_input = data.get("tool_input", {})

    state = {
        "provider": "codex",
        "session_id": session_id,
        "cwd": cwd,
        "event": event,
        "pid": os.getppid(),
        "tty": get_tty(),
        "transcript_path": data.get("transcript_path"),
        "model": data.get("model"),
        "permission_mode": data.get("permission_mode"),
    }

    if event == "SessionStart":
        state["status"] = "waiting_for_input"
        state["session_start_source"] = data.get("source")

    elif event == "UserPromptSubmit":
        state["status"] = "processing"
        state["prompt"] = data.get("prompt")

    elif event == "PreToolUse":
        state["status"] = "waiting_for_approval"
        state["tool"] = data.get("tool_name")
        state["tool_input"] = tool_input
        tool_use_id = data.get("tool_use_id")
        if tool_use_id:
            state["tool_use_id"] = tool_use_id

        # Notify the app that approval is needed
        # Note: We do NOT block/wait for response because Codex CLI doesn't support
        # 'allow' decision via hook - user must go to terminal to approve
        send_event(state)
        
        # Exit with code 0 to let Codex show its own approval UI in terminal
        sys.exit(0)

    elif event == "PostToolUse":
        state["status"] = "processing"
        state["tool"] = data.get("tool_name")
        state["tool_input"] = tool_input
        tool_use_id = data.get("tool_use_id")
        if tool_use_id:
            state["tool_use_id"] = tool_use_id

    elif event == "Stop":
        state["status"] = "waiting_for_input"
        state["last_assistant_message"] = data.get("last_assistant_message")

    else:
        state["status"] = "unknown"

    send_event(state)


if __name__ == "__main__":
    main()
