# Qwen Code Subagent Specification

> **🎯 智能代理调度系统 - Linus风格的实用主义设计**

## 核心设计哲学

### "好品味"实现
```
坏代码：if task_type == "simple": use_qwen() elif task_type == "complex": use_claude()
好代码：strategy = TaskStrategy.from_context(task); strategy.execute()
```

### 数据结构优先
```python
# 核心数据结构 - 消除所有特殊情况
@dataclass(frozen=True)
class Task:
    content: str
    context: CodeContext
    estimated_tokens: int
    task_type: TaskType

class ExecutionResult:
    success: bool
    output: str
    executor: str  # "qwen" | "claude" | "fallback"
    metadata: Dict[str, Any]
```

## 任务分类策略

### 自动分类规则（无条件分支）
```python
# 基于 token 估算和内容特征的简单映射
QWEN_SUITABLE_PATTERNS = {
    # 简单重复性任务
    "batch_format": lambda task: task.estimated_tokens > 50000,
    "documentation": lambda task: "generate docs" in task.content.lower(),
    "translation": lambda task: "translate" in task.content.lower(),
    "simple_refactor": lambda task: "rename" in task.content.lower(),
    
    # 大规模分析（利用 Qwen 长上下文）
    "codebase_analysis": lambda task: len(task.context.files) > 20,
    "pattern_search": lambda task: "find pattern" in task.content.lower(),
}

# Claude 专属任务（复杂推理）
CLAUDE_EXCLUSIVE_PATTERNS = {
    "architecture_design": lambda task: "design" in task.content.lower(),
    "complex_debugging": lambda task: "debug" in task.content.lower(),
    "algorithm_optimization": lambda task: "optimize algorithm" in task.content.lower(),
}
```

## 执行器接口设计

### 统一接口（消除特殊情况）
```python
from abc import ABC, abstractmethod
from typing import Protocol

class CodeExecutor(Protocol):
    """统一的代码执行器接口"""
    
    def can_handle(self, task: Task) -> bool:
        """判断是否能处理此任务"""
        ...
    
    def execute(self, task: Task) -> ExecutionResult:
        """执行任务，返回统一结果"""
        ...
    
    def health_check(self) -> bool:
        """服务健康检查"""
        ...

class QwenExecutor:
    """Qwen Code 执行器"""
    
    def __init__(self, config: QwenConfig):
        self.cli_path = config.cli_path or "qwen-code"
        self.api_endpoint = config.api_endpoint
        self.timeout = config.timeout or 300
    
    def execute(self, task: Task) -> ExecutionResult:
        # 1. 优先尝试 CLI
        if self._cli_available():
            return self._execute_cli(task)
        
        # 2. 回退到 API
        if self.api_endpoint:
            return self._execute_api(task)
            
        # 3. 标记为不可用，让调度器回退到 Claude
        return ExecutionResult(
            success=False,
            output="Qwen unavailable",
            executor="qwen",
            metadata={"fallback_reason": "service_unavailable"}
        )

class ClaudeExecutor:
    """Claude 执行器（现有逻辑）"""
    
    def execute(self, task: Task) -> ExecutionResult:
        # 调用现有的 Claude 处理逻辑
        result = self._process_with_claude(task)
        return ExecutionResult(
            success=True,
            output=result,
            executor="claude",
            metadata={}
        )
```

## 调度器核心逻辑

### 零特殊情况的调度器
```python
class TaskScheduler:
    """Linus风格：简单、直接、无特殊情况"""
    
    def __init__(self, executors: List[CodeExecutor]):
        self.executors = executors
    
    def route_task(self, task: Task) -> ExecutionResult:
        """路由逻辑：找到第一个能处理的执行器"""
        
        for executor in self.executors:
            if executor.can_handle(task) and executor.health_check():
                result = executor.execute(task)
                if result.success:
                    return result
        
        # 最后回退到 Claude（永远可用）
        claude = ClaudeExecutor()
        return claude.execute(task)

# 使用示例（配置优先级）
scheduler = TaskScheduler([
    QwenExecutor(config),      # 优先使用 Qwen
    ClaudeExecutor()           # Claude 作为兜底
])
```

## 配置和部署

### 简单配置文件
```yaml
# qwen-config.yml
qwen:
  cli_path: "qwen-code"  # 或者绝对路径
  api_endpoint: "https://api.qwen.com/v1"
  api_key: "${QWEN_API_KEY}"
  timeout: 300
  
  # 任务路由配置
  enable_for:
    - batch_operations
    - documentation_generation
    - large_codebase_analysis
    - simple_refactoring
  
  # 健康检查配置
  health_check:
    interval: 60  # 秒
    retry_count: 3
```

### 集成到现有工作流
```bash
# 在现有的 setup-claude-workflow-enhanced.sh 中添加
echo "🤖 配置 Qwen Code 集成..."

# 检查 Qwen Code 是否可用
if command -v qwen-code >/dev/null 2>&1; then
    echo "✅ Qwen Code CLI 已安装"
    
    # 复制配置文件
    cp qwen-config.yml .claude/
    
    # 设置环境变量
    echo "export ENABLE_QWEN_INTEGRATION=true" >> .claude/config
else
    echo "⚠️  Qwen Code CLI 未安装，将仅使用 Claude"
    echo "export ENABLE_QWEN_INTEGRATION=false" >> .claude/config
fi
```

## 错误处理和回退机制

### 健壮的错误处理
```python
class RobustScheduler:
    """永远不失败的调度器"""
    
    def execute_with_fallback(self, task: Task) -> ExecutionResult:
        """多层回退策略"""
        
        try:
            # 第一优先级：Qwen
            if self.qwen.health_check():
                result = self.qwen.execute(task)
                if result.success:
                    self._log_success("qwen", task)
                    return result
                
            # 第二优先级：Claude（永远可用）
            result = self.claude.execute(task)
            self._log_fallback("claude", task, "qwen_failed")
            return result
            
        except Exception as e:
            # 最后的保险：返回错误信息而不是崩溃
            self._log_error(e, task)
            return ExecutionResult(
                success=False,
                output=f"All executors failed: {str(e)}",
                executor="none",
                metadata={"error": str(e)}
            )
```

## 监控和状态报告

### 简单的状态报告
```python
class ExecutionMonitor:
    """执行状态监控"""
    
    def __init__(self):
        self.stats = {
            "qwen_success": 0,
            "claude_fallback": 0,
            "total_tasks": 0
        }
    
    def report_status(self) -> str:
        """生成状态报告"""
        qwen_ratio = self.stats["qwen_success"] / max(self.stats["total_tasks"], 1)
        
        return f"""
Qwen Integration Status:
- Tasks routed to Qwen: {self.stats['qwen_success']}
- Fallback to Claude: {self.stats['claude_fallback']}
- Qwen success rate: {qwen_ratio:.1%}
        """
```

## 实际使用接口

### 向后兼容的 API
```python
# 现有的 Claude Code 调用方式保持不变
def process_user_request(user_input: str) -> str:
    """现有接口，零破坏性"""
    
    # 解析任务
    task = Task.from_user_input(user_input)
    
    # 智能调度（用户无感知）
    if os.getenv("ENABLE_QWEN_INTEGRATION") == "true":
        scheduler = TaskScheduler([QwenExecutor(), ClaudeExecutor()])
    else:
        scheduler = TaskScheduler([ClaudeExecutor()])
    
    # 执行并返回结果
    result = scheduler.route_task(task)
    return result.output
```

### 命令行扩展
```bash
# 新增可选的显式调用方式
claude-code --executor qwen "批量格式化所有Python文件"
claude-code --executor claude "设计新的架构方案"  
claude-code --executor auto "自动选择最佳执行器"  # 默认行为
```

## 部署和测试

### 集成测试套件
```python
def test_qwen_integration():
    """集成测试：确保 Qwen 集成不破坏现有功能"""
    
    # 1. 测试向后兼容性
    assert process_user_request("hello") == "hello (processed by claude)"
    
    # 2. 测试 Qwen 路由
    os.environ["ENABLE_QWEN_INTEGRATION"] = "true"
    result = process_user_request("批量重命名所有函数")
    assert "qwen" in result.lower()
    
    # 3. 测试回退机制
    with mock.patch("QwenExecutor.health_check", return_value=False):
        result = process_user_request("任务")
        assert result  # Claude 应该接管
```

### 渐进式部署策略
```bash
# 阶段1：仅启用文档生成
echo "QWEN_ENABLE_TASKS=documentation" >> .claude/config

# 阶段2：启用批量操作  
echo "QWEN_ENABLE_TASKS=documentation,batch_format" >> .claude/config

# 阶段3：全面启用
echo "QWEN_ENABLE_TASKS=all" >> .claude/config
```

## 性能优化

### Token 优化策略
```python
class TokenOptimizer:
    """基于 Linus 的实用主义：优化实际瓶颈"""
    
    def estimate_task_cost(self, task: Task) -> int:
        """估算任务的 token 消耗"""
        
        base_cost = len(task.content) // 4  # 粗略估算
        context_cost = sum(len(f.content) for f in task.context.files) // 4
        
        return base_cost + context_cost
    
    def should_use_qwen(self, task: Task) -> bool:
        """基于成本的路由决策"""
        
        estimated_cost = self.estimate_task_cost(task)
        
        # Qwen 适合处理大量内容
        return estimated_cost > 10000 and any(
            pattern(task) for pattern in QWEN_SUITABLE_PATTERNS.values()
        )
```

## 总结

这个 Qwen Code 子代理规范遵循 Linus 的核心哲学：

1. **好品味**：用策略模式消除复杂的条件分支
2. **Never Break Userspace**：完全向后兼容现有 API
3. **实用主义**：解决 token 限制的实际问题
4. **简洁性**：核心逻辑不超过3层缩进

关键特性：
- ✅ 智能任务路由（基于内容和规模）
- ✅ 多种 Qwen 调用方式（CLI + API）
- ✅ 健壮的错误处理和回退机制
- ✅ 零破坏性集成到现有工作流
- ✅ 简单的监控和状态报告

这个设计确保了系统的可靠性：即使 Qwen 完全不可用，现有功能也不会受到任何影响。

---

> *"这不是在解决假想的问题，而是在解决 Claude token 限制的实际痛点。"* - Linus Style Analysis