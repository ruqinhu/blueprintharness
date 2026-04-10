# Task: [任务名称] (TEMPLATE)

> 所属 Spec: [链接到 specs/ 下的规格书]
> 预估规模: 本次 Spec 分解的总工作量的 1/5 ~ 1/10
> 状态: active

## 1. 🔍 业务锚点 (Precision Anchor)
> **Iron Rule: 无精确引用，不代码。**

引用 `harness/spec/` 下的 `DOMAIN_MODEL` 或 `BUSINESS_PROCESS` 原文或锚点 ID。
> **@blueprint-ref**: [精确锚点：文档标题/规则编号 BR-xxx/Mermaid节点ID] [引用的业务规则/流程简述]

## 2. 🧠 相关经验模式
> 要求扫描 `harness/memory/lessons.md`。

- [ ] **扫描结果**: [列出至少一条相关经验模式，若无则写“无”]

## 3. 🛠️ 文件变更范围
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing`
- Test: `tests/exact/path/to/test`

## 4. 🚀 实现步骤 (Step-by-Step)
> 参考 Superpowers writing-plans 风格。

- [ ] **Step 1: 编写失败测试 (若适用)**
    - [ ] `code snippet or description`
    - [ ] `verification command`
- [ ] **Step 2: 编写最小实现**
    - [ ] `blueprint-ref anchor must be included here`
- [ ] **Step 3: 验证通过**
- [ ] **Step 4: 提交变更**

## 5. 🧘 收尾反思
> 在 Phase 5 归档前必须填写。

### Q1: 本次实现与业务文档有出入吗？
> [回答。如果有，摘要并记录至 trace/failures.md]

### Q2: 本次是否发现了可复用的模式？
> [回答。如果有，摘要并记录至 memory/lessons.md]
