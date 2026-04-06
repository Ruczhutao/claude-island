#!/usr/bin/env python3
"""
Cursor Island Hook
- Sends Cursor IDE session state to ClaudeIsland.app via Unix socket
- Cursor 3.0+ hooks integration (beforeSubmitPrompt, afterAgentResponse, etc.)

Hook events from Cursor:
- beforeSubmitPrompt: User sends a message
- afterAgentResponse: Agent responds
- beforeShellExecution: About to run a shell command
- afterShellExecution: Shell command completed
- stop: Session ended
"""
import json
import os
import socket
import subprocess
import sys
import hashlib

SOCKET_PATH = "/tmp/claude-island.sock"
TIMEOUT_SECONDS = 5  # Short timeout for non-blocking notification


def get_tty():
    """Get the TTY for the Cursor parent process when available."""
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


def extract_project_name(workspace_roots):
    """Extract project name from workspace_roots array.
    
    Args:
        workspace_roots: List of workspace root paths
        
    Returns:
        Last path component of the first workspace root
        Example: /Users/.../工作论文/粤港澳融入/原稿 -> "原稿"
    """
    if not workspace_roots or not isinstance(workspace_roots, list):
        return "Cursor"
    
    first_root = workspace_roots[0]
    if not first_root or not isinstance(first_root, str):
        return "Cursor"
    
    # Get the last path component
    return os.path.basename(first_root) or "Cursor"


def generate_tool_use_id(conversation_id, command, pid):
    """Generate a consistent tool_use_id for shell command tracking."""
    tool_id_input = f"{conversation_id}:{command}:{pid}"
    tool_hash = hashlib.md5(tool_id_input.encode()).hexdigest()[:16]
    return f"cursor-shell-{tool_hash}"


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

    # Cursor provides conversation_id as the session identifier
    conversation_id = data.get("conversation_id", "unknown")
    event = data.get("hook_event_name", "")
    
    # Use workspace_roots[0] as cwd if available, fallback to os.getcwd()
    workspace_roots = data.get("workspace_roots", [])
    if workspace_roots and isinstance(workspace_roots, list) and len(workspace_roots) > 0:
        cwd = workspace_roots[0]
    else:
        cwd = os.getcwd()
    
    # Extract project name from workspace_roots
    project_name = extract_project_name(workspace_roots)

    # Build base state
    state = {
        "provider": "cursor",
        "session_id": f"cursor-{conversation_id}",
        "cwd": cwd,
        "event": event,
        "pid": os.getppid(),
        "tty": get_tty(),
        "transcript_path": data.get("transcript_path"),
        "model": data.get("model"),
        "project_name": project_name,
    }

    # Map Cursor events to Agent Island status
    # Reference: docs/HANDOVER.md "Cursor 3.0 Hooks 开发设计"
    
    if event == "beforeSubmitPrompt":
        # User just sent a message - Agent is now processing
        state["status"] = "processing"
        state["prompt"] = data.get("prompt")

    elif event == "afterAgentResponse":
        # Agent has responded - back to idle/waiting for input
        state["status"] = "waiting_for_input"
        state["last_assistant_message"] = data.get("text")

    elif event == "beforeShellExecution":
        # Agent wants to execute a shell command
        # Note: Cursor's beforeShellExecution doesn't have expectsResponse like Claude
        # We notify the app but don't block - user must go to Cursor to approve
        state["status"] = "waiting_for_approval"
        state["tool"] = "shell"
        # Include command in tool_input for display
        command = data.get("command", "")
        state["tool_input"] = {"command": command}
        
        # Generate a tool_use_id for tracking (Cursor doesn't provide one)
        tool_use_id = generate_tool_use_id(conversation_id, command, os.getppid())
        state["tool_use_id"] = tool_use_id
        
        # Notify the app that approval is needed
        # Cursor doesn't support 'allow' decision via hook - user must go to Cursor to approve
        send_event(state)
        
        # Exit with code 0 to let Cursor show its own approval UI
        sys.exit(0)

    elif event == "afterShellExecution":
        # Shell command completed - back to processing
        state["status"] = "processing"
        state["tool"] = "shell"
        # Include command and result
        command = data.get("command", "")
        result = data.get("result", "")
        state["tool_input"] = {"command": command, "result": result}
        
        # Use same tool_use_id generation as beforeShellExecution
        tool_use_id = generate_tool_use_id(conversation_id, command, os.getppid())
        state["tool_use_id"] = tool_use_id

    elif event == "stop":
        # Session ended - use waiting_for_input to keep session in list
        # (Cursor doesn't have a true "session ended" concept like Claude,
        # it just means the current agent loop finished)
        state["status"] = "waiting_for_input"
        # Optional: include loop_count if available
        if "loop_count" in data:
            state["loop_count"] = data.get("loop_count")

    else:
        state["status"] = "unknown"

    send_event(state)


if __name__ == "__main__":
    main()
