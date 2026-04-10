# 架构设计 (ARCHITECTURE.md)

> 文档权威等级：P3
> 本文档定义了系统的逻辑分层、组件边界及依赖准则。

## 1. 逻辑分层与职责

| 层级 | 组件 | 关键职责 |
| :--- | :--- | :--- |
| **L4** | Controller | RESTful 接口暴露，不含业务逻辑。 |
| **L3** | Service / Logic | **核心业务流程编排**，必须引用 `BUSINESS_PROCESS` 中的流程定义。 |
| **L2** | Domain / Entity | **核心业务规则执行**，必须引用 `DOMAIN_MODEL` 的规则（BR-xxx）。 |
| **L1** | Infrastructure | 数据库访问 (Mapper/DAO)、第三方 SDK 调用。 |
| **L0** | Common / Utils | 通用工具类、错误码、基础常量。 |

---

## 2. 依赖准则 (Dependency Rules)

- **允许：** 高层依赖低层。
- **禁止：** 低层反向依赖高层（例如 Service 层引用 Controller 会被 `validate.sh` 拦截）。
- **强制：** 业务逻辑层必须通过 `@blueprint-ref` 锚点建立与蓝图文档的强关联。

---

## 3. 技术栈大纲

- **Backend**: Java 21+ / Spring Boot 3.4+ / Maven
- **Database**: MySQL 8.0 / Redis 7.2
- **Infrastructure**: Mybatis Plus / Apache HttpClient 5
- **Testing**: JUnit 5 / ArchUnit
