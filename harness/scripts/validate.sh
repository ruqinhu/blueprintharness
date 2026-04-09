#!/bin/bash
# Blueprint Harness — 机械化验证脚本
# 用途：在任务声明完成前强制运行，拦截不合规的代码变更。

PASS=true

# 辅助函数：输出颜色
function echo_green() { echo -e "\033[32m$1\033[0m"; }
function echo_red() { echo -e "\033[31m$1\033[0m"; }
function echo_yellow() { echo -e "\033[33m$1\033[0m"; }

echo "--------------------------------------------------------"
echo "🚀 启动 Blueprint Harness 机械化验证程序..."
echo "--------------------------------------------------------"

# ═══════════════════════════════════════
# Probe 1: @blueprint-ref 精确锚点校验
# ═══════════════════════════════════════
echo "🔍 [Probe 1] 检查代码变更中的业务锚点引用 (@blueprint-ref)..."

# 获取暂存区(staged)的代码文件
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(java|kt|py|ts|js|go|cpp|cs)$')

if [ -n "$STAGED_FILES" ]; then
  for file in $STAGED_FILES; do
    # 深度匹配：必须包含 DOMAIN_MODEL/BUSINESS_PROCESS 或 BR-xxx 编号或 Anchor-锚点
    if ! grep -qE "@blueprint-ref:.*(DOMAIN_MODEL|BUSINESS_PROCESS|BR-[0-9]+|Anchor-|Node-)" "$file"; then
      echo_red "  ❌ FAIL: $file 缺少有效的业务锚点引用。"
      echo "     提示：引用格式需为 // @blueprint-ref: [文档名/规则ID/锚点ID] [简述]"
      PASS=false
    else
      echo_green "  ✅ $file: 业务锚点校验通过。"
    fi
  done
else
  echo_yellow "  ⏭️  暂存区无新增代码文件，跳过 Probe 1。"
fi

echo ""

# ═══════════════════════════════════════
# Probe 2: 蓝图核心文档完整性校验
# ═══════════════════════════════════════
echo "🔍 [Probe 2] 检查蓝图核心文档完整性..."

REQUIRED_DOCS=(
  "harness/docs/DOMAIN_MODEL.md"
  "harness/docs/BUSINESS_PROCESS.md"
  "harness/docs/PRODUCT_SENSE.md"
  "harness/docs/ARCHITECTURE.md"
  "harness/docs/VERIFY.md"
)

for doc in "${REQUIRED_DOCS[@]}"; do
  if [ ! -f "$doc" ]; then
    echo_red "  ❌ FAIL: 缺少核心文档 $doc"
    PASS=false
  else
    echo_green "  ✅ $doc"
  fi
done

echo ""

# ═══════════════════════════════════════
# Probe 3: 活跃任务收尾反思校验
# ═══════════════════════════════════════
echo "🔍 [Probe 3] 检查待闭环任务的收尾反思..."

ACTIVE_TASKS=$(ls harness/plans/tasks/active/*.md 2>/dev/null | grep -v "_TEMPLATE.md")

if [ -n "$ACTIVE_TASKS" ]; then
  for task in $ACTIVE_TASKS; do
    if ! grep -q "## 5. 🧘 收尾反思" "$task"; then
      echo_red "  ❌ FAIL: 任务 $task 损坏，缺少“收尾反思”章节。"
      PASS=false
    elif grep -A 5 "## 5. 🧘 收尾反思" "$task" | grep -q "\[待填写\]"; then
      echo_yellow "  ⚠️  WARN: $task 包含未填写的“收尾反思”，在归档前必须完成回答。"
    else
      echo_green "  ✅ $task: 收尾反思已就绪。"
    fi
  done
else
  echo_yellow "  ⏭️  无活跃任务记录，跳过 Probe 3。"
fi

# ═══════════════════════════════════════
# 最终判定
# ═══════════════════════════════════════
echo "--------------------------------------------------------"
if [ "$PASS" = true ]; then
  echo_green "✅ ALL PROBES PASSED! 业务一致性已达成门禁准入。"
  echo "--------------------------------------------------------"
  exit 0
else
  echo_red "❌ VALIDATION FAILED! 请根据上述错误信息修复蓝图一致性问题。"
  echo "--------------------------------------------------------"
  exit 1
fi
