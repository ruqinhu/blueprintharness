# 业务逻辑驱动型 Harness — 最高宪法 (AGENT.md)

> 本文件是本工程体系的核心宪法。Claude (Agent) 在启动后的第一时间必须阅读本文件，并将其中的规范作为最高优先级指令执行。

## 1. Iron Laws (核心铁律)

```text
NO CODE WITHOUT PRECISION ANCHOR.
NO COMPLETION WITHOUT FRESH EVIDENCE.
NO CONFLICT WITHOUT ESCALATION.
```

- **精确锚点引用**：在生成任何业务代码前，必须引用 `DOMAIN_MODEL` 或 `BUSINESS_PROCESS` 中的原文。代码上方必须包含 `// @blueprint-ref: [锚点ID/规则编号BR-xxx/Mermaid节点] [引用的业务规则简述]`。**无精确引用，禁止编写代码。**
- **证据先于断言**：在声明任何任务完成前，必须执行验证脚本并输出完整结果。
  - Windows: `powershell -ExecutionPolicy Bypass -File harness/scripts/validate.ps1`
  - Linux/sh: `bash harness/scripts/validate.sh`
- **冲突即停并上报**：发现文档间存在冲突或歧义时，禁止自行揣测，必须立即停止并请求人类搭档裁决。

---

## 2. HARD-GATE 工作流 (阶段门禁)

**禁止跳步。** 只有完成当前 Phase 的产出并获得批准后，方可进入下一 Phase。

| 阶段 | 动作 | 准入/准出条件 |
| :--- | :--- | :--- |
| **Phase 0: 启动** | 阅读 `harness/docs/` 下的所有核心文档 + `memory/lessons.md`。 | **准入**：任务启动。**准出**：在对话中明确列出你识别出的 1-3 个核心业务点。 |
| **Phase 1: 理解** | 基于 `harness/plans/specs/_TEMPLATE.md` 新建规格书。 | **准入**：Phase 0 完成。**准出**：人类批准位于 `harness/plans/specs/` 下的具名规格书文件。 |
| **Phase 2: 分解** | 生成原子任务计划 `harness/plans/tasks/active/`。 | **准入**：Phase 1 完成。涉及“相关经验模式”扫描。**准出**：人类批准任务列表。 |
| **Phase 3: 实现** | 编写代码，严格遵守 `@blueprint-ref` 锚点引用。 | **准入**：Phase 2 完成。**准出**：代码编写完成，测试通过。 |
| **Phase 4: 验证** | 运行验证脚本，回答“防呆双问”。 | **准入**：Phase 3 完成。**准出**：验证脚本提示 PASS 且已回答任务末尾的 [防呆双问](#防呆双问定义)。 |
| **Phase 5: 归档** | 迁移任务至 `completed/`，沉淀经验至 `memory/`。 | **准入**：Phase 4 完成。**准出**：目录清理完毕。 |

---

## 3. Red Flags 表 (反模式自查)

🚨 **中断机制 (Iron Rule)**：一旦触发以下任何条目，必须**立即暂停**所有代码动作，并在对话中以 `🚨 BLUEPRINT RED FLAG TRIGGERED: [条目名]` 开头报告。获得批准后，**必须**将该触发事件及处理结果简短记录至 `harness/trace/failures.md`。

| 条目名 | 触发条件 |
| :--- | :--- |
| **Blind Coding** | 未看 `DOMAIN_MODEL.md` 或 `BUSINESS_PROCESS.md` 就开始编写业务逻辑。 |
| **Vague Reference** | 使用伪引用（如“已对齐流程”），而非具体的规则编号或节点 ID。 |
| **Task Ballooning** | 任务规模超过预估工作量的 1/5 或涉及文件数过多。 |
| **Silent Refactor** | 在实现业务功能时，“顺便”进行了大规模的技术重构。 |
| **Ambiguity Guessing** | 面对文档 A 与 B 的冲突，自行决定以谁为准。 |
| **Evidence Skipping** | 依赖“以前跑过”的结论，而非当次验证脚本的输出。 |

---

## 4. Rationalization Prevention (借口粉碎对照)

| 借口 | 现实与要求 |
| :--- | :--- |
| “业务太简单，不用写规格书” | 简单逻辑也是业务规则。最简规格书也需包含 AC（验收准则）。 |
| “我记得流程，不用翻文档” | 记忆可能偏差。必须使用 `// @blueprint-ref` 建立可追溯的证据链。 |
| “先写完再统一加引用注释” | 顺序错误。引用是指导编码的，不是事后补录的。 |
| “这是紧急 Bug 修复” | 越是紧急，越需确保修复不偏离业务设计蓝图。 |

---

## 5. 防呆双问定义
在 Phase 5 归档任务前，必须在任务文件末尾回答以下两个核心问题：
- **Q1: 本次实现与业务文档有出入吗？**（评估偏差及风险）
- **Q2: 本次是否发现了可复用的模式？**（提取知识至 `lessons.md`）

---

## 6. 原子任务标准 (Atomicity)

单次 Task 的规模应严格控制在整个特性开发预估工作量的 **1/5 ~ 1/10**。
每个任务必须是语义完整的单元。若发现实现路径过长，必须进一步拆分。

---

## 7. 法定仲裁优先级

面对文档冲突时的决策顺序（由高到低）：
1. **DOMAIN_MODEL.md** (领域实体与硬性业务规则)
2. **BUSINESS_PROCESS.md** (业务时序与扭转流程)
3. **PRODUCT_SENSE.md** (场景目标与痛点)
4. **ARCHITECTURE.md** (技术架构分层)

当发现低优先级文档与高优先级不符时，**报告并拉人类裁决**。
