#!/usr/bin/env python3
"""
Qwen Code Subagent Implementation
基于 Linus 哲学：简洁、实用、向后兼容

核心设计：
- 好品味：用策略模式替代复杂条件分支
- Never Break Userspace：完全兼容现有 Claude Code API
- 实用主义：解决 token 限制的实际问题
"""

import os
import json
import subprocess
import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Dict, List, Any, Optional, Protocol
from pathlib import Path
import requests
import time


@dataclass(frozen=True)
class Task:
    """任务数据结构 - 不可变，消除副作用"""
    content: str
    context_files: List[str] = None
    estimated_tokens: int = 0
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.context_files is None:
            object.__setattr__(self, 'context_files', [])
        if self.metadata is None:
            object.__setattr__(self, 'metadata', {})
        
        # 自动估算 token 数量
        if self.estimated_tokens == 0:
            token_count = self._estimate_tokens()
            object.__setattr__(self, 'estimated_tokens', token_count)
    
    def _estimate_tokens(self) -> int:
        """粗略估算 token 数量（1 token ≈ 4 字符）"""
        content_tokens = len(self.content) // 4
        
        # 加上上下文文件的 token
        context_tokens = 0
        for file_path in self.context_files:
            try:
                if os.path.exists(file_path):
                    with open(file_path, 'r', encoding='utf-8') as f:
                        context_tokens += len(f.read()) // 4
            except Exception:
                pass  # 忽略读取错误
        
        return content_tokens + context_tokens


@dataclass(frozen=True)
class ExecutionResult:
    """执行结果 - 统一返回格式"""
    success: bool
    output: str
    executor: str  # "qwen" | "claude" | "fallback"
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.metadata is None:
            object.__setattr__(self, 'metadata', {})


class CodeExecutor(Protocol):
    """统一的代码执行器接口 - 消除特殊情况"""
    
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
    """Qwen Code 执行器 - 支持 CLI 和 API 两种方式"""
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        self.config = config or self._load_config()
        self.cli_path = self.config.get('cli_path', 'qwen-code')
        self.api_endpoint = self.config.get('api_endpoint')
        self.api_key = self.config.get('api_key')
        self.timeout = self.config.get('timeout', 300)
        
        # 设置日志
        self.logger = logging.getLogger(__name__)
    
    def _load_config(self) -> Dict[str, Any]:
        """加载配置文件"""
        config_path = Path.home() / '.claude' / 'qwen-config.json'
        if config_path.exists():
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                self.logger.warning(f"加载 Qwen 配置失败: {e}")
        
        # 默认配置
        return {
            'cli_path': 'qwen-code',
            'timeout': 300,
            'enable_for': [
                'batch_operations',
                'documentation_generation', 
                'large_codebase_analysis',
                'simple_refactoring'
            ]
        }
    
    def can_handle(self, task: Task) -> bool:
        """基于任务特征判断是否适合 Qwen 处理"""
        
        # 检查是否启用了 Qwen 集成
        if not os.getenv('ENABLE_QWEN_INTEGRATION', 'false').lower() == 'true':
            return False
        
        # 基于内容特征的简单映射（无复杂条件分支）
        qwen_patterns = {
            'batch_format': lambda: (task.estimated_tokens >= 15000 and any(word in task.content.lower() for word in ['format', '格式化', '格式'])) or 
                                  ('批量' in task.content.lower() and any(word in task.content.lower() for word in ['format', '格式化', '格式'])),
            'documentation': lambda: any(word in task.content.lower() for word in ['docs', 'document', '文档']),
            'translation': lambda: any(word in task.content.lower() for word in ['translate', '翻译', 'trans']),
            'simple_refactor': lambda: any(word in task.content.lower() for word in ['rename', 'refactor', '重构']),
            'codebase_analysis': lambda: len(task.context_files) > 10,
            'pattern_search': lambda: any(word in task.content.lower() for word in ['find pattern', 'search', '搜索']),
            'large_content': lambda: task.estimated_tokens >= 15000  # 纯粹的大内容任务
        }
        
        # 检查任务是否匹配任何 Qwen 适合的模式
        return any(pattern() for pattern in qwen_patterns.values())
    
    def execute(self, task: Task) -> ExecutionResult:
        """执行任务 - 优先 CLI，回退到 API"""
        
        # 1. 优先尝试 CLI
        if self._cli_available():
            return self._execute_cli(task)
        
        # 2. 回退到 API
        if self.api_endpoint and self.api_key:
            return self._execute_api(task)
        
        # 3. 都不可用
        return ExecutionResult(
            success=False,
            output="Qwen service unavailable",
            executor="qwen",
            metadata={"fallback_reason": "service_unavailable"}
        )
    
    def health_check(self) -> bool:
        """检查 Qwen 服务是否可用"""
        return self._cli_available() or self._api_available()
    
    def _cli_available(self) -> bool:
        """检查 CLI 是否可用"""
        try:
            result = subprocess.run(
                [self.cli_path, '--version'],
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.returncode == 0
        except Exception:
            return False
    
    def _api_available(self) -> bool:
        """检查 API 是否可用"""
        if not (self.api_endpoint and self.api_key):
            return False
        
        try:
            response = requests.get(
                f"{self.api_endpoint}/health",
                headers={"Authorization": f"Bearer {self.api_key}"},
                timeout=10
            )
            return response.status_code == 200
        except Exception:
            return False
    
    def _execute_cli(self, task: Task) -> ExecutionResult:
        """通过 CLI 执行任务"""
        try:
            # 构建 CLI 命令
            cmd = [self.cli_path, "--task", task.content]
            
            # 添加上下文文件
            for file_path in task.context_files:
                if os.path.exists(file_path):
                    cmd.extend(["--file", file_path])
            
            # 执行命令
            self.logger.info(f"执行 Qwen CLI: {' '.join(cmd[:3])}...")
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.timeout
            )
            
            if result.returncode == 0:
                return ExecutionResult(
                    success=True,
                    output=result.stdout,
                    executor="qwen-cli",
                    metadata={"command": cmd[:3]}
                )
            else:
                return ExecutionResult(
                    success=False,
                    output=f"Qwen CLI error: {result.stderr}",
                    executor="qwen-cli",
                    metadata={"error_code": result.returncode}
                )
        
        except subprocess.TimeoutExpired:
            return ExecutionResult(
                success=False,
                output=f"Qwen CLI timeout after {self.timeout}s",
                executor="qwen-cli",
                metadata={"error": "timeout"}
            )
        except Exception as e:
            return ExecutionResult(
                success=False,
                output=f"Qwen CLI execution failed: {str(e)}",
                executor="qwen-cli",
                metadata={"error": str(e)}
            )
    
    def _execute_api(self, task: Task) -> ExecutionResult:
        """通过 API 执行任务"""
        try:
            # 构建 API 请求
            payload = {
                "task": task.content,
                "context_files": task.context_files,
                "metadata": task.metadata
            }
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            
            # 发送请求
            self.logger.info(f"调用 Qwen API: {self.api_endpoint}")
            response = requests.post(
                f"{self.api_endpoint}/execute",
                json=payload,
                headers=headers,
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                result_data = response.json()
                return ExecutionResult(
                    success=True,
                    output=result_data.get("output", ""),
                    executor="qwen-api",
                    metadata={"response_id": result_data.get("id")}
                )
            else:
                return ExecutionResult(
                    success=False,
                    output=f"Qwen API error: {response.status_code} {response.text}",
                    executor="qwen-api",
                    metadata={"status_code": response.status_code}
                )
        
        except requests.RequestException as e:
            return ExecutionResult(
                success=False,
                output=f"Qwen API request failed: {str(e)}",
                executor="qwen-api",
                metadata={"error": str(e)}
            )


class ClaudeExecutor:
    """Claude 执行器 - 兜底方案，永远可用"""
    
    def can_handle(self, task: Task) -> bool:
        """Claude 可以处理任何任务"""
        return True
    
    def execute(self, task: Task) -> ExecutionResult:
        """使用 Claude 处理任务 - 这里是占位符实现"""
        
        # 在实际集成中，这里会调用现有的 Claude 处理逻辑
        # 现在返回一个模拟结果
        return ExecutionResult(
            success=True,
            output=f"Claude processed: {task.content[:100]}...",
            executor="claude",
            metadata={"token_count": task.estimated_tokens}
        )
    
    def health_check(self) -> bool:
        """Claude 永远可用"""
        return True


class TaskScheduler:
    """任务调度器 - Linus 风格：简单、直接、无特殊情况"""
    
    def __init__(self, executors: Optional[List[CodeExecutor]] = None):
        self.executors = executors or [QwenExecutor(), ClaudeExecutor()]
        self.stats = {
            "qwen_success": 0,
            "claude_fallback": 0,
            "total_tasks": 0,
            "errors": 0
        }
        
        # 设置日志
        self.logger = logging.getLogger(__name__)
    
    def route_task(self, task: Task) -> ExecutionResult:
        """路由任务到最合适的执行器"""
        
        self.stats["total_tasks"] += 1
        
        # 按优先级顺序尝试每个执行器
        for executor in self.executors:
            try:
                if executor.can_handle(task) and executor.health_check():
                    self.logger.info(f"路由任务到 {executor.__class__.__name__}")
                    result = executor.execute(task)
                    
                    if result.success:
                        # 更新统计
                        if "qwen" in result.executor:
                            self.stats["qwen_success"] += 1
                        elif result.executor == "claude":
                            self.stats["claude_fallback"] += 1
                        
                        return result
                    else:
                        self.logger.warning(f"{executor.__class__.__name__} 执行失败: {result.output}")
            
            except Exception as e:
                self.logger.error(f"{executor.__class__.__name__} 异常: {str(e)}")
                self.stats["errors"] += 1
                continue
        
        # 所有执行器都失败了（理论上不应该发生，因为 Claude 永远可用）
        self.stats["errors"] += 1
        return ExecutionResult(
            success=False,
            output="All executors failed",
            executor="none",
            metadata={"error": "complete_failure"}
        )
    
    def get_status_report(self) -> str:
        """生成状态报告"""
        total = max(self.stats["total_tasks"], 1)
        qwen_ratio = self.stats["qwen_success"] / total * 100
        
        return f"""Qwen Integration Status:
- Total tasks processed: {self.stats['total_tasks']}
- Routed to Qwen: {self.stats['qwen_success']} ({qwen_ratio:.1f}%)
- Fallback to Claude: {self.stats['claude_fallback']}
- Errors: {self.stats['errors']}
"""


# 向后兼容的 API 函数
def process_user_request(user_input: str, context_files: Optional[List[str]] = None) -> str:
    """
    主要 API 函数 - 完全向后兼容
    
    这个函数保持现有的签名，内部使用智能调度
    """
    
    # 创建任务对象
    task = Task(
        content=user_input,
        context_files=context_files or [],
        metadata={"source": "user_request"}
    )
    
    # 创建调度器（根据环境变量决定是否启用 Qwen）
    if os.getenv("ENABLE_QWEN_INTEGRATION", "false").lower() == "true":
        scheduler = TaskScheduler([QwenExecutor(), ClaudeExecutor()])
    else:
        scheduler = TaskScheduler([ClaudeExecutor()])
    
    # 执行任务
    result = scheduler.route_task(task)
    
    # 返回结果（兼容原有格式）
    if result.success:
        return result.output
    else:
        # 即使失败也要返回有用的信息
        return f"处理失败: {result.output}"


def main():
    """命令行入口点"""
    import sys
    
    if len(sys.argv) < 2:
        print("用法: python qwen_subagent.py <任务描述> [文件1] [文件2] ...")
        return
    
    # 解析命令行参数
    task_content = sys.argv[1]
    context_files = sys.argv[2:] if len(sys.argv) > 2 else []
    
    # 处理请求
    result = process_user_request(task_content, context_files)
    print(result)


if __name__ == "__main__":
    # 配置日志
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    main()