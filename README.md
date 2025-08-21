# 一键运行 one click
```
git clone --depth 1 --filter=blob:none --sparse git@github.com:developer-hq/ClaudeCodeTemplate.git /tmp/claude-tmp && cd /tmp/claude-tmp && git sparse-checkout set .claude && cp -r .claude . && rm -rf /tmp/claude-tmp
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

