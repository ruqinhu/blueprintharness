# 技术规格与组件白名单 (TECH_STACK.md)

> 文档权威等级：P0 (最高执行依据)
> 本工程强制锁定 `dc-framework` 企业级技术栈与统一模板规范。Agent 严禁引入第三方同类组件或手写原生实现（No Reinventing the Wheel）。

## 1. 基础环境约束
- **语言 Runtime**: Java 17
- **框架基础**: Spring Boot 3.x, Spring Cloud
- **基础中间件**: Nacos (注册/配置中心), Sentinel (限流降级), RocketMQ (消息队列)
- **数据库**: MySQL + Druid连接池
- **构建工具**: Maven 3.8+
- **构建基础**: 根工程 `pom.xml` 必须包含 `com.dc.framework:dc-dependencies` BOM 和 `com.dc.biz:dc-biz-bom`。

## 2. 强制组件映射表 (Whitelist)

凡涉及以下业务能力，**必须**使用对应的组件/机制，严禁自造轮子。

| 业务能力 | 推荐/强制组件 (Starter/组件) | 备注说明 |
| :--- | :--- | :--- |
| **缓存 (Cache)** | `dc-spring-boot-starter-redis` | 基于 Redisson 底座，禁用原生 RedisTemplate |
| **分布式锁 (Lock)** | `@DcLock` (Redisson) | 强制使用该注解进行锁保护 |
| **消息队列 (MQ)** | `RocketMQ` | 基于 RocketMQ 生产者/消费者标准实践 |
| **数据库 (ORM)** | `MyBatis-Plus 3.5.11` | 使用指定的版本底座，严禁随意升级 |
| **任务调度** | `XXL-Job` | 统一分布式任务调度入口 |
| **API 文档** | `Knife4j (Swagger3)` | 对外接口必须加注 Knife4j 配置注解 |
| **操作日志** | `@OperationLog` | 记录业务审计轨迹，规范化操作捕获 |
| **幂等管控** | `dc-spring-boot-starter-idempotent` | 按需引入。关键支付/提交事务建议配备拦截处理逻辑 |
| **业务公共核心** | `dc-biz-common-core` | 公共枚举、常量、响应码 |
| **安全认证** | `dc-biz-security` | 统一认证/授权模块 |
| **主键生成策略** | **自增策略 (Auto-increment)** | 实体主键 ID 必须使用数据库自增。注：业务编号由 `DOMAIN_MODEL` 定义，不受此约束 |
| **业务编号生成** | `SnowflakeKeyGenerator` (可选) | 订单号、流水号等业务编号场景可使用雪花算法 |
| **日志** | `Logback + Logstash` | 统一日志采集通道，禁止引入其它日志框架 |
| **异步任务** | `dc-biz-async-task` | 使用统一业务异步队列封装处理耗时操作 |
| **分页模型** | `PageResult / BasePageParam` | 强制使用 `com.dc.framework.common.model.domain` 下的分页封装 |
| **统一响应** | `ApiResult<T>` | 必须使用 `com.dc.framework.common.model.result.ApiResult` |
| **响应码** | `ResultCode / ResultCodeItem` | 统一响应码枚举，分别为框架层和业务层定义 |
| **业务异常** | `BusinessException` | 必须使用 `com.dc.framework.common.core.exception.BusinessException` |

## 3. 依赖自查准则
1. 检查根目录 `pom.xml`，必须导入 `com.dc.framework:dc-dependencies` BOM 和 `com.dc.biz:dc-biz-bom`。
2. 任何新增的 Maven 依赖必须在上述体系内，否则视为“架构违规”。不要随意覆盖或排除父 POM 内已定义的版本号（特别是 MyBatis-Plus 3.5.11）。

## 4. 自动自愈
- 如果格式校验或者规范脚本执行失败，Agent 应当在归档前主动确认为已修复。
