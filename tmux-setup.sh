#!/bin/sh

PWD=$(pwd)
SESSION=$(basename "$PWD")

tmux new-session -s "$SESSION" -d
tmux send-keys -t "$SESSION":0.0 'npx zenn preview' C-m

# initial window for client generate
tmux split-window -v -t "$SESSION" 
tmux send-keys -t "$SESSION":0.1 'code .' C-m

# Set the even-vertical layout 
tmux send-keys -t "$SESSION" M-2

tmux attach -t "$SESSION"
