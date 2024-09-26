#!/bin/sh

file_names=(
name001
name002
name003
)

# ディレクトリに移動
cd "$dir_path"

# ファイルを作成するループ
for name in "${file_names[@]}"; do
  touch "$name.md"
done