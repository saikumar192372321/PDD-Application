import json
import os
import re

log_file = "/Users/sail/.gemini/antigravity/brain/1ab2e939-99c3-40b5-a4b3-a028cfe53acd/.system_generated/logs/overview.txt"
with open(log_file, "r") as f:
    lines = f.readlines()

actions = []

for line in lines:
    try:
        data = json.loads(line)
        if data.get("type") == "PLANNER_RESPONSE" and "tool_calls" in data:
            for call in data["tool_calls"]:
                if call["name"] in ["replace_file_content", "multi_replace_file_content"]:
                    args = call["args"]
                    target_file = args.get("TargetFile", "").strip('"')
                    
                    if call["name"] == "replace_file_content":
                        tc = args.get("TargetContent", "")
                        rc = args.get("ReplacementContent", "")
                        actions.append((target_file, rc, tc))
                    else:
                        chunks = args.get("ReplacementChunks", [])
                        if isinstance(chunks, str):
                            try:
                                chunks = json.loads(chunks)
                            except:
                                # Sometimes it's double escaped
                                try:
                                    chunks = json.loads(json.loads('"' + chunks + '"'))
                                except:
                                    pass
                        if isinstance(chunks, list):
                            for chunk in chunks:
                                if isinstance(chunk, dict):
                                    tc = chunk.get("TargetContent", "")
                                    rc = chunk.get("ReplacementContent", "")
                                    actions.append((target_file, rc, tc))
    except Exception as e:
        pass

actions.reverse()
print(f"Found {len(actions)} replacement actions to reverse.")

for target_file, old_content, new_content in actions:
    if os.path.exists(target_file):
        with open(target_file, "r") as f:
            content = f.read()
        
        # Exact match
        if old_content in content:
            content = content.replace(old_content, new_content, 1)
            with open(target_file, "w") as f:
                f.write(content)
            print(f"Reverted change in {target_file}")
        else:
            # Try to match by lines, ignoring leading/trailing empty lines
            old_lines = old_content.strip().split('\n')
            new_lines = new_content.strip().split('\n')
            if old_content.strip() in content:
                content = content.replace(old_content.strip(), new_content.strip(), 1)
                with open(target_file, "w") as f:
                    f.write(content)
                print(f"Reverted change in {target_file} (using stripped version)")
            else:
                print(f"Warning: Could not find content to revert in {target_file}")

