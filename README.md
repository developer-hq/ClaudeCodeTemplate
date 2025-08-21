# 一键运行 one click
### 同步到目标目录
```
bash <(curl -s https://raw.githubusercontent.com/developer-hq/ClaudeCodeTemplate/main/quick-sync.sh) TargetPath
```
### 同步到当前目录
```
bash <(curl -s https://raw.githubusercontent.com/developer-hq/ClaudeCodeTemplate/main/quick-sync.sh) .
```


已配置的hooks：

  1. UserPromptSubmit (第85-94行) - 用户提交prompt时响铃3次
  2. Notification (第45-54行) - 通知时响铃3次
  3. start (第107-116行) - Claude启动时响铃3次
  4. stop (第96-105行) - Claude停止时响铃3次
  5. PostToolUse hooks:
    - Edit工具后自动git提交 (第58-64行)
    - Write工具后自动git提交 (第67-73行)
    - 所有文件操作后自动git add (第76-82行)

