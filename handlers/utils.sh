#!/usr/bin/env bash
tmpdir="${1:?tmpdir is required}"

INDENT=0
INDENT_STEP=2
indent() {
  local n="$1"
  shift
  printf "%*s%s\n" "$n" "" "$*"
}
y() {
  printf "%*s%s\n" "$INDENT" "" "$*"
}

push() {
  ((INDENT += INDENT_STEP))
}

pop() {
  ((INDENT -= INDENT_STEP))
  ((INDENT < 0)) && INDENT=0
}

reset_indent() {
  INDENT=0
}

if [ -n "$2" ]; then
  y "\"$2\":"
  push
fi
