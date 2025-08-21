#!/bin/bash

# Git Worktree 管理脚本
# 基于最佳实践，优先使用worktree而非checkout

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[WORKTREE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Git仓库
check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "当前目录不是Git仓库"
        exit 1
    fi
}

# 列出所有worktree
list_worktrees() {
    log_info "当前所有 worktree:"
    git worktree list
    echo ""
    
    # 统计信息
    local total=$(git worktree list | wc -l)
    local main_repo=$(git worktree list | head -1 | awk '{print $1}')
    log_info "总计: $total 个工作树"
    log_info "主仓库: $main_repo"
}

# 创建新功能分支worktree
create_feature_worktree() {
    local feature_name="$1"
    
    if [ -z "$feature_name" ]; then
        echo -n "输入功能分支名 (例: feature/user-auth, fix/login-bug): "
        read -r feature_name
    fi
    
    if [ -z "$feature_name" ]; then
        log_error "分支名不能为空"
        return 1
    fi
    
    # 清理分支名
    feature_name=$(echo "$feature_name" | sed 's/[^a-zA-Z0-9/_-]//g')
    
    # 生成worktree目录名
    local repo_name=$(basename "$(git rev-parse --show-toplevel)")
    local wt_dir="../$repo_name-$feature_name"
    
    # 检查目录是否已存在
    if [ -d "$wt_dir" ]; then
        log_error "目录已存在: $wt_dir"
        return 1
    fi
    
    # 检查分支是否已存在
    if git show-ref --verify --quiet refs/heads/$feature_name; then
        log_warning "分支 $feature_name 已存在，将创建worktree指向现有分支"
        git worktree add "$wt_dir" "$feature_name"
    else
        # 询问基于哪个分支创建
        echo "基于哪个分支创建? (默认: main/master)"
        echo "1) main"
        echo "2) master" 
        echo "3) develop"
        echo "4) 当前分支 ($(git branch --show-current))"
        echo "5) 自定义"
        echo -n "选择 [1-5]: "
        read -r base_choice
        
        local base_branch=""
        case $base_choice in
            1) base_branch="main" ;;
            2) base_branch="master" ;;
            3) base_branch="develop" ;;
            4) base_branch=$(git branch --show-current) ;;
            5) 
                echo -n "输入基础分支名: "
                read -r base_branch
                ;;
            *) 
                # 自动检测主分支
                if git show-ref --verify --quiet refs/heads/main; then
                    base_branch="main"
                elif git show-ref --verify --quiet refs/heads/master; then
                    base_branch="master"
                else
                    base_branch=$(git branch --show-current)
                fi
                ;;
        esac
        
        log_info "基于 $base_branch 创建新分支 $feature_name"
        git worktree add -b "$feature_name" "$wt_dir" "$base_branch"
    fi
    
    log_success "Worktree 创建成功!"
    echo "路径: $wt_dir"
    echo "分支: $feature_name"
    echo ""
    echo "进入新worktree:"
    echo "  cd $wt_dir"
    echo ""
    echo "在VSCode中打开:"
    echo "  code $wt_dir"
}

# 删除worktree
remove_worktree() {
    local wt_path="$1"
    
    if [ -z "$wt_path" ]; then
        echo ""
        list_worktrees
        echo -n "输入要删除的worktree路径: "
        read -r wt_path
    fi
    
    if [ -z "$wt_path" ]; then
        log_error "路径不能为空"
        return 1
    fi
    
    if [ ! -d "$wt_path" ]; then
        log_error "路径不存在: $wt_path"
        return 1
    fi
    
    # 确认删除
    echo -e "${YELLOW}⚠️  即将删除 worktree: $wt_path${NC}"
    echo -n "确认删除? (y/N): "
    read -r confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        git worktree remove "$wt_path"
        log_success "Worktree 已删除: $wt_path"
        
        # 询问是否删除分支
        echo -n "是否同时删除对应的分支? (y/N): "
        read -r delete_branch
        
        if [ "$delete_branch" = "y" ] || [ "$delete_branch" = "Y" ]; then
            # 提取分支名（简单方式）
            local branch_name=$(basename "$wt_path" | sed "s/$(basename "$(git rev-parse --show-toplevel)")-//")
            if git show-ref --verify --quiet refs/heads/$branch_name; then
                git branch -D "$branch_name"
                log_success "分支已删除: $branch_name"
            fi
        fi
    else
        log_info "取消删除"
    fi
}

# 清理孤立的worktree
cleanup_worktrees() {
    log_info "清理孤立的worktree..."
    git worktree prune
    log_success "清理完成"
}

# 切换到worktree
switch_to_worktree() {
    echo ""
    list_worktrees
    echo -n "输入worktree路径 (或输入数字选择): "
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        # 数字选择
        local wt_path=$(git worktree list | sed -n "${selection}p" | awk '{print $1}')
    else
        # 直接路径
        local wt_path="$selection"
    fi
    
    if [ -z "$wt_path" ] || [ ! -d "$wt_path" ]; then
        log_error "无效的worktree路径"
        return 1
    fi
    
    log_info "切换到 worktree: $wt_path"
    
    if command -v code >/dev/null 2>&1; then
        echo "在VSCode中打开: code $wt_path"
        code "$wt_path"
    fi
    
    echo "手动切换命令: cd $wt_path"
}

# 显示帮助
show_help() {
    echo "Git Worktree 管理工具"
    echo ""
    echo "用法:"
    echo "  $0 list                    列出所有worktree"
    echo "  $0 create [branch-name]    创建新功能分支worktree"
    echo "  $0 remove [path]           删除worktree"
    echo "  $0 switch                  切换到worktree"
    echo "  $0 cleanup                 清理孤立的worktree"
    echo "  $0 help                    显示此帮助"
    echo ""
    echo "推荐工作流:"
    echo "  1. 创建功能分支: $0 create feature/new-api"
    echo "  2. 在新worktree中开发"
    echo "  3. 完成后合并到主分支"
    echo "  4. 删除worktree: $0 remove"
    echo ""
    echo "优势:"
    echo "  - 避免频繁的git checkout"
    echo "  - 多个功能并行开发"
    echo "  - 保持各分支的工作状态"
}

# 主函数
main() {
    case "${1:-help}" in
        list|ls)
            check_git_repo
            list_worktrees
            ;;
        create|new)
            check_git_repo
            create_feature_worktree "$2"
            ;;
        remove|rm|delete)
            check_git_repo
            remove_worktree "$2"
            ;;
        switch|sw)
            check_git_repo
            switch_to_worktree
            ;;
        cleanup|clean)
            check_git_repo
            cleanup_worktrees
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}未知命令: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"