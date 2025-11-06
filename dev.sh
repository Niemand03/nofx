#!/bin/bash

SESSION="nofx"
BACKEND_WINDOW="backend"
FRONTEND_WINDOW="frontend"
ROOT_DIR="/root/nofx"

# 检查tmux是否安装
if ! command -v tmux &> /dev/null; then
    echo "❌ tmux未安装，请先安装: apt-get install tmux"
    exit 1
fi

# 启动服务
start() {
    cd "$ROOT_DIR"
    
    # 检查是否已存在会话
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "⚠️ 会话已存在"
        exit 1
    fi
    
    # 创建新会话（后台窗口）
    tmux new-session -d -s "$SESSION" -n "$BACKEND_WINDOW"
    
    # 启动后端
    tmux send-keys -t "$SESSION:$BACKEND_WINDOW" "cd $ROOT_DIR && lsof -t -i :8080 | xargs -r kill -9 2>/dev/null; go build -o nofx && ./nofx" C-m
    
    # 创建前端窗口
    tmux new-window -t "$SESSION" -n "$FRONTEND_WINDOW"
    tmux send-keys -t "$SESSION:$FRONTEND_WINDOW" "cd $ROOT_DIR/web && lsof -t -i :3000 | xargs -r kill -9 2>/dev/null; [ ! -d node_modules ] && npm install --silent || true; npm run dev" C-m
    
    # 切换到后端窗口
    tmux select-window -t "$SESSION:$BACKEND_WINDOW"
    
    echo "✅ 已启动"
}

# 停止服务
stop() {
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "⚠️  会话不存在"
        exit 1
    fi
    
    # 清理端口
    lsof -t -i :8080 | xargs -r kill -9 2>/dev/null || true
    lsof -t -i :3000 | xargs -r kill -9 2>/dev/null || true
    
    # 停止tmux会话
    tmux kill-session -t "$SESSION" 2>/dev/null || true
    
    echo "✅ 服务已停止"
}

# 查看日志
attach() {
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "⚠️  会话不存在，使用: ./dev.sh start"
        exit 1
    fi
    tmux attach -t "$SESSION"
}

# 重启服务
restart() {
    stop
    sleep 1
    start
}

# 主函数
case "${1:-start}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    attach|log|logs)
        attach
        ;;
    *)
        echo "用法: ./dev.sh [start|stop|restart|attach]"
        exit 1
        ;;
esac

