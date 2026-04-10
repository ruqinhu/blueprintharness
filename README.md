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

本框架的核心理念来自 [Superpowers](https://github.com/deepfates/superpowers) 与 [Trellis](https://github.com/mindfold-ai/Trellis) 项目。通过标准化 Spec 分层与 HARD-GATE 门禁，确保 AI 在可控的轨道内运行：

| 机制 | 来源 | 作用 |
| :--- | :--- | :--- |
| **Iron Laws** | Superpowers | 三条不可违背的铁律，定义行为底线 |
| **HARD-GATE** | 原创 | 六阶段门禁，由 `workflow.md` 强制驱动，消灭"跳步"可能 |
| **Spec Sharding** | Trellis | 将业务知识拆分为高信号的规格说明 (Spec)，提高召回准确度 |
| **Precision Anchor** | 原创 | `@blueprint-ref` 强制代码与蓝图文档建立可追溯链接 |
| **Context Memory** | Trellis | 通过 `workspace/` 留存开发者 Session 日志，解决上下文丢失问题 |

---

## 快速开始

### 1. 复制到你的项目

```bash
# 将 harness/ 目录和 AGENT.md 复制到你的业务项目根目录
cp -r blueprintharness/harness your-project/
cp blueprintharness/AGENT.md your-project/
```

### 2. 填充你的业务蓝图 (Specs)

按照以下顺序编辑 `harness/spec/` 下的模板文件，用你的真实业务内容替换示例：

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

### 3. 开始协作

当你在项目根目录放置了 `AGENT.md` 后，AI 将自动加载 **Phase 0 → Phase 5** 的门禁流程。详细规则见 `harness/workflow.md`。

---

## 项目结构

```
your-project/
├── AGENT.md                              # 🔴 Agent 行为宪法（启动后第一个读的文件）
│
└── harness/
    ├── workflow.md                       # 📜 任务执行工作流（HARD-GATE 定义）
    │
    ├── spec/                             # 📘 业务规格库 (Specs) — "事实唯一来源"
    │   ├── README.md                     #    文档导航图与阅读顺序
    │   ├── DOMAIN_MODEL.md              #    P0 级：实体、规则 (BR-xxx)、状态机
    │   ├── BUSINESS_PROCESS.md          #    P1 级：时序图、扭转矩阵、异常补偿
    │   ├── PRODUCT_SENSE.md             #    P2 级：业务价值、痛点、高风险环节
    │   ├── ARCHITECTURE.md              #    P3 级：技术分层、依赖方向
    │   └── VERIFY.md                    #    验收清单与性能底线
    │
    ├── tasks/                            # 📋 任务调度中心
    │   ├── specs/                        #    功能规格书 (Task PRDs)
    │   ├── active/                       #    进行中的原子任务
    │   └── completed/                    #    已闭环归档的任务
    │
    ├── workspace/                        # 🧠 开发工作区（Session Journals）
    │   └── [user]/                       #    每个开发者的会话持续性记录
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

### 🧠 Workspace Journals — 解决上下文丢失

在 `harness/workspace/[user]/journal.md` 中，AI 会记录复杂的决策逻辑或技术选型背景。这确保了当另一名同事或下一个 AI Session 接入时，能够快速“对齐”思路。

---

## 验证脚本

验证脚本包含三个探针（Probe）：

| Probe | 检查内容 | 失败后果 |
| :--- | :--- | :--- |
| **Probe 1** | Git 暂存区的代码文件是否包含有效的 `@blueprint-ref` | ❌ FAIL |
| **Probe 2** | 核心规格文档 (Specs) 是否全部存在 | ❌ FAIL |
| **Probe 3** | 活跃任务的"防呆双问"是否已回答 | ⚠️ WARN |

### 运行方式

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File harness/scripts/validate.ps1
```

---

## License

MIT

---

## 致谢

- [Superpowers](https://github.com/deepfates/superpowers) — Iron Laws、Red Flags 等行为塑造模式的灵感来源
- [Trellis](https://github.com/mindfold-ai/Trellis) — Spec 分层、Workspace Journaling 等工程化设计的参考
