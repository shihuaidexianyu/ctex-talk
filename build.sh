#!/usr/bin/env bash
set -euo pipefail

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$HERE"
BUILD=$(mktemp -d "${TMPDIR:-/tmp}/ctex-talk.XXXXXX")

# 占位图没有交叉引用或页码，只需一遍。
if ! latex -interaction=nonstopmode -halt-on-error -output-directory="$BUILD" figures/placeholder.tex >"$BUILD/placeholder.log" 2>&1; then
  printf '占位图构建失败；构建目录保留在 %s\n' "$BUILD"
  exit 1
fi
if ! dvipdfmx -o figures/placeholder.pdf "$BUILD/placeholder.dvi" >>"$BUILD/placeholder.log" 2>&1; then
  printf '占位图 PDF 转换失败；构建目录保留在 %s\n' "$BUILD"
  exit 1
fi

build_one() {
  local STEM=$1
  for PASS in 1 2; do
    if ! latex -interaction=nonstopmode -halt-on-error -output-directory="$BUILD" "$STEM.tex" >"$BUILD/$STEM-$PASS.log" 2>&1; then
      printf '%s：LaTeX 第 %s 遍失败；构建目录保留在 %s\n' "$STEM" "$PASS" "$BUILD"
      exit 1
    fi
  done
  if ! dvipdfmx -o "$STEM.pdf" "$BUILD/$STEM.dvi" >"$BUILD/$STEM-dvipdfmx.log" 2>&1; then
    printf '%s：dvipdfmx 失败；构建目录保留在 %s\n' "$STEM" "$BUILD"
    exit 1
  fi
  if grep -E 'Overfull|There were undefined references' "$BUILD/$STEM-2.log"; then
    printf '%s：存在版面溢出或未解析引用；构建目录保留在 %s\n' "$STEM" "$BUILD"
    exit 1
  fi
  printf '已生成 %s/%s.pdf\n' "$HERE" "$STEM"
  pdfinfo "$STEM.pdf" | grep -E '^(Pages|Page size|File size):'
}

if [ "$#" -gt 0 ]; then
  STEMS=("$@")
else
  STEMS=(template short layouts)
fi

for STEM in "${STEMS[@]}"; do
  build_one "${STEM%.tex}"
done

rm -rf "$BUILD"
