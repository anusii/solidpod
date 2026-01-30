import os
import re

def check_dart_comments(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    issues = []
    in_header = True
    # Keywords to identify logical code blocks that should stay compact
    code_keywords = [r'debugPrint\(', r'print\(', r'if\s*\(', r'final\s+', r'var\s+', r'return\s+', r'await\s+']
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # 1. Skip file header (Copyright/Licence blocks)
        if in_header and stripped != "" and not stripped.startswith('//'):
            in_header = False
        if in_header or not stripped.startswith('//'):
            i += 1
            continue

        # 2. Skip machine instructions (ignore / ignore_for_file)
        if re.match(r'^//\s*ignore(_for_file)?:', stripped):
            i += 1
            continue

        # --- 3. Collect Comment Blocks ---
        block_start_index = i
        comment_block = []
        indentation = len(line) - len(line.lstrip())
        
        while i < len(lines) and lines[i].strip().startswith('//'):
            # Stop if the line is a machine instruction
            if re.match(r'^//\s*ignore(_for_file)?:', lines[i].strip()):
                break
            comment_block.append(lines[i].strip())
            i += 1
        
        if not comment_block:
            continue

        # --- Rule Check: Full Stop (on the last line of the block) ---
        last_line = comment_block[-1]
        is_code = any(re.search(kw, last_line) for kw in code_keywords)
        if not is_code and re.search(r'[A-Za-z]', last_line):
            # Check if missing . ! ? : ; ' " at the end
            if re.search(r'//\s+[A-Za-z0-9].*[^.!?:\;\'"]$', last_line):
                issues.append(f"Line {block_start_index + len(comment_block)}: Missing full stop at end of sentence.")

        # --- Rule Check: Blank Line BEFORE ---
        if block_start_index > 0:
            prev = lines[block_start_index - 1].strip()
            # Exempt if follows opening brackets or is already separated
            skip_before = prev.endswith('(') or prev.endswith('{') or \
                          prev.endswith('[') or prev == "" or \
                          prev.startswith('//')
            
            if not skip_before:
                issues.append(f"Line {block_start_index + 1}: Missing blank line BEFORE comment block.")

        # --- Rule Check: Blank Line AFTER ---
        if i < len(lines):
            nxt = lines[i].strip()
            # Logic Step Exemption: Inside methods, following logic keywords
            is_logic_step = indentation > 0 and any(nxt.startswith(k) for k in ['final ', 'var ', 'await ', 'if ('])
            
            # Exempt if followed by closing brackets, commas, named parameters, or logic steps
            skip_after = nxt.startswith(')') or nxt.startswith('}') or \
                         nxt.startswith(']') or nxt.startswith(',') or \
                         re.search(r'^\w+:', nxt) or is_logic_step or \
                         nxt == "" or nxt.startswith('//')

            if not skip_after:
                issues.append(f"Line {i}: Missing blank line AFTER comment block.")

    return issues

def main():
    print("🔍 Starting Comment Style Check")
    found_any_issue = False
    
    # Recursively traverse all directories, excluding hidden ones (e.g., .dart_tool)
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                file_issues = check_dart_comments(file_path)
                
                if file_issues:
                    found_any_issue = True
                    print(f"\n❌ {file_path}:")
                    for issue in file_issues:
                        print(f"   {issue}")

    if not found_any_issue:
        print("\n✅ All .dart files adhere to the project guidelines!")

if __name__ == "__main__":
    main()