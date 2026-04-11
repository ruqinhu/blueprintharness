# 核心资产：技术架构 (ARCHITECTURE.md)

> 文档权威等级：P3
> 本文档定义了系统的逻辑分层、组件边界、依赖准则及开发约束。
> 技术栈选型请参阅 P0 级文档 `TECH_STACK.md`。

## 1. 物理层级与模块组织 (Maven Structure)

本工程严格遵循以下统一模板结构：

```text
{root-project-name} (父模块)
├── pom.xml
├── {module}-start               # 应用启动模块与主配置存放区
└── {module}-module              # 业务实体聚合模块 (POM，也可依规范命名为 -biz)
    ├── *-api        # API 接口定义层 (供外部微服务调用与 FeignClient 存放)
    ├── *-dao        # 数据访问层 (仅包含 Entity Mapper)
    ├── *-service    # 业务逻辑层 (流程编排，禁止直接引用 Web 层注解)
    └── *-controller # 控制器暴露层 (RESTful / RPC endpoint 入口)
```

## 2. 逻辑分层与职责映射

| 层级 | 对应物理模块 | 关键职责 |
| :--- | :--- | :--- |
| **L4** | `*-controller` | RESTful 接口暴露，处理 HTTP 协议适配，不含复杂业务逻辑。 |
| **L3** | `*-service` | **核心业务流程编排**，必须包含对 `BUSINESS_PROCESS` 的引用。 |
| **L2** | `*-api` | 接口契约定义（FeignClient、DTO），供外部消费。 |
| **L1** | `*-dao` | Infrastructure 层，数据库访问控制层 (Entity/Mapper)、三方 SDK 适配层。并遵循 `DOMAIN_MODEL` 规则。 |

## 3. API 开发与编码规范 (Red Lines)

1. **接口传参限制**：**禁止**使用路径传参（`@PathVariable`）。参数必须且只能放置在 QueryString (对于 GET) 或 Request Body (对于 POST/PUT/DELETE) 中，以便于 Sentinel 限流及统一拦截。
2. **ContentType 限制**：**严禁**使用 `application/x-www-urlencoded` 开发接口。统一使用 `application/json`。
3. **命名规范**：若资源名或动作名由多个单词组成，URL 路径上必须使用**中划线（小写）**进行连接（如 `/delete-user` 而非 `/deleteUser`）。
4. **包扫描基准**：应用启动模块强制使用指定扫描：
   - 基础扫描：`@ComponentScan(basePackages = "com.dc.{basePackage}")`
   - DAO 扫描：`@MapperScan(basePackages = {"com.dc.{basePackage}.mybatis.mapper"})`
5. **逻辑删除约定**：实体表中全局需要遵守 `deleted` 字段逻辑删除规范（`1`=已删除, `0`=未删除）。

## 4. 依赖治理规则

- **强制准则：** 业务核心驱动开发，必须通过 `@blueprint-ref` 锚定对应的规范需求文档。
- **允许：** 高层模块依赖低层模块（如 `*-controller` 依赖 `*-service`）。
- **禁止：** 
  - 禁止跨层违规（Service不能依赖 Controller）。
  - Web 层不得直接操作物理层 API 定义之外的数据访问层原生 `Mapper`，必须经过 `Service` 包装。
- **隔离**：微服务内部模块若需要对外暴露，必须抽取进入 `*-api` 层定义，由调用方声明 `FeignClient`，而不是使得其他服务直接依赖服务模块。

## 5. 分布式治理补充

所有的分布式功能实现必须落库至本项目的核心 Starter/依赖，比如：
1. **统一锁管理**：基于 `@DcLock` 或 Redisson 客户端 API 限定。
2. **幂等体系**：关键支付/提交事务必须配备合理的拦截处理逻辑。

## 6. 关键文件路径约定

| 说明 | 路径模式 |
| :--- | :--- |
| 启动类 | `{module}-start/src/main/java/com/dc/{basePackage}/**/Application.java` |
| API 接口 | `*-api/src/main/java/com/dc/{basePackage}/api/*.java` |
| 控制器 | `*-controller/src/main/java/com/dc/{basePackage}/controller/*.java` |
| 业务服务 | `*-service/src/main/java/com/dc/{basePackage}/application/*.java` |
| 数据库实体 | `*-dao/src/main/java/com/dc/{basePackage}/entity/*.java` |
| 主配置 | `{module}-start/src/main/resources/application.yml` |
| 环境配置 | `{module}-start/src/main/resources/application-{env}.yml` |
| 日志配置 | `{module}-start/src/main/resources/logback-spring.xml` |

## 7. 分页交互规范

为确保系统一致性，所有涉及列表查询的分页功能必须遵守以下规约：

1. **请求入参**：
    - 基础分页查询：必须继承 `com.dc.framework.common.model.domain.BasePageParam`。
    - 需排序分页查询：必须继承 `com.dc.framework.common.model.domain.PageParam`。
2. **响应出参**：
    - 控制器返回必须统一使用 `ApiResult<PageResult<VO>>` 结构。
    - 禁止在 Service 层或 Controller 层自行构造类似 `PageVO` 的自定义分页实体。
3. **前端交互**：
    - 分页参数统一命名为 `current` (当前页码) 和 `size` (每页条数)，禁止使用 `page/limit` 或 `pageNum/pageSize`。

## 8. 响应封装与异常处理规范

为提升系统健壮性与排错效率，必须遵循以下标准：

1. **统一响应结果 (Unified Response)**：
    - 所有的 REST 接口返回值必须强制使用 `com.dc.framework.common.model.result.ApiResult<T>` 进行包装。
    - 成功响应示例：`return ApiResult.success(data);`
    - 失败响应示例：`return ApiResult.fail(ResultCode.PARAM_ERROR);`
2. **业务异常处理 (Business Exception)**：
    - 在 Service 层或业务逻辑验证中发现非预期错误（如：余额不足、权限不足等），**必须**直接抛出 `com.dc.framework.common.core.exception.BusinessException`。
    - **严禁**使用 `return null`、`return false` 或返回自定义错误对象的方式来传递业务错误。
    - **严禁**直接抛出原始的 `RuntimeException` 或 `Exception`，必须对异常进行业务化语义封装。
3. **响应码定义 (Result Code)**：
    - 框架全局错误码使用 `ResultCode` 枚举。
    - 业务定制错误码建议在子项目内维护实现 `ResultCodeItem` 接口的枚举，以保证错误码的唯一性与可追溯性。
