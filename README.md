# Claude Code Template

> **🎯 Linus风格的Claude Code自动化开发工作流模板**

一个完整的Claude Code项目模板，集成了智能自动提交、uv Python项目管理、MCP服务配置和测试驱动开发支持。

## 🚀 快速开始

### 方法一：完整安装（推荐）
```bash
git clone https://github.com/developer-hq/ClaudeCodeTemplate.git my-project
cd my-project
./setup-claude-workflow-enhanced.sh
```

### 方法二：快速安装
```bash
git clone https://github.com/developer-hq/ClaudeCodeTemplate.git my-project
cd my-project
./quick-setup.sh
```

## ✨ 核心特性

### 🧠 Linus哲学驱动
- **好品味优先**：消除特殊情况，优化数据结构
- **Never Break Userspace**：绝对向后兼容
- **实用主义**：解决实际问题，拒绝过度工程
- **查看文档优先**：修改困难包时优先查询官方文档

### 🔧 自动化工作流
- **智能自动提交**：对话结束后自动commit，token优化
- **安全检查机制**：冲突检测、远程状态检查
- **格式化提交消息**：自动生成规范的git commit格式
- **后台推送支持**：可选的后台git push，显示PID方便管理

### 🐍 现代Python开发
- **uv集成**：现代Python项目管理，虚拟环境自动化
- **依赖管理**：自动安装pytest, black, isort, mypy等开发工具
- **版本控制**：支持Python版本选择和uv.lock文件同步

### ✅ 代码质量保障
- **pre-commit集成**：自动代码格式化和质量检查
- **类型检查**：mypy静态类型分析
- **测试覆盖**：pytest自动化测试框架
- **代码风格**：black格式化 + isort导入排序

### 🧪 测试驱动开发
- **TDD输出样式**：使用`/output-style tdd`进入TDD模式
- **Red-Green-Refactor循环**：强制执行标准TDD流程
- **测试优先**：在TDD模式下必须先写测试

### 🔌 MCP服务集成
自动配置以下MCP服务：
- **context7**: 官方文档查询和API参考
- **grep**: GitHub代码搜索，查看实际使用案例  
- **spec-workflow**: 需求文档和设计规格管理

### 🤖 Qwen Code 智能集成
- **智能任务路由**：自动判断使用 Qwen 还是 Claude 处理任务
- **多种调用方式**：支持 CLI 和 API 两种方式调用 Qwen
- **零破坏性**：完全向后兼容，Qwen 不可用时自动回退到 Claude
- **任务分类**：自动识别批量操作、文档生成、翻译等适合 Qwen 的任务

## 📁 文件结构

```
ClaudeCodeTemplate/
├── setup-claude-workflow-enhanced.sh  # 完整安装脚本
├── quick-setup.sh                     # 快速安装脚本  
├── setup-qwen-integration.sh          # Qwen Code 集成脚本
├── claude-base-template.md            # Claude基础提示词模板
├── tdd-output-style.md               # TDD输出样式定义
├── qwen-subagent-spec.md             # Qwen 子代理规范文档
├── qwen_subagent.py                  # Qwen 子代理实现
├── qwen-config.json                  # Qwen 配置文件
├── example_usage.py                  # 使用示例
├── test_qwen_integration.py          # 集成测试
└── README.md                         # 本文件
```

## 🎯 使用场景

### 传统项目
```bash
# Git项目 + 自动提交 + MCP服务
./quick-setup.sh
```

### Python项目（推荐）
```bash  
# uv项目管理 + pre-commit + 完整工作流
./setup-claude-workflow-enhanced.sh
# 选择: 使用uv -> 是
# 选择: Python版本 -> 3.11
# 选择: 启用pre-commit -> 是
```

### TDD开发
```bash
# 首先设置项目
./setup-claude-workflow-enhanced.sh

# 然后在Claude Code中切换到TDD模式
/output-style tdd
```

### Qwen Code 集成
```bash
# 设置 Qwen Code 集成（可选）
./setup-qwen-integration.sh

# 查看集成状态
.claude/qwen-status.sh

# 测试集成功能
python3 test_qwen_integration.py

# 运行使用示例
python3 example_usage.py
```

## 🔄 工作流程

1. **项目初始化**: 运行安装脚本配置环境
2. **正常开发**: 与Claude对话，实现功能
3. **自动提交**: 对话结束后自动commit（token优化）
4. **代码质量**: pre-commit自动检查和修复
5. **可选推送**: 后台push到远程仓库

## 🎮 命令参考

### Claude Code命令
```bash
/output-style tdd      # 切换到TDD模式
/output-style default  # 返回默认模式
/output-style         # 查看所有可用样式
```

### uv项目管理
```bash
uv run python main.py  # 运行脚本
uv run pytest         # 运行测试
uv add requests        # 添加依赖
uv add --dev black     # 添加开发依赖
```

### 手动操作
```bash
./.claude/smart-commit-hook.sh  # 手动触发提交
jobs                           # 查看后台任务
kill <PID>                     # 停止后台推送
```

### Qwen Code 命令
```bash
./.claude/qwen-call.sh "任务描述"    # 直接调用 Qwen
./.claude/qwen-status.sh           # 查看集成状态
./.claude/qwen-test.sh            # 运行集成测试
python3 qwen_subagent.py "任务"    # 直接运行子代理
```

## 🛠️ 定制配置

### Git提交格式
自动生成格式：`[类型] 内容 操作 用户`
- `[feat]` - 新功能
- `[fix]` - Bug修复
- `[dev]` - 开发中  
- `[cleanup]` - 清理代码

### pre-commit检查项
- **uv-lock**: 保持依赖文件同步
- **black**: 代码格式化
- **isort**: import语句排序
- **mypy**: 静态类型检查
- **基础检查**: 文件结尾、YAML格式等

## 🔍 故障排除

### 常见问题

**Q: uv命令未找到**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

**Q: MCP服务配置失败**
```bash
# 手动配置
claude mcp add --transport http context7 https://mcp.context7.com/mcp
claude mcp add --transport http grep https://mcp.grep.app
```

**Q: pre-commit检查失败**
```bash
# 手动修复后重新提交
uv run pre-commit run --all-files
git add .
git commit -m "fix: 修复代码格式问题"
```

## 🤝 贡献

这个模板遵循Linus Torvalds的设计哲学：
- **好品味**：简洁优雅的解决方案
- **实用主义**：解决实际问题
- **向后兼容**：不破坏现有工作流

欢迎提交Issue和PR来改进这个模板！

## 📄 许可证

MIT License - 自由使用和修改

---

> *"好程序员担心数据结构，坏程序员担心代码。"* - Linus Torvalds

**享受高效的Claude Code开发体验！** 🚀