#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source ${SCRIPT_DIR}/mindmap/.venv/bin/activate
cat | python3 ${SCRIPT_DIR}/mindmap/mindmap.py ${tmpdir}
