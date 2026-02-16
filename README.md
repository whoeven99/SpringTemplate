# SpringTemplateUser

Spring Boot 多模块项目

## 项目结构

本项目采用多模块架构，参考 SpringBackend 框架设计，包含以下模块：

### 模块说明

1. **SpringTemplateCommon** - 公共模块
   - 提供公共的实体类、工具类、常量等
   - 被其他所有模块依赖

2. **SpringTemplateRepository** - 数据访问层模块
   - 提供数据访问层（DAO/Repository）功能
   - 包含 MyBatis-Plus 配置
   - 包含 Redis 配置
   - 提供基础 Repository 类

3. **SpringTemplateIntegration** - 集成模块
   - 提供第三方服务集成功能
   - HTTP 客户端服务
   - 外部 API 调用封装

4. **SpringTemplateService** - 业务逻辑层模块
   - 提供业务逻辑层（Service）功能
   - 依赖 Repository 和 Integration 模块
   - 包含基础 Service 接口和实现

5. **SpringTemplateApi** - API 接口层模块
   - 提供 REST API 接口
   - 包含主启动类 `ApiApplication`
   - 包含 Controller 层
   - 依赖 Service 模块

## 技术栈

- Spring Boot 3.2.3
- Java 17
- MyBatis-Plus 3.5.5
- Redis (Jedis 5.2.0)
- MySQL / SQL Server
- Druid 数据源
- Maven 多模块管理

## 模块依赖关系

```
SpringTemplateApi
  └── SpringTemplateService
        ├── SpringTemplateCommon
        ├── SpringTemplateRepository
        │     └── SpringTemplateCommon
        └── SpringTemplateIntegration
              └── SpringTemplateCommon
```

## 快速开始

1. 配置数据库连接（`SpringTemplateApi/src/main/resources/application.local.yml`）
2. 配置 Redis 连接（`SpringTemplateApi/src/main/resources/application.local.yml`）
3. 运行主启动类：`com.springtemplate.api.ApiApplication`
4. 访问测试接口：`http://localhost:8080/api/test/hello`

## 构建项目

```bash
mvn clean install
```

## 运行项目

```bash
cd SpringTemplateApi
mvn spring-boot:run
```
