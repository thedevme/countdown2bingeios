# Phase Commit

Commit and push the current phase's work.

## Instructions

1. Read the build plan at `/docs/build-plan.md`
2. Ask me which phase number was just completed
3. Find that phase's title in the build plan
4. Save the conversation log before committing:

```bash
mkdir -p docs/conversations

python3 << 'PYEOF'
import json
import os
from datetime import datetime

# Find the current session file
claude_dir = os.path.expanduser("~/.claude/projects/-Users-craigclayton-apps-appstore-Countdown2Binge")
session_files = [f for f in os.listdir(claude_dir) if f.endswith('.jsonl')]
if not session_files:
    print("No session file found")
    exit(0)

# Use the most recent session file
session_files.sort(key=lambda x: os.path.getmtime(os.path.join(claude_dir, x)), reverse=True)
input_file = os.path.join(claude_dir, session_files[0])

# Generate output filename with timestamp
timestamp = datetime.now().strftime("%Y-%m-%d_%H%M")
output_file = f"docs/conversations/{timestamp}-session.md"

messages = []
with open(input_file, 'r') as f:
    for line in f:
        try:
            data = json.loads(line.strip())
            messages.append(data)
        except:
            continue

with open(output_file, 'w') as out:
    out.write(f"# Conversation Log - {datetime.now().strftime('%B %d, %Y %H:%M')}\n\n")
    out.write("---\n\n")

    for msg in messages:
        msg_type = msg.get('type', '')

        if msg_type == 'user':
            out.write("## USER\n\n")
            content = msg.get('message', {}).get('content', [])
            if isinstance(content, list):
                for item in content:
                    if isinstance(item, dict):
                        if item.get('type') == 'text':
                            out.write(item.get('text', '') + "\n\n")
                        elif item.get('type') == 'tool_result':
                            out.write(f"*[Tool result received]*\n\n")
                    elif isinstance(item, str):
                        out.write(item + "\n\n")
            elif isinstance(content, str):
                out.write(content + "\n\n")
            out.write("---\n\n")

        elif msg_type == 'assistant':
            out.write("## ASSISTANT\n\n")
            content = msg.get('message', {}).get('content', [])
            if isinstance(content, list):
                for item in content:
                    if isinstance(item, dict):
                        if item.get('type') == 'text':
                            text = item.get('text', '')
                            if text:
                                out.write(text + "\n\n")
                        elif item.get('type') == 'tool_use':
                            tool_name = item.get('name', 'unknown')
                            tool_input = item.get('input', {})
                            if tool_name == 'Edit':
                                out.write(f"*[Edit: {tool_input.get('file_path', 'file')}]*\n\n")
                            elif tool_name == 'Read':
                                out.write(f"*[Read: {tool_input.get('file_path', 'file')}]*\n\n")
                            elif tool_name == 'Write':
                                out.write(f"*[Write: {tool_input.get('file_path', 'file')}]*\n\n")
                            elif tool_name == 'Bash':
                                cmd = tool_input.get('command', '')[:80]
                                out.write(f"*[Bash: {cmd}...]*\n\n")
                            else:
                                out.write(f"*[Tool: {tool_name}]*\n\n")
            out.write("---\n\n")

print(f"Conversation saved to {output_file}")
PYEOF
```

5. Commit and push:
```bash
git add -A && git commit -m "Phase {PHASE_NUMBER}: {PHASE_TITLE}" && git push
```