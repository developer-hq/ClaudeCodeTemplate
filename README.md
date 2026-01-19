# 一键运行 one click
### 同步到目标目录
```
bash <(curl -s https://raw.githubusercontent.com/developer-hq/ClaudeCodeTemplate/master/quick-sync.sh) TargetPath
```
### 同步到当前目录
```
bash <(curl -s https://raw.githubusercontent.com/developer-hq/ClaudeCodeTemplate/master/quick-sync.sh) .
```


已配置的hooks：

  1. **Notification** (第51-64行) - Claude发送通知时触发
     - 播放系统提示音
     - 发送推送通知到移动设备（通过 Bark API）
     - 需要在运行 quick-sync.sh 时配置 Bark Token

  2. **Stop** (第66-80行) - Claude停止运行时触发
     - 播放系统提示音
     - 发送推送通知到移动设备（通过 Bark API）
     - 需要在运行 quick-sync.sh 时配置 Bark Token

## 使用说明

1. 运行 quick-sync.sh 脚本同步配置
2. 脚本会提示输入 Bark Token（用于手机推送通知）
3. 如果跳过 Token 配置，可以后续手动编辑 `.claude/settings.json`，将 `YOUR_BARK_TOKEN_HERE` 替换为你的 Bark Token

注：之前版本包含的 UserPromptSubmit、Start 和 PostToolUse（自动git提交、任务跟踪）hooks 已被移除

