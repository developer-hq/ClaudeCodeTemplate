#!/usr/bin/env python3
"""
Qwen Code Subagent 集成测试
确保系统的健壮性和向后兼容性
"""

import unittest
import os
import sys
from unittest.mock import Mock, patch
from pathlib import Path

# 添加当前目录到 Python 路径
sys.path.insert(0, str(Path(__file__).parent))

from qwen_subagent import (
    Task, ExecutionResult, QwenExecutor, ClaudeExecutor, 
    TaskScheduler, process_user_request
)


class TestTask(unittest.TestCase):
    """测试 Task 数据结构"""
    
    def test_task_creation(self):
        """测试任务创建"""
        task = Task("测试内容")
        self.assertEqual(task.content, "测试内容")
        self.assertEqual(task.context_files, [])
        self.assertIsInstance(task.estimated_tokens, int)
        self.assertGreater(task.estimated_tokens, 0)
    
    def test_task_token_estimation(self):
        """测试 token 估算"""
        short_task = Task("短")
        long_task = Task("很长的内容 " * 100)
        
        self.assertLess(short_task.estimated_tokens, long_task.estimated_tokens)
    
    def test_task_with_context_files(self):
        """测试带上下文文件的任务"""
        # 创建临时文件
        test_file = "test_temp.txt"
        with open(test_file, 'w') as f:
            f.write("测试内容 " * 50)
        
        try:
            task = Task("任务", [test_file])
            # 应该包含文件内容的 token
            self.assertGreater(task.estimated_tokens, len("任务") // 4)
        finally:
            if os.path.exists(test_file):
                os.remove(test_file)


class TestExecutionResult(unittest.TestCase):
    """测试 ExecutionResult 数据结构"""
    
    def test_result_creation(self):
        """测试结果创建"""
        result = ExecutionResult(
            success=True,
            output="测试输出",
            executor="test"
        )
        
        self.assertTrue(result.success)
        self.assertEqual(result.output, "测试输出")
        self.assertEqual(result.executor, "test")
        self.assertEqual(result.metadata, {})


class TestClaudeExecutor(unittest.TestCase):
    """测试 Claude 执行器"""
    
    def test_claude_can_handle_all_tasks(self):
        """测试 Claude 可以处理所有任务"""
        executor = ClaudeExecutor()
        task = Task("任何任务")
        
        self.assertTrue(executor.can_handle(task))
    
    def test_claude_health_check(self):
        """测试 Claude 健康检查"""
        executor = ClaudeExecutor()
        self.assertTrue(executor.health_check())
    
    def test_claude_execution(self):
        """测试 Claude 执行"""
        executor = ClaudeExecutor()
        task = Task("测试任务")
        
        result = executor.execute(task)
        
        self.assertIsInstance(result, ExecutionResult)
        self.assertTrue(result.success)
        self.assertEqual(result.executor, "claude")


class TestQwenExecutor(unittest.TestCase):
    """测试 Qwen 执行器"""
    
    def setUp(self):
        """设置测试环境"""
        self.executor = QwenExecutor()
    
    def test_qwen_task_classification(self):
        """测试 Qwen 任务分类"""
        # 禁用 Qwen 集成时，不应该处理任何任务
        with patch.dict(os.environ, {'ENABLE_QWEN_INTEGRATION': 'false'}):
            executor = QwenExecutor()
            task = Task("任何任务")
            self.assertFalse(executor.can_handle(task))
        
        # 启用 Qwen 集成时，应该能处理特定类型的任务
        with patch.dict(os.environ, {'ENABLE_QWEN_INTEGRATION': 'true'}):
            executor = QwenExecutor()
            
            # 文档生成任务
            doc_task = Task("生成项目文档")
            self.assertTrue(executor.can_handle(doc_task))
            
            # 翻译任务
            trans_task = Task("翻译这些内容")
            self.assertTrue(executor.can_handle(trans_task))
            
            # 大规模任务
            large_task = Task("格式化代码 " * 10000)  # 大内容
            self.assertTrue(executor.can_handle(large_task))
    
    @patch('subprocess.run')
    def test_qwen_cli_availability_check(self, mock_run):
        """测试 CLI 可用性检查"""
        # 模拟 CLI 可用
        mock_run.return_value.returncode = 0
        self.assertTrue(self.executor._cli_available())
        
        # 模拟 CLI 不可用
        mock_run.return_value.returncode = 1
        self.assertFalse(self.executor._cli_available())
        
        # 模拟异常
        mock_run.side_effect = Exception("Command not found")
        self.assertFalse(self.executor._cli_available())
    
    @patch('requests.get')
    def test_qwen_api_availability_check(self, mock_get):
        """测试 API 可用性检查"""
        # 没有配置 API
        self.assertFalse(self.executor._api_available())
        
        # 配置了 API
        executor = QwenExecutor({
            'api_endpoint': 'https://test.com',
            'api_key': 'test-key'
        })
        
        # API 可用
        mock_get.return_value.status_code = 200
        self.assertTrue(executor._api_available())
        
        # API 不可用
        mock_get.return_value.status_code = 500
        self.assertFalse(executor._api_available())
        
        # 网络异常
        mock_get.side_effect = Exception("Network error")
        self.assertFalse(executor._api_available())


class TestTaskScheduler(unittest.TestCase):
    """测试任务调度器"""
    
    def test_scheduler_with_working_executors(self):
        """测试调度器与可用的执行器"""
        # 创建模拟执行器
        mock_executor1 = Mock()
        mock_executor1.can_handle.return_value = True
        mock_executor1.health_check.return_value = True
        mock_executor1.execute.return_value = ExecutionResult(
            success=True, output="执行器1的结果", executor="mock1"
        )
        
        scheduler = TaskScheduler([mock_executor1])
        task = Task("测试任务")
        
        result = scheduler.route_task(task)
        
        self.assertTrue(result.success)
        self.assertEqual(result.executor, "mock1")
        mock_executor1.can_handle.assert_called_once_with(task)
        mock_executor1.execute.assert_called_once_with(task)
    
    def test_scheduler_fallback_mechanism(self):
        """测试调度器回退机制"""
        # 创建失败的执行器和成功的执行器
        failing_executor = Mock()
        failing_executor.can_handle.return_value = True
        failing_executor.health_check.return_value = False  # 健康检查失败
        
        working_executor = Mock()
        working_executor.can_handle.return_value = True
        working_executor.health_check.return_value = True
        working_executor.execute.return_value = ExecutionResult(
            success=True, output="回退执行器的结果", executor="fallback"
        )
        
        scheduler = TaskScheduler([failing_executor, working_executor])
        task = Task("测试任务")
        
        result = scheduler.route_task(task)
        
        self.assertTrue(result.success)
        self.assertEqual(result.executor, "fallback")
        # 失败的执行器不应该被调用
        failing_executor.execute.assert_not_called()
    
    def test_scheduler_statistics(self):
        """测试调度器统计功能"""
        scheduler = TaskScheduler([ClaudeExecutor()])
        
        # 处理几个任务
        for i in range(3):
            task = Task(f"任务 {i}")
            scheduler.route_task(task)
        
        # 检查统计
        self.assertEqual(scheduler.stats["total_tasks"], 3)
        self.assertEqual(scheduler.stats["claude_fallback"], 3)
        
        # 检查状态报告
        report = scheduler.get_status_report()
        self.assertIn("Total tasks processed: 3", report)


class TestBackwardCompatibility(unittest.TestCase):
    """测试向后兼容性"""
    
    def test_process_user_request_basic(self):
        """测试基础的用户请求处理"""
        result = process_user_request("测试请求")
        
        # 应该返回字符串结果
        self.assertIsInstance(result, str)
        self.assertGreater(len(result), 0)
    
    def test_process_user_request_with_context(self):
        """测试带上下文的用户请求处理"""
        # 创建临时文件
        test_file = "test_context.txt"
        with open(test_file, 'w') as f:
            f.write("上下文内容")
        
        try:
            result = process_user_request("分析这个文件", [test_file])
            
            self.assertIsInstance(result, str)
            self.assertGreater(len(result), 0)
        finally:
            if os.path.exists(test_file):
                os.remove(test_file)
    
    def test_process_user_request_without_qwen(self):
        """测试在没有 Qwen 的情况下处理请求"""
        with patch.dict(os.environ, {'ENABLE_QWEN_INTEGRATION': 'false'}):
            result = process_user_request("测试请求")
            
            # 应该仍然能处理请求（通过 Claude）
            self.assertIsInstance(result, str)
            self.assertGreater(len(result), 0)


class TestErrorHandling(unittest.TestCase):
    """测试错误处理"""
    
    def test_scheduler_handles_executor_exceptions(self):
        """测试调度器处理执行器异常"""
        # 创建会抛异常的执行器
        failing_executor = Mock()
        failing_executor.can_handle.return_value = True
        failing_executor.health_check.return_value = True
        failing_executor.execute.side_effect = Exception("执行器异常")
        
        # 创建正常的执行器作为回退
        working_executor = ClaudeExecutor()
        
        scheduler = TaskScheduler([failing_executor, working_executor])
        task = Task("测试任务")
        
        result = scheduler.route_task(task)
        
        # 应该成功回退到 Claude
        self.assertTrue(result.success)
        self.assertEqual(result.executor, "claude")
    
    def test_qwen_executor_handles_cli_timeout(self):
        """测试 Qwen 执行器处理 CLI 超时"""
        with patch('subprocess.run') as mock_run:
            import subprocess
            mock_run.side_effect = subprocess.TimeoutExpired("qwen-code", 300)
            
            executor = QwenExecutor()
            task = Task("测试任务")
            
            result = executor._execute_cli(task)
            
            self.assertFalse(result.success)
            self.assertIn("timeout", result.output.lower())


def run_tests():
    """运行所有测试"""
    print("🧪 运行 Qwen Code Subagent 集成测试...")
    print("=" * 50)
    
    # 创建测试套件
    suite = unittest.TestLoader().loadTestsFromModule(sys.modules[__name__])
    
    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # 显示结果摘要
    print("\n" + "=" * 50)
    print(f"测试运行完成!")
    print(f"总计: {result.testsRun} 个测试")
    print(f"成功: {result.testsRun - len(result.failures) - len(result.errors)} 个")
    print(f"失败: {len(result.failures)} 个")
    print(f"错误: {len(result.errors)} 个")
    
    if result.failures:
        print("\n失败的测试:")
        for test, error in result.failures:
            print(f"  - {test}: {error}")
    
    if result.errors:
        print("\n错误的测试:")
        for test, error in result.errors:
            print(f"  - {test}: {error}")
    
    # 返回是否所有测试都通过
    return len(result.failures) == 0 and len(result.errors) == 0


if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)