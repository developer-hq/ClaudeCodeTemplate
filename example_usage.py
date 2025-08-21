#!/usr/bin/env python3
"""
Qwen Code Subagent 使用示例
演示智能路由和回退机制
"""

import os
import sys
from pathlib import Path

# 添加当前目录到 Python 路径
sys.path.insert(0, str(Path(__file__).parent))

from qwen_subagent import (
    Task, TaskScheduler, QwenExecutor, ClaudeExecutor, 
    process_user_request
)


def demo_basic_usage():
    """基础使用演示"""
    print("=== 基础使用演示 ===")
    
    # 1. 简单调用（向后兼容的 API）
    print("1. 简单任务（会自动路由到合适的执行器）")
    result = process_user_request("帮我写一个 Hello World 函数")
    print(f"结果: {result[:100]}...")
    print()
    
    # 2. 带上下文文件的调用
    print("2. 带上下文文件的任务")
    context_files = ["qwen_subagent.py"]  # 当前文件作为上下文
    result = process_user_request("分析这个 Python 文件的结构", context_files)
    print(f"结果: {result[:100]}...")
    print()


def demo_task_routing():
    """任务路由演示"""
    print("=== 任务路由演示 ===")
    
    # 创建调度器
    scheduler = TaskScheduler()
    
    # 测试不同类型的任务
    test_tasks = [
        # 适合 Qwen 的任务
        Task("批量格式化所有 Python 文件", ["file1.py", "file2.py"], 25000),
        Task("生成项目文档", [], 5000, {"type": "documentation"}),
        Task("翻译这些注释到中文", [], 3000),
        
        # 适合 Claude 的任务  
        Task("设计一个新的架构方案", [], 2000),
        Task("调试这个复杂的算法", [], 1500),
        Task("优化性能瓶颈", [], 1000),
    ]
    
    for i, task in enumerate(test_tasks, 1):
        print(f"{i}. 任务: {task.content[:50]}...")
        result = scheduler.route_task(task)
        print(f"   路由到: {result.executor}")
        print(f"   成功: {'✅' if result.success else '❌'}")
        print()
    
    # 显示统计信息
    print("路由统计:")
    print(scheduler.get_status_report())


def demo_fallback_mechanism():
    """回退机制演示"""
    print("=== 回退机制演示 ===")
    
    # 模拟 Qwen 不可用的情况
    print("1. 模拟 Qwen 服务不可用...")
    
    # 创建一个 Qwen 不可用的执行器
    class UnavailableQwenExecutor:
        def can_handle(self, task):
            return True  # 声称可以处理
        
        def health_check(self):
            return False  # 但健康检查失败
        
        def execute(self, task):
            return None  # 不会被调用
    
    # 使用不可用的 Qwen + 可用的 Claude
    scheduler = TaskScheduler([UnavailableQwenExecutor(), ClaudeExecutor()])
    
    task = Task("这个任务应该回退到 Claude", [], 5000)
    result = scheduler.route_task(task)
    
    print(f"结果: 任务被路由到 {result.executor}")
    print(f"成功执行: {'✅' if result.success else '❌'}")
    print()


def demo_configuration():
    """配置演示"""
    print("=== 配置演示 ===")
    
    # 显示当前配置
    print("1. 环境变量:")
    print(f"   ENABLE_QWEN_INTEGRATION: {os.getenv('ENABLE_QWEN_INTEGRATION', 'not set')}")
    print()
    
    # 显示 Qwen 执行器配置
    qwen = QwenExecutor()
    print("2. Qwen 执行器配置:")
    print(f"   CLI 路径: {qwen.cli_path}")
    print(f"   API 端点: {qwen.api_endpoint or 'Not configured'}")
    print(f"   超时时间: {qwen.timeout}s")
    print(f"   CLI 可用: {'✅' if qwen._cli_available() else '❌'}")
    print(f"   API 可用: {'✅' if qwen._api_available() else '❌'}")
    print()


def demo_advanced_features():
    """高级功能演示"""
    print("=== 高级功能演示 ===")
    
    # 1. Token 估算
    print("1. Token 估算:")
    large_content = "这是一个很长的内容 " * 1000  # 模拟大内容
    task = Task(large_content, ["file1.py", "file2.py"])
    print(f"   任务内容长度: {len(task.content)} 字符")
    print(f"   估算 token 数: {task.estimated_tokens}")
    print(f"   是否适合 Qwen: {QwenExecutor().can_handle(task)}")
    print()
    
    # 2. 任务元数据
    print("2. 任务元数据:")
    task_with_metadata = Task(
        "分析代码质量",
        ["qwen_subagent.py"],
        metadata={"priority": "high", "user": "developer"}
    )
    print(f"   元数据: {task_with_metadata.metadata}")
    print()


def interactive_demo():
    """交互式演示"""
    print("=== 交互式演示 ===")
    print("输入任务描述，系统将自动选择最佳执行器")
    print("输入 'quit' 退出")
    print()
    
    scheduler = TaskScheduler()
    
    while True:
        try:
            user_input = input("任务> ").strip()
            if user_input.lower() in ['quit', 'exit', 'q']:
                break
            
            if not user_input:
                continue
            
            # 处理任务
            task = Task(user_input)
            result = scheduler.route_task(task)
            
            print(f"路由到: {result.executor}")
            print(f"结果: {result.output[:200]}...")
            if len(result.output) > 200:
                print("   (输出已截断)")
            print()
            
        except KeyboardInterrupt:
            print("\n\n再见！")
            break
        except Exception as e:
            print(f"错误: {e}")


def main():
    """主函数"""
    print("🤖 Qwen Code Subagent 演示程序")
    print("=" * 50)
    print()
    
    # 运行各种演示
    try:
        demo_basic_usage()
        demo_task_routing()
        demo_fallback_mechanism()
        demo_configuration()
        demo_advanced_features()
        
        # 如果是交互模式
        if len(sys.argv) > 1 and sys.argv[1] == "--interactive":
            interactive_demo()
        
    except Exception as e:
        print(f"演示过程中出错: {e}")
        import traceback
        traceback.print_exc()
    
    print("演示完成！")


if __name__ == "__main__":
    main()