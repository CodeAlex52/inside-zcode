#!/usr/bin/env bash
# scan-local-traces.sh — ZCode 本地痕迹只读自查（不删除、不修改任何文件）
#
# 用途：审计本机是否存在 ZCode 的检查点/快照痕迹（配合 README 第六章自保清单使用）。
# 用法：
#   ./scripts/scan-local-traces.sh            # 默认扫描 ~/.zcode
#   ./scripts/scan-local-traces.sh /path/to/.zcode
#
# 退出码：0 = 发现痕迹（需要关注）；1 = 未发现或目录不存在；2 = 用法错误。
set -u

ROOT="${1:-$HOME/.zcode}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,9p' "$0"
  exit 0
fi

if [[ ! -d "$ROOT" ]]; then
  echo "[i] 未发现 $ROOT —— 本机或其用户目录下没有 ZCode 痕迹目录。"
  echo "    （Windows 检查：%LOCALAPPDATA%\\Programs\\ZCode 与用户目录下的 .zcode）"
  exit 1
fi

echo "== ZCode 本地痕迹只读自查 =="
echo "目标目录: $ROOT"
echo

echo "==> 1. 目录总体积（顶层）"
du -sh "$ROOT" 2>/dev/null || echo "    (du 失败，权限或路径异常)"

CKPT="$ROOT/v2/checkpoints"
if [[ -d "$CKPT" ]]; then
  echo
  echo "==> 2. checkpoints 目录体积"
  du -sh "$CKPT" 2>/dev/null || true
  echo
  echo "==> 3. 最大的 10 个文件"
  find "$CKPT" -type f -exec du -k {} + 2>/dev/null \
    | sort -rn | head -10 \
    | awk '{ printf "    %8.1f MB  %s\n", $1/1024, $2 }'
  echo
  echo "==> 4. 加密包 (.enc) 统计"
  ENC_COUNT=$(find "$CKPT" -type f -name "*.enc" 2>/dev/null | wc -l | tr -d ' ')
  echo "    .enc 文件数量: $ENC_COUNT"
  if [[ "$ENC_COUNT" -gt 0 ]]; then
    echo "    提醒: 快照类密文本地无法解密；是否删除请先保留证据、再做决策。"
    FINDINGS=1
  else
    FINDINGS=0
  fi
else
  echo
  echo "[i] 没有 $CKPT 目录。"
  FINDINGS=0
fi

echo
echo "== 后续建议（详见 README 第六章） =="
echo "  1) 先保留证据（不要直接 rm），记录体积与版本；"
echo "  2) 轮换云凭证与仓库密钥（如曾在该工作区开过 Agent）；"
echo "  3) 检查 .gitignore 是否覆盖 .env / *credential* / *password* / LFS 缓存；"
echo "  4) 反馈影响面可到本仓库 Issue 贴出脱敏后的体积与版本。"

if [[ "${FINDINGS:-0}" == "1" ]]; then
  echo
  echo "[!] 发现痕迹。请按上述建议处理。"
fi
exit 0
