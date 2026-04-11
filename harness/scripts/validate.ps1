# Blueprint Harness 企业级校验脚本 (PowerShell v1.6)
# 环境锁定：Java 17 + Maven + dc-framework

$Pass = $true

Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "🚀 启动 Blueprint Harness 企业级验证程序 (dc-framework)..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

# ═══════════════════════════════════════
# Probe 0: 环境锁死校验 (Maven/Java Lock)
# ═══════════════════════════════════════
Write-Host "🔍 [Probe 0] 检查项目环境合法性 (Java/Maven/BOM)..."
if (-not (Test-Path "pom.xml")) {
    Write-Host "  ❌ CRITICAL FAIL: 未发现 pom.xml。本系统严格锁定 Java/Maven 环境。" -ForegroundColor Red
    Write-Host "  请在 dc-framework 基础工程内运行。" -ForegroundColor Red
    exit 1
} else {
    $PomContent = Get-Content "pom.xml" -Raw
    if ($PomContent -notmatch "com\.dc\.framework" -and $PomContent -notmatch "dc-dependencies" -and $PomContent -notmatch "com\.dc\.biz") {
        Write-Host "  ❌ FAIL: pom.xml 缺少核心依赖 (com.dc.framework 或 com.dc.biz)。" -ForegroundColor Red
        Write-Host "  请同步 dc-framework 技术栈规范。" -ForegroundColor Red
        $Pass = $false
    } else {
        Write-Host "  ✅ 环境与 BOM 校验通过。" -ForegroundColor Green
    }
}

# ═══════════════════════════════════════
# Probe 1: @blueprint-ref 精确锚点校验
# ═══════════════════════════════════════
Write-Host "`n🔍 [Probe 1] 检查代码变更中的业务锚点引用 (@blueprint-ref)..."
$StagedFiles = git diff --cached --name-only --diff-filter=ACM | Select-String -Pattern "\.(java|kt)$"
if ($StagedFiles) {
    foreach ($File in $StagedFiles) {
        $FilePath = $File.ToString()
        $Content = Get-Content $FilePath -Raw
        if ($Content -notmatch "@blueprint-ref:.*(DOMAIN_MODEL|BUSINESS_PROCESS|TECH_STACK|BR-[0-9]+|Anchor-)") {
            Write-Host "  ❌ FAIL: ${FilePath} 缺少业务锚点。" -ForegroundColor Red
            $Pass = $false
        } else {
            Write-Host "  ✅ ${FilePath}: 校验通过。" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  ⏭️  暂存区无新增代码文件，跳过 Probe 1。" -ForegroundColor Yellow
}

# ═══════════════════════════════════════
# Probe 2: 规格文档完整性
# ═══════════════════════════════════════
Write-Host "`n🔍 [Probe 2] 检查核心规格文档 (Specs) 完整性..."
$RequiredDocs = @(
    "harness/spec/DOMAIN_MODEL.md",
    "harness/spec/BUSINESS_PROCESS.md",
    "harness/spec/PRODUCT_SENSE.md",
    "harness/spec/ARCHITECTURE.md",
    "harness/spec/VERIFY.md",
    "harness/spec/TECH_STACK.md",
    "harness/workflow.md"
)
foreach ($Doc in $RequiredDocs) {
    if (-not (Test-Path $Doc)) {
        Write-Host "  ❌ FAIL: 缺少核心文档 $Doc" -ForegroundColor Red
        $Pass = $false
    } else {
        Write-Host "  ✅ $Doc" -ForegroundColor Green
    }
}

# ═══════════════════════════════════════
# Probe 3: 活跃任务的防呆双问检查
# ═══════════════════════════════════════
Write-Host "`n🔍 [Probe 3] 检查待闭环任务的收尾反思..."
$ActiveTasks = Get-ChildItem -Path "harness/tasks/active/*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_TEMPLATE.md" }

if ($ActiveTasks) {
    foreach ($Task in $ActiveTasks) {
        $TaskContent = Get-Content $Task.FullName -Raw
        # 匹配标题，对空格不敏感
        if ($TaskContent -notmatch "##\s+5\.\s+🧘\s+收尾反思") {
            Write-Host "  ❌ FAIL: 任务 $($Task.Name) 损坏，缺少“收尾反思”章节。" -ForegroundColor Red
            $Pass = $false
        } else {
            # 深度检查：检测是否保留了模板中的提示文字（即未填）
            # 优化正则以匹配不同换行符和潜在的空格
            $Q1Unfilled = $TaskContent -match "###\s+Q1:[\s\S]*?\[回答"
            $Q2Unfilled = $TaskContent -match "###\s+Q2:[\s\S]*?\[回答"
            if ($Q1Unfilled -or $Q2Unfilled) {
                Write-Host "  ⚠️  WARN: $($Task.Name) 的 Q1 或 Q2 尚未填写（保留了模板占位符），归档前必须回答。" -ForegroundColor Yellow
            } else {
                Write-Host "  ✅ $($Task.Name): 收尾反思已填写。" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "  ⏭️  无活跃任务记录，跳过 Probe 3。" -ForegroundColor Yellow
}

# ═══════════════════════════════════════
# Probe 4: Spring Java Format 自愈逻辑
# ═══════════════════════════════════════
Write-Host "`n🔍 [Probe 4] 检查代码格式与依赖规范 (Self-Healing)..."
$MvnCmd = Get-Command mvn -ErrorAction SilentlyContinue
if ($MvnCmd) {
    Write-Host "  正在执行 mvn spring-javaformat:validate..." -ForegroundColor Gray
    $FormatResult = mvn spring-javaformat:validate -DskipTests 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ⚠️  检测到格式违规，正在尝试自动修复 (mvn spring-javaformat:apply)..." -ForegroundColor Yellow
        mvn spring-javaformat:apply -DskipTests 2>&1 | Out-Null
        Write-Host "  ✅ 格式自动修复完成。请在 git commit 前重新 Add 这些变更。" -ForegroundColor Green
    } else {
        Write-Host "  ✅ 代码格式校验通过。" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠️  未安装 mvn，跳过 Probe 4。" -ForegroundColor Yellow
}

# ═══════════════════════════════════════
# 最终判定
# ═══════════════════════════════════════
Write-Host "`n--------------------------------------------------------"
if ($Pass) {
    Write-Host "✅ ALL PROBES PASSED! 已对齐 dc-framework 企业级标准。" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ VALIDATION FAILED! 请修复上述业务一致性问题。" -ForegroundColor Red
    exit 1
}
