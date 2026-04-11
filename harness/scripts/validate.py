#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Blueprint Harness 企业级校验脚本 (Python v1.0)
环境锁定：Java 17 + Maven + dc-framework
"""

import os
import sys
import subprocess
import re
from pathlib import Path

# --- 配置区 ---
REQUIRED_DOCS = [
    "harness/spec/DOMAIN_MODEL.md",
    "harness/spec/BUSINESS_PROCESS.md",
    "harness/spec/PRODUCT_SENSE.md",
    "harness/spec/ARCHITECTURE.md",
    "harness/spec/VERIFY.md",
    "harness/spec/TECH_STACK.md",
    "harness/workflow.md"
]

# --- 辅助函数 ---
class Color:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    GRAY = '\033[90m'
    CYAN = '\033[96m'
    END = '\033[0m'

def log_info(msg): echo(f"🔍 {msg}")
def log_success(msg): echo(f"  {Color.GREEN}✅ {msg}{Color.END}")
def log_fail(msg): echo(f"  {Color.RED}❌ {msg}{Color.END}")
def log_warn(msg): echo(f"  {Color.YELLOW}⚠️  {msg}{Color.END}")
def echo(msg): print(msg)

def run_cmd(cmd, shell=True):
    try:
        result = subprocess.run(
            cmd, 
            shell=shell, 
            capture_output=True, 
            text=True, 
            encoding='utf-8', 
            errors='ignore'
        )
        return result
    except Exception as e:
        return None

# --- 探针逻辑 ---

def probe_0_environment():
    echo(f"{Color.CYAN}[Probe 0] 检查项目环境合法性 (Java/Maven/BOM)...{Color.END}")
    pom_path = Path("pom.xml")
    if not pom_path.exists():
        log_fail("未发现 pom.xml。本系统严格锁定 Java/Maven 环境。")
        echo("  请在 dc-framework 基础工程内运行。")
        sys.exit(1)
    
    content = pom_path.read_text(encoding='utf-8', errors='ignore')
    if not re.search(r"com\.dc\.framework|dc-dependencies|com\.dc\.biz", content):
        log_fail("pom.xml 缺少核心依赖 (com.dc.framework 或 com.dc.biz)。")
        return False
    
    log_success("环境与 BOM 校验通过。")
    return True

def probe_1_anchor():
    echo(f"\n{Color.CYAN}[Probe 1] 检查新增代码中的业务锚点 (@blueprint-ref)...{Color.END}")
    res = run_cmd("git diff --cached --name-only --diff-filter=ACM")
    if not res or not res.stdout.strip():
        echo(f"  {Color.YELLOW}⏭️  暂存区无新增文件，跳过 Probe 1。{Color.END}")
        return True

    files = [f for f in res.stdout.splitlines() if f.endswith(('.java', '.kt'))]
    if not files:
        echo(f"  {Color.YELLOW}⏭️  暂存区无 Java/Kotlin 文件，跳过 Probe 1。{Color.END}")
        return True

    pass_flag = True
    for f in files:
        path = Path(f)
        if not path.exists(): continue
        content = path.read_text(encoding='utf-8', errors='ignore')
        if not re.search(r"@blueprint-ref:.*(DOMAIN_MODEL|BUSINESS_PROCESS|TECH_STACK|BR-[0-9]+|Anchor-)", content):
            log_fail(f"{f} 缺少有效的业务锚点引用。")
            pass_flag = False
        else:
            log_success(f"{f}: 校验通过。")
    return pass_flag

def probe_2_specs():
    echo(f"\n{Color.CYAN}[Probe 2] 检查核心规格文档 (Specs) 完整性...{Color.END}")
    pass_flag = True
    for doc in REQUIRED_DOCS:
        if not Path(doc).exists():
            log_fail(f"缺少核心文档 {doc}")
            pass_flag = False
        else:
            log_success(doc)
    return pass_flag

def probe_3_tasks():
    echo(f"\n{Color.CYAN}[Probe 3] 检查待闭环任务的收尾反思...{Color.END}")
    task_dir = Path("harness/tasks/active")
    if not task_dir.exists():
        echo(f"  {Color.YELLOW}⏭️  未发现活跃任务目录，跳过 Probe 3。{Color.END}")
        return True

    tasks = [t for t in task_dir.glob("*.md") if t.name != "_TEMPLATE.md"]
    if not tasks:
        echo(f"  {Color.YELLOW}⏭️  无活跃任务记录，跳过 Probe 3。{Color.END}")
        return True

    pass_flag = True
    for t in tasks:
        content = t.read_text(encoding='utf-8', errors='ignore')
        if not re.search(r"##\s+5\.\s+🧘\s+收尾反思", content):
            log_fail(f"任务 {t.name} 损坏，缺少“收尾反思”章节。")
            pass_flag = False
        else:
            q1_unfilled = re.search(r"###\s+Q1:[\s\S]*?\[回答", content)
            q2_unfilled = re.search(r"###\s+Q2:[\s\S]*?\[回答", content)
            if q1_unfilled or q2_unfilled:
                log_warn(f"{t.name} 的 Q1 或 Q2 尚未填写（保留了模板占位符）。")
            else:
                log_success(f"{t.name}: 校验已填写。")
    return pass_flag

def probe_4_format():
    echo(f"\n{Color.CYAN}[Probe 4] 检查代码格式与依赖规范 (Self-Healing)...{Color.END}")
    mvn_check = run_cmd("mvn -v")
    if not mvn_check or mvn_check.returncode != 0:
        log_warn("未安装 mvn，跳过 Probe 4。")
        return True

    echo(f"  {Color.GRAY}正在执行 mvn spring-javaformat:validate...{Color.END}")
    res = run_cmd("mvn spring-javaformat:validate -DskipTests")
    if res.returncode != 0:
        log_warn("检测到格式违规，正在尝试自动修复 (mvn spring-javaformat:apply)...")
        run_cmd("mvn spring-javaformat:apply -DskipTests")
        log_success("格式自动修复完成。请在 git commit 前重新 Add 这些变更。")
    else:
        log_success("代码格式校验通过。")
    return True

# --- 主入口 ---

def main():
    echo("--------------------------------------------------------")
    echo(f"{Color.CYAN}🚀 启动 Blueprint Harness 企业级验证程序 (dc-framework/Python)...{Color.END}")
    echo("--------------------------------------------------------")

    p0 = probe_0_environment()
    p1 = probe_1_anchor()
    p2 = probe_2_specs()
    p3 = probe_3_tasks()
    p4 = probe_4_format()

    echo("\n--------------------------------------------------------")
    if all([p0, p1, p2, p3, p4]):
        echo(f"{Color.GREEN}✅ ALL PROBES PASSED! 已对齐 dc-framework 企业级标准。{Color.END}")
        sys.exit(0)
    else:
        echo(f"{Color.RED}❌ VALIDATION FAILED! 请修复上述业务一致性问题。{Color.END}")
        sys.exit(1)

if __name__ == "__main__":
    main()
