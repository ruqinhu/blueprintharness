# 业务逻辑驱动型 Harness — 最高宪法 (AGENT.md)

> 本文件是本工程体系的核心宪法。Claude (Agent) 在启动后的第一时间必须阅读本文件，并将其中的规范作为最高优先级指令执行。

## 1. Iron Laws (核心铁律)

```text
NO CODE WITHOUT PRECISION ANCHOR.
NO COMPLETION WITHOUT FRESH EVIDENCE.
NO CONFLICT WITHOUT ESCALATION.
```

- **精确锚点引用**：在生成任何业务代码前，必须引用 `harness/spec/` 中定义的 `DOMAIN_MODEL` 或 `BUSINESS_PROCESS` 原文。代码上方必须包含 `// @blueprint-ref: [锚点ID/规则编号BR-xxx/Mermaid节点] [引用的业务规则简述]`。
- **证据先于断言**：在声明任何任务完成前，必须执行验证脚本并输出完整结果。
  - Windows: `powershell -ExecutionPolicy Bypass -File harness/scripts/validate.ps1`
  - Linux/sh: `bash harness/scripts/validate.sh`
- **冲突即停并上报**：发现文档间存在冲突或歧义时，禁止自行揣测，必须立即停止并请求人类搭档裁决。

---

## 2. 核心执行框架

本工程采用 **HARD-GATE (阶段门禁)** 工作流。具体 Phase 定义与原子化标准见：
👉 **harness/workflow.md**

---

## 3. Red Flags 表 (反模式自查)

🚨 **中断机制 (Iron Rule)**：一旦触发以下任何条目，必须**立即暂停**所有代码动作，并在对话中以 `🚨 BLUEPRINT RED FLAG TRIGGERED: [条目名]` 开头报告。获得批准后，**必须**将该触发事件及处理结果记录至 `harness/trace/failures.md`。

| 条目名 | 触发条件 |
| :--- | :--- |
| **Blind Coding** | 未看 `harness/spec/` 下对应的蓝图就开始编写业务逻辑。 |
| **Vague Reference** | 使用伪引用（如“已对齐流程”），而非具体的规则编号或节点 ID。 |
| **Task Ballooning** | 任务规模超过预估工作量的 1/5 或涉及文件数过多。 |
| **Silent Refactor** | 在实现业务功能时，“顺便”进行了大规模的技术重构。 |
| **Ambiguity Guessing** | 面对文档 A 与 B 的冲突，自行决定以谁为准。 |
| **Evidence Skipping** | 依赖“以前跑过”的结论，而非当次验证脚本的输出。 |

---

## 4. Rationalization Prevention (借口粉碎)

| 借口 | 现实与要求 |
| :--- | :--- |
| “业务太简单，不用写规格书” | 简单逻辑也是业务规则。最简规格书也需包含 AC（验收准则）。 |
| “我记得流程，不用翻文档” | 记忆可能偏差。必须使用 `// @blueprint-ref` 建立可追溯的证据链。 |
| “先写完再统一加引用注释” | 顺序错误。引用是指导编码的，不是事后补录的。 |
| “这是紧急 Bug 修复” | 越是紧急，越需确保修复不偏离业务设计蓝图。 |

---

## 5. 法定仲裁优先级

面对文档冲突时的决策顺序（由高到低）：
1. **DOMAIN_MODEL.md** (领域实体与硬性业务规则)
2. **BUSINESS_PROCESS.md** (业务时序与扭转流程)
3. **PRODUCT_SENSE.md** (场景目标与痛点)
4. **ARCHITECTURE.md** (技术架构分层)

当发现低优先级文档与高优先级不符时，**汇报并寻求裁决**。
