#!/usr/bin/env python3
"""
Cursor Bridge - 测试 Cursor hooks 的数据格式

使用方法:
1. 修改 ~/.cursor/hooks.json，将 command 指向此脚本
2. 在 Cursor 中进行操作（发送消息、运行命令等）
3. 查看日志文件 /tmp/cursor-bridge.log
"""

import json
import sys
import os
import datetime

def log_event(event_type, data):
    """记录事件到日志文件"""
    log_entry = {
        "timestamp": datetime.datetime.now().isoformat(),
        "event": event_type,
        "data": data,
        "env": dict(os.environ)
    }
    
    with open("/tmp/cursor-bridge.log", "a") as f:
        f.write(json.dumps(log_entry, indent=2, default=str))
        f.write("\n" + "="*80 + "\n")

def main():
    """主函数 - 接收 Cursor 的 hook 调用"""
    
    # 从命令行参数获取事件类型
    # Cursor 可能通过参数或环境变量传递信息
    event_type = "unknown"
    
    if len(sys.argv) > 1:
        # 检查 --source cursor 参数
        if "--source" in sys.argv:
            idx = sys.argv.index("--source")
            if idx + 1 < len(sys.argv):
                event_type = f"source:{sys.argv[idx + 1]}"
    
    # 收集所有可用的信息
    data = {
        "argv": sys.argv,
        "stdin": None,
        "cwd": os.getcwd()
    }
    
    # 尝试读取 stdin（可能传递 JSON 数据）
    try:
        if not sys.stdin.isatty():
            stdin_content = sys.stdin.read()
            if stdin_content:
                try:
                    data["stdin"] = json.loads(stdin_content)
                except:
                    data["stdin"] = stdin_content
    except:
        pass
    
    # 记录事件
    log_event(event_type, data)
    
    # 同时输出到 stderr（方便调试）
    print(f"[cursor-bridge] Event: {event_type}", file=sys.stderr)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
