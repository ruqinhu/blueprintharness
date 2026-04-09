# Blueprint Harness — 机械化验证脚本 (PowerShell 版)
# 用途：在任务声明完成前强制运行，拦截不合规的代码变更。

$Pass = $true

Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "🚀 启动 Blueprint Harness 机械化验证程序 (PowerShell)..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

# ═══════════════════════════════════════
# Probe 1: @blueprint-ref 精确锚点校验
# ═══════════════════════════════════════
Write-Host "🔍 [Probe 1] 检查代码变更中的业务锚点引用 (@blueprint-ref)..."

# 获取暂存区(staged)的代码文件
$StagedFiles = git diff --cached --name-only --diff-filter=ACM | Select-String -Pattern "\.(java|kt|py|ts|js|go|cpp|cs)$"

if ($StagedFiles) {
    foreach ($File in $StagedFiles) {
        $FilePath = $File.ToString()
        # 深度匹配：必须包含 DOMAIN_MODEL/BUSINESS_PROCESS 或 BR-xxx 编号或 Anchor-锚点
        $Content = Get-Content $FilePath -Raw
        if ($Content -notmatch "@blueprint-ref:.*(DOMAIN_MODEL|BUSINESS_PROCESS|BR-[0-9]+|Anchor-|Node-)") {
            Write-Host "  ❌ FAIL: ${FilePath} 缺少有效的业务锚点引用。" -ForegroundColor Red
            Write-Host "     提示：引用格式需为 // @blueprint-ref: [文档名/规则ID/锚点ID] [简述]"
            $Pass = $false
        } else {
            Write-Host "  ✅ ${FilePath}: 业务锚点校验通过。" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  ⏭️  暂存区无新增代码文件，跳过 Probe 1。" -ForegroundColor Yellow
}

Write-Host ""

# ═══════════════════════════════════════
# Probe 2: 蓝图核心文档完整性校验
# ═══════════════════════════════════════
Write-Host "🔍 [Probe 2] 检查蓝图核心文档完整性..."

$RequiredDocs = @(
    "harness/docs/DOMAIN_MODEL.md",
    "harness/docs/BUSINESS_PROCESS.md",
    "harness/docs/PRODUCT_SENSE.md",
    "harness/docs/ARCHITECTURE.md",
    "harness/docs/VERIFY.md"
)

foreach ($Doc in $RequiredDocs) {
    if (-not (Test-Path $Doc)) {
        Write-Host "  ❌ FAIL: 缺少核心文档 $Doc" -ForegroundColor Red
        $Pass = $false
    } else {
        Write-Host "  ✅ $Doc" -ForegroundColor Green
    }
}

Write-Host ""

# ═══════════════════════════════════════
# Probe 3: 活跃任务收尾反思校验
# ═══════════════════════════════════════
Write-Host "🔍 [Probe 3] 检查待闭环任务的收尾反思..."

$ActiveTasks = Get-ChildItem "harness/plans/tasks/active/*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_TEMPLATE.md" }

if ($ActiveTasks) {
    foreach ($Task in $ActiveTasks) {
        $TaskContent = Get-Content $Task.FullName -Raw
        if ($TaskContent -notmatch "## 5. 🧘 收尾反思") {
            Write-Host "  ❌ FAIL: 任务 $($Task.Name) 损坏，缺少“收尾反思”章节。" -ForegroundColor Red
            $Pass = $false
        } else {
            # 深度检查：检测是否保留了模板中的提示文字（即未填）
            $Q1Unfilled = $TaskContent -match "### Q1:[\s\S]*?\[回答"
            $Q2Unfilled = $TaskContent -match "### Q2:[\s\S]*?\[回答"
            if ($Q1Unfilled -or $Q2Unfilled) {
                Write-Host "  ⚠️  WARN: ${FilePath} 的 Q1 或 Q2 尚未填写（保留了模板占位符），归档前必须回答。" -ForegroundColor Yellow
            } else {
                Write-Host "  ✅ ${FilePath}: 收尾反思已填或已确认完成。" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "  ⏭️  无活跃任务记录，跳过 Probe 3。" -ForegroundColor Yellow
}

# ═══════════════════════════════════════
# 最终判定
# ═══════════════════════════════════════
Write-Host "--------------------------------------------------------"
if ($Pass) {
    Write-Host "✅ ALL PROBES PASSED! 业务一致性已达成门禁准入。" -ForegroundColor Green
    Write-Host "--------------------------------------------------------"
    exit 0
} else {
    Write-Host "❌ VALIDATION FAILED! 请根据上述错误信息修复蓝图一致性问题。" -ForegroundColor Red
    Write-Host "--------------------------------------------------------"
    exit 1
}
