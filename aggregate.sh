#!/bin/sh

cd "$(dirname "$0")" || exit 
cd ../ || exit # cd to the git repository root

AGGREGATED=$(find steps/* -print0 | \
  xargs -0 cat | \
  grep -v '#!/bin/sh' | \
  grep -v '# REMOVE THIS' | \
  sed 's/^\#\s//') 

# copy README.md to the clipboard
if which clip.exe 1>/dev/null # WSL
then
  echo "$AGGREGATED" | clip.exe 
elif which pbcopy 1>/dev/null # Mac
then
  echo "$AGGREGATED" | pbcopy
elif which xsel 1>/dev/null # Debian/Ubuntu Linux
then
  # WSL gives error on xsel as "xsel: Can't open display: (null)" so, using clip.exe on WSL
  echo "$AGGREGATED" | xsel --clipboard --input
fi