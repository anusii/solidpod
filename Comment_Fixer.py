import os
import re

def fix_dart_comments(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    fixed_lines = []
    i = 0
    in_header = True  
    # Keywords to identify logical code blocks that should stay compact
    code_keywords = [r'debugPrint\(', r'print\(', r'if\s*\(', r'final\s+', r'var\s+', r'return\s+', r'await\s+']

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # 1. Skip file header (Copyright/Licence blocks)
        if in_header and stripped != "" and not stripped.startswith('//'):
            in_header = False
        if in_header or not stripped.startswith('//'):
            fixed_lines.append(line)
            i += 1
            continue

        # 2. Skip machine instructions (ignore / ignore_for_file)
        if re.match(r'^//\s*ignore(_for_file)?:', stripped):
            fixed_lines.append(line)
            i += 1
            continue

        # --- 3. Process Comment Blocks ---
        comment_block = []
        indentation = len(line) - len(line.lstrip()) # Detect indentation level
        
        while i < len(lines):
            curr_stripped = lines[i].strip()
            # Stop if the line is not a comment or is a machine instruction
            if not curr_stripped.startswith('//') or re.match(r'^//\s*ignore(_for_file)?:', curr_stripped):
                break
            comment_block.append(lines[i])
            i += 1
        
        if not comment_block:
            continue

        # Process Full Stops (only on the last line of a block)
        processed_block = []
        for index, c_line in enumerate(comment_block):
            c_stripped = c_line.strip()
            is_code = any(re.search(kw, c_stripped) for kw in code_keywords)
            
            # Apply full stop if it's the last line, is English, and not a code snippet
            if index == len(comment_block) - 1 and not is_code:
                if re.search(r'//\s+[A-Za-z0-9].*[^.!?:\;\'"]$', c_stripped):
                    if re.search(r'[A-Za-z]', c_stripped):
                        c_line = c_line.rstrip() + '.\n'
            processed_block.append(c_line)

        # --- Rule A: Blank Line BEFORE ---
        if len(fixed_lines) > 0:
            prev_line = fixed_lines[-1].strip()
            # Exempt if follows opening brackets or is already separated
            skip_before = prev_line.endswith('(') or prev_line.endswith('{') or \
                          prev_line.endswith('[') or \
                          prev_line == "" or prev_line.startswith('//')
            if not skip_before:
                fixed_lines.append('\n')

        fixed_lines.extend(processed_block)

        # --- Rule B: Blank Line AFTER ---
        if i < len(lines):
            next_line = lines[i].strip()
            
            # Logic Step Exemption: Keep compact if inside a method and followed by logic keywords
            is_logic_step = indentation > 0 and (
                next_line.startswith('final ') or 
                next_line.startswith('var ') or 
                next_line.startswith('await ') or
                next_line.startswith('if (')
            )

            # Exempt if followed by closing brackets, commas, named parameters, or logic steps
            skip_after = next_line.startswith(')') or next_line.startswith('}') or \
                         next_line.startswith(']') or next_line.startswith(',') or \
                         re.search(r'^\w+:', next_line) or \
                         is_logic_step or \
                         next_line == "" or next_line.startswith('//')
            
            if not skip_after:
                fixed_lines.append('\n')
        
    return fixed_lines

def main():
    print("🚀 Running Comment Fixer...")
    count = 0
    for root, dirs, files in os.walk('.'):
        # Skip hidden directories like .dart_tool
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                with open(file_path, 'r', encoding='utf-8') as f:
                    original = f.readlines()
                
                fixed = fix_dart_comments(file_path)
                
                if original != fixed:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.writelines(fixed)
                    print(f"✅ Formatted: {file_path}")
                    count += 1
                    
    print(f"\n✨ Process complete! {count} files were updated.")

if __name__ == "__main__":
    main()