#!/usr/bin/env python3
"""
Gemini Island Hook
- Sends Gemini CLI session state to ClaudeIsland.app via Unix socket
- For BeforeTool: notifies the app but does NOT block - user goes to terminal for approval
  (Gemini CLI only supports 'deny' via hook, 'allow' requires user interaction in terminal)
"""
import json
import os
import socket
import subprocess
import sys

SOCKET_PATH = "/tmp/claude-island.sock"
TIMEOUT_SECONDS = 5  # Short timeout for non-blocking notification

# Event name mapping: Gemini native → Agent Island internal
EVENT_MAP = {
    "SessionStart": "SessionStart",
    "BeforeAgent": "UserPromptSubmit",
    "BeforeTool": "PreToolUse",
    "AfterTool": "PostToolUse",
    "AfterAgent": "Stop",
    "SessionEnd": "SessionEnd",
}


def get_tty():
    """Get the TTY for the Gemini parent process when available."""
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
    gemini_event = data.get("hook_event_name", "")
    # Map Gemini event names to Agent Island internal event names
    event = EVENT_MAP.get(gemini_event, gemini_event)
    cwd = data.get("cwd") or os.getcwd()
    tool_input = data.get("tool_input", {})

    state = {
        "provider": "gemini",
        "session_id": session_id,
        "cwd": cwd,
        "event": event,
        "pid": os.getppid(),
        "tty": get_tty(),
        "transcript_path": data.get("transcript_path"),
        "model": data.get("model"),
        "permission_mode": data.get("permission_mode"),
    }

    # Output empty JSON to satisfy Gemini CLI protocol as early as possible
    print("{}")

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
        tool_call_id = data.get("tool_call_id")
        if tool_call_id:
            state["tool_use_id"] = tool_call_id

        # Notify the app that approval is needed
        # Note: We do NOT block/wait for response because Gemini CLI doesn't support
        # 'allow' decision via hook - user must go to terminal to approve
        send_event(state)
        
        # Exit with code 0 to let Gemini show its own approval UI in terminal
        sys.exit(0)

    elif event == "PostToolUse":
        state["status"] = "processing"
        state["tool"] = data.get("tool_name")
        state["tool_input"] = tool_input
        tool_call_id = data.get("tool_call_id")
        if tool_call_id:
            state["tool_use_id"] = tool_call_id

    elif event == "Stop":
        state["status"] = "waiting_for_input"

    elif event == "SessionEnd":
        state["status"] = "ended"

    else:
        state["status"] = "unknown"

    send_event(state)


if __name__ == "__main__":
    main()
