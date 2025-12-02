#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(dirname "$(realpath -e $0)")
EXAMPLE_DIR="$SCRIPT_DIR/.."
cd "$SCRIPT_DIR"

python3 -m venv venv
source venv/bin/activate
pip install -r ./requirements.txt > /dev/null

cd "$EXAMPLE_DIR"
for example in *; do
  [ -d "$example" ] || continue
  [ "$example" == "$(basename "$SCRIPT_DIR")" ] && continue
  cd "$EXAMPLE_DIR/$example"
  "$SCRIPT_DIR/gen_plot.py"
  cd ..
done
