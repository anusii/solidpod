import os
import re

def check_dart_comments(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    issues = []
    
    for i in range(len(lines)):
        line = lines[i]
        stripped = line.strip()

        # 匹配单行注释 // 或 文档注释 ///
        if stripped.startswith('//'):
            # 1. 检查句尾是否有句号 (针对英文注释)
            # 匹配以字母数字开头，但结尾不是 . ! ? 的注释
            if re.search(r'//\s+[A-Za-z0-9].*[^.!?]$', stripped):
                issues.append(f"Line {i+1}: Comment does not end with a full stop.")

            # 2. 检查前后空行逻辑
            if i > 0 and i < len(lines) - 1:
                prev_line = lines[i-1].strip()
                next_line = lines[i+1].strip()

                # 判断是否在括号后的第一行：例如 `( {` 后面
                after_parenthesis = prev_line.endswith('(') or prev_line.endswith('{')

                # 检查前一行是否为空行 (除非是在括号后)
                if not after_parenthesis and prev_line != "" and not prev_line.startswith('//'):
                    issues.append(f"Line {i+1}: Missing blank line BEFORE comment.")

                # 检查后一行是否为空行
                if next_line != "" and not next_line.startswith('//'):
                    issues.append(f"Line {i+1}: Missing blank line AFTER comment.")

    return issues

def main():
    print("🔍 Starting Comment Style Check...")
    found_any_issue = False
    
    # 递归遍历所有目录，排除隐藏目录（如 .dart_tool）
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                file_issues = check_dart_comments(file_path)
                
                if file_issues:
                    found_any_issue = True
                    print(f"\n❌ Issues in: {file_path}")
                    for issue in file_issues:
                        print(f"   {issue}")

    if not found_any_issue:
        print("\n✅ All .dart files adhere to the comment guidelines!")

if __name__ == "__main__":
    main()