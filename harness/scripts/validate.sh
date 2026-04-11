#!/bin/bash
# Blueprint Harness 企业级校验脚本 (Bash v1.6)
# 环境锁定：Java 17 + Maven + dc-framework

PASS=true

# 辅助函数：输出颜色
function echo_green() { echo -e "\033[32m$1\033[0m"; }
function echo_red() { echo -e "\033[31m$1\033[0m"; }
function echo_yellow() { echo -e "\033[33m$1\033[0m"; }

echo "--------------------------------------------------------"
echo "🚀 启动 Blueprint Harness 企业级验证程序 (dc-framework)..."
echo "--------------------------------------------------------"

# ═══════════════════════════════════════
# Probe 0: 环境锁死校验 (Maven/Java Lock)
# ═══════════════════════════════════════
echo "🔍 [Probe 0] 检查项目环境合法性 (Java/Maven/BOM)..."
if [ ! -f "pom.xml" ]; then
  echo_red "  ❌ CRITICAL FAIL: 未发现 pom.xml。本系统严格锁定 Java/Maven 环境。"
  exit 1
else
  if ! grep -qE "com\.dc\.framework|dc-dependencies|com\.dc\.biz" "pom.xml"; then
    echo_red "  ❌ FAIL: pom.xml 缺少核心依赖 (com.dc.framework 或 com.dc.biz)。"
    PASS=false
  else
    echo_green "  ✅ 环境与 BOM 校验通过。"
  fi
fi

# ═══════════════════════════════════════
# Probe 1: @blueprint-ref 精确锚点校验
# ═══════════════════════════════════════
echo ""
echo "🔍 [Probe 1] 检查代码变更中的业务锚点引用 (@blueprint-ref)..."
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(java|kt)$')

if [ -n "$STAGED_FILES" ]; then
  for file in $STAGED_FILES; do
    if ! grep -qE "@blueprint-ref:.*(DOMAIN_MODEL|BUSINESS_PROCESS|TECH_STACK|BR-[0-9]+|Anchor-)" "$file"; then
      echo_red "  ❌ FAIL: $file 缺少有效的业务锚点引用。"
      PASS=false
    else
      echo_green "  ✅ $file: 校验通过。"
    fi
  done
else
  echo_yellow "  ⏭️  暂存区无新增代码文件，跳过 Probe 1。"
fi

echo ""

# ═══════════════════════════════════════
# Probe 2: 蓝图核心文档完整性校验
# ═══════════════════════════════════════
echo "🔍 [Probe 2] 检查核心规格文档 (Specs) 完整性..."
REQUIRED_DOCS=(
  "harness/spec/DOMAIN_MODEL.md"
  "harness/spec/BUSINESS_PROCESS.md"
  "harness/spec/PRODUCT_SENSE.md"
  "harness/spec/ARCHITECTURE.md"
  "harness/spec/VERIFY.md"
  "harness/spec/TECH_STACK.md"
  "harness/workflow.md"
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
# Probe 3: 活跃任务的防呆双问检查
# ═══════════════════════════════════════
echo "🔍 [Probe 3] 检查待闭环任务的收尾反思..."
ACTIVE_TASKS=$(ls harness/tasks/active/*.md 2>/dev/null | grep -v "_TEMPLATE.md")

if [ -n "$ACTIVE_TASKS" ]; then
  for task in $ACTIVE_TASKS; do
    # 匹配标题，对空格不敏感
    if ! grep -qE "##\s+5\.\s+🧘\s+收尾反思" "$task"; then
      echo_red "  ❌ FAIL: 任务 $task 损坏，缺少“收尾反思”章节。"
      PASS=false
    else
      # 深度检查：检测是否保留了模板中的提示文字（即未填）
      Q1_UNFILLED=$(grep -E "###\s+Q1:" "$task" -A 5 | grep "\[回答")
      Q2_UNFILLED=$(grep -E "###\s+Q2:" "$task" -A 5 | grep "\[回答")
      if [ -n "$Q1_UNFILLED" ] || [ -n "$Q2_UNFILLED" ]; then
        echo_yellow "  ⚠️  WARN: $task 的 Q1 或 Q2 尚未填写（保留了模板占位符），归档前必须回答。"
      else
        echo_green "  ✅ $task: 收尾反思已填写。"
      fi
    fi
  done
else
  echo_yellow "  ⏭️  无活跃任务记录，跳过 Probe 3。"
fi

echo ""

# ═══════════════════════════════════════
# Probe 4: Spring Java Format 自愈逻辑
# ═══════════════════════════════════════
echo "🔍 [Probe 4] 检查代码格式与依赖规范 (Self-Healing)..."
if command -v mvn &> /dev/null; then
  echo "  正在执行 mvn spring-javaformat:validate..."
  if ! mvn spring-javaformat:validate -DskipTests &> /dev/null; then
    echo_yellow "  ⚠️  检测到格式违规，正在尝试自动修复 (mvn spring-javaformat:apply)..."
    mvn spring-javaformat:apply -DskipTests &> /dev/null
    echo_green "  ✅ 格式自动修复完成。请在 git commit 前重新 Add 这些变更。"
  else
    echo_green "  ✅ 代码格式校验通过。"
  fi
else
  echo_yellow "  ⚠️  未安装 mvn，跳过 Probe 4。"
fi

# ═══════════════════════════════════════
# 最终判定
# ═══════════════════════════════════════
echo ""
echo "--------------------------------------------------------"
if [ "$PASS" = true ]; then
  echo_green "✅ ALL PROBES PASSED! 已对齐 dc-framework 企业级标准。"
  echo "--------------------------------------------------------"
  exit 0
else
  echo_red "❌ VALIDATION FAILED! 请修复上述业务一致性问题。"
  echo "--------------------------------------------------------"
  exit 1
fi
