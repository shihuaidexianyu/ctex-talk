#!/usr/bin/env bash
set -euo pipefail

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$HERE"
BUILD=$(mktemp -d "${TMPDIR:-/tmp}/ctex-talk.XXXXXX")

# 占位图没有中文、交叉引用或页码，只需一遍。
if ! latex -interaction=nonstopmode -halt-on-error -output-directory="$BUILD" figures/placeholder.tex >"$BUILD/placeholder.log" 2>&1; then
  printf '占位图构建失败；构建目录保留在 %s\n' "$BUILD"
  exit 1
fi
if ! dvipdfmx -o figures/placeholder.pdf "$BUILD/placeholder.dvi" >>"$BUILD/placeholder.log" 2>&1; then
  printf '占位图 PDF 转换失败；构建目录保留在 %s\n' "$BUILD"
  exit 1
fi

# 当前工具链：DVI LaTeX + dvipdfmx；OSFONTDIR 让 ctex 找到 Noto CJK。
for PASS in 1 2; do
  if ! OSFONTDIR=/usr/share/fonts// latex -interaction=nonstopmode -halt-on-error -output-directory="$BUILD" template.tex >"$BUILD/template-$PASS.log" 2>&1; then
    printf 'template.tex：LaTeX 第 %s 遍失败；构建目录保留在 %s\n' "$PASS" "$BUILD"
    exit 1
  fi
done
if ! OSFONTDIR=/usr/share/fonts// dvipdfmx -o template.pdf "$BUILD/template.dvi" >"$BUILD/template-dvipdfmx.log" 2>&1; then
  printf 'template.tex：dvipdfmx 失败；构建目录保留在 %s\n' "$BUILD"
  exit 1
fi

rm -rf "$BUILD"
printf '已生成 %s/template.pdf（固定填空模板）\n' "$HERE"
pdfinfo template.pdf | grep -E '^(Pages|Page size|File size):'
