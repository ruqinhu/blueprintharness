# Blueprint Harness — 业务逻辑驱动型 AI 协同开发框架

> **让 AI Agent 像受过训练的领域专家一样写代码，而不是像没有上下文的代码生成器。**

## 问题

当 AI Agent（Claude、GPT 等）参与复杂业务系统的开发时，最常见的失败模式不是"写不出代码"，而是：

- **业务逻辑凭空捏造**：没有阅读领域模型就开始编写 Service 层
- **文档形同虚设**：文档写了但 Agent 不看，或看了但不引用
- **质量不可追溯**：代码与业务规则之间没有可审计的关联链
- **流程随意跳跃**：跳过设计直接编码，跳过验证直接声明完成

Blueprint Harness 通过**机械化约束**而非"口头建议"来系统性地消除这些问题。

---

## 设计哲学   

本框架的核心理念来自 [Superpowers](https://github.com/deepfates/superpowers) 项目中经过验证的 Agent 行为塑造模式，并针对**业务逻辑密集型开发**进行了深度定制：

| 机制 | 来源 | 作用 |
| :--- | :--- | :--- |
| **Iron Laws** | verification-before-completion | 三条不可违背的铁律，定义行为底线 |
| **HARD-GATE** | brainstorming | 六阶段门禁，消灭"跳步"可能 |
| **Red Flags** | systematic-debugging | 反模式自查 + 触发即中断上报 |
| **Rationalization Prevention** | verification | 预封常见逃逸借口 |
| **Precision Anchor** | 原创 | `@blueprint-ref` 强制代码与业务文档建立可追溯链接 |

---

## 快速开始

### 1. 复制到你的项目

```bash
# 将 harness/ 目录和 AGENT.md 复制到你的业务项目根目录
cp -r blueprintharness/harness your-project/
cp blueprintharness/AGENT.md your-project/
```

### 2. 填充你的业务蓝图

按照以下顺序编辑 `harness/docs/` 下的模板文件，用你的真实业务内容替换示例：

```
PRODUCT_SENSE.md  →  你的业务是什么、解决什么痛点
       ↓
DOMAIN_MODEL.md   →  你的核心实体、状态机、业务规则 (BR-xxx)
       ↓
BUSINESS_PROCESS.md → 你的业务时序图、状态扭转矩阵
       ↓
ARCHITECTURE.md   →  你的技术分层与依赖准则
       ↓
VERIFY.md         →  你的验收标准与测试路径
```

### 3. 启动 Agent 协作

当你把 `AGENT.md` 放在项目根目录后，Agent 会自动按照 **Phase 0 → Phase 5** 的门禁流程执行：

```
Phase 0: 阅读蓝图文档 + 经验库
Phase 1: 输出功能规格书，等待你的审批
Phase 2: 拆分原子任务，扫描历史经验
Phase 3: 编码（每段代码必须有 @blueprint-ref 锚点）
Phase 4: 运行 validate 脚本 + 回答防呆双问
Phase 5: 归档任务，沉淀经验模式
```

---

## 项目结构

```
your-project/
├── AGENT.md                              # 🔴 Agent 行为宪法（启动后第一个读的文件）
│
└── harness/
    ├── docs/                             # 📘 业务蓝图库 — "事实唯一来源"
    │   ├── README.md                     #    文档导航图与阅读顺序
    │   ├── DOMAIN_MODEL.md              #    P0 级：实体、规则 (BR-xxx)、状态机
    │   ├── BUSINESS_PROCESS.md          #    P1 级：时序图、扭转矩阵、异常补偿
    │   ├── PRODUCT_SENSE.md             #    P2 级：业务价值、痛点、高风险环节
    │   ├── ARCHITECTURE.md              #    P3 级：技术分层、依赖方向
    │   └── VERIFY.md                    #    验收清单与性能底线
    │
    ├── plans/                            # 📋 任务调度中心
    │   ├── specs/                        #    功能规格书（brainstorming → 设计产出）
    │   │   └── _TEMPLATE.md             #    标准模板（含版本号、AC、影响分析）
    │   └── tasks/                        #    原子任务执行
    │       ├── active/                   #    进行中（含经验回溯字段）
    │       │   └── _TEMPLATE.md
    │       └── completed/                #    已闭环归档
    │
    ├── scripts/                          # ⚙️ 机械化执法
    │   ├── validate.ps1                 #    Windows PowerShell 验证脚本
    │   └── validate.sh                  #    Linux/macOS Bash 验证脚本
    │
    ├── trace/                            # 🔍 失败审计
    │   └── failures.md                  #    架构违规与偏差教训记录
    │
    └── memory/                           # 🧠 经验沉淀
        └── lessons.md                   #    可复用的业务代码模式库
```

---

## 核心机制详解

### 🔒 Iron Laws — 三条铁律

```
NO CODE WITHOUT PRECISION ANCHOR.    → 无锚点不代码
NO COMPLETION WITHOUT FRESH EVIDENCE. → 无证据不完成
NO CONFLICT WITHOUT ESCALATION.      → 有冲突必上报
```

### 🎯 `@blueprint-ref` — 精确锚点引用

每一段业务代码上方必须包含对蓝图文档的显式引用：

```java
// @blueprint-ref: DOMAIN_MODEL BR-002 支付前必须校验库存
public void processPayment(Order order) {
    if (!inventoryService.checkStock(order)) {
        throw new InsufficientStockException();
    }
    // ...
}
```

验证脚本会通过正则匹配检查引用是否指向了具体的文档（`DOMAIN_MODEL`、`BUSINESS_PROCESS`）或规则编号（`BR-xxx`），**伪引用会被拦截**。

### 🚨 Red Flags — 触发即中断

Agent 发现自己触发了反模式（如盲目编码、伪引用、任务膨胀）时，必须立即暂停并报告：

```
🚨 BLUEPRINT RED FLAG TRIGGERED: Blind Coding
我在未阅读 DOMAIN_MODEL 的情况下开始编写支付逻辑。
补救计划：回退至 Phase 0，先阅读 DOMAIN_MODEL 第 3 章状态机定义。
```

---

## 验证脚本

验证脚本包含三个探针（Probe）：

| Probe | 检查内容 | 失败后果 |
| :--- | :--- | :--- |
| **Probe 1** | Git 暂存区的代码文件是否包含有效的 `@blueprint-ref` | ❌ FAIL |
| **Probe 2** | 五类核心蓝图文档是否全部存在 | ❌ FAIL |
| **Probe 3** | 活跃任务的"防呆双问"是否已回答 | ⚠️ WARN |

### 运行方式

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File harness/scripts/validate.ps1

# Linux / macOS
bash harness/scripts/validate.sh
```

### 示例输出

```
--------------------------------------------------------
🚀 启动 Blueprint Harness 机械化验证程序...
--------------------------------------------------------
🔍 [Probe 1] 检查代码变更中的业务锚点引用 (@blueprint-ref)...
  ✅ OrderService.java: 业务锚点校验通过。
  ❌ FAIL: PaymentUtil.java 缺少有效的业务锚点引用。

🔍 [Probe 2] 检查蓝图核心文档完整性...
  ✅ harness/docs/DOMAIN_MODEL.md
  ✅ harness/docs/BUSINESS_PROCESS.md
  ...

🔍 [Probe 3] 检查待闭环任务的收尾反思...
  ⚠️  WARN: fix-payment-flow.md 的 Q1 或 Q2 尚未填写（保留了模板占位符），归档前必须回答。
--------------------------------------------------------
❌ VALIDATION FAILED! 请根据上述错误信息修复。
--------------------------------------------------------
```

---

## 适用场景

| ✅ 适合 | ❌ 不适合 |
| :--- | :--- |
| 业务逻辑复杂的企业系统 | 纯技术基础设施 / 工具库 |
| 多 Agent 协作的大型项目 | 30 行以内的脚本或 PoC |
| 需要审计追溯的金融/医疗等领域 | 无业务领域概念的 CRUD |
| 长期迭代维护的产品 | 一次性的 Hackathon 项目 |

---

## 自定义与扩展

### 添加新的 Probe

在 `validate.ps1` / `validate.sh` 中新增检查逻辑即可。例如：

```powershell
# Probe 4: 检查是否存在未解决的 TODO
$TodoFiles = git diff --cached --name-only | ForEach-Object {
    if (Select-String -Path $_ -Pattern "TODO" -Quiet) { $_ }
}
```

### 扩展 Red Flags 表

在 `AGENT.md` 的 Red Flags 表中直接追加新行：

```markdown
| **Untested Path** | 添加了新的业务分支但没有对应的测试用例。 |
```

### 适配其他 Agent

`AGENT.md` 的设计是 Agent 无关的。无论是 Claude、GPT、Gemini 还是其他 LLM Agent，只要它读取项目根目录的 `AGENT.md`，就会被纳入这套约束体系。

---

## 致谢

- [Superpowers](https://github.com/deepfates/superpowers) — Iron Laws、HARD-GATE、Red Flags 等行为塑造模式的灵感来源

## License

MIT
