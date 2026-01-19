# 一键运行 one click
### 同步到目标目录
```
bash <(curl -s https://raw.githubusercontent.com/developer-hq/ClaudeCodePrivateTemplate/main/quick-sync.sh) TargetPath
```
### 同步到当前目录
```
bash <(curl -s https://raw.githubusercontent.com/developer-hq/ClaudeCodePrivateTemplate/main/quick-sync.sh) .
```


已配置的hooks：

  1. **Notification** (第51-64行) - Claude发送通知时触发
     - 播放系统提示音
     - 发送推送通知到移动设备（通过 Bark API）

  2. **Stop** (第66-80行) - Claude停止运行时触发
     - 播放系统提示音
     - 发送推送通知到移动设备（通过 Bark API）

  3. **PostToolUse - TodoWrite** (第81-91行) - 任务状态更新时触发
     - 当任务标记为 `in_progress` 时，自动推送正在执行的任务名称
     - 使用较轻的提示音（minuet）避免频繁打扰

注：之前版本包含的 UserPromptSubmit、Start 和 PostToolUse（自动git提交）hooks 已被移除

