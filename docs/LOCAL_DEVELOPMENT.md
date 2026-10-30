# DataPilot 本地开发与演示

## 环境与启动

使用 JDK 17+、Node.js 22+、pnpm 11、Docker Compose v2。按[仓库首页](../README.md)启动数据库、后端和前端。`.mvn/datapilot-settings.xml` 仅配置公开 Maven 镜像，不含账号；不需要镜像时可移除命令中的 `-s` 参数。

| 服务 | 地址 / 数据库 | 本地演示账号 |
| --- | --- | --- |
| 前端 | http://localhost:3000 | — |
| 后端 | http://localhost:8065 | — |
| Swagger | http://localhost:8065/swagger-ui.html | — |
| 管理 MySQL | 127.0.0.1:13307 / nl2sql_db | root / root |
| 电商 MySQL | 127.0.0.1:13306 / product_db | root / root |
| 人口 PostgreSQL | 127.0.0.1:15432 / china_population_db | postgres / postgres |

本地 Compose 覆盖配置将数据保存在 Docker 命名卷中。初始化 SQL 位于 `docker-file/config/`。示例密码只适用于隔离的本地演示环境。

## 配置 AI 分析

1. 在页面“模型配置”中添加并激活 Chat 和 Embedding 模型，填写提供方、模型名、API Key 与 Base URL。
2. 添加电商数据源，测试连接并关联到智能体。
3. 选择需要的业务表并初始化数据源，使 Schema 可以被检索。
4. 先测试自然语言查询，再测试 Python 分析、报告及人工反馈。

不要把 API Key 写入源码或提交到 Git。模型配置和数据库卷也不应作为仓库文件发布。没有有效模型凭据时，只能验证基础服务，无法证明完整 AI 工作流可运行。

Python 执行依赖 Docker Sandbox。默认 Docker endpoint 是 `unix:///var/run/docker.sock`；Windows 下需按实际 Docker 环境设置 `DATAAGENT_SANDBOX_DOCKER_HOST`，详见[开发者指南](DEVELOPER_GUIDE.md)及[高级能力](ADVANCED_FEATURES.md)。

## Windows 辅助脚本

`scripts/start-datapilot.ps1`、`stop-datapilot.ps1` 与 `start-docker-datapilot.ps1` 保留当前开发环境的启停流程，使用前请阅读脚本：

- Docker Desktop 路径假设为 `C:\Program Files\Docker\Docker\Docker Desktop.exe`，隔离运行目录固定为 `D:\DockerRuntimeDataPilot`。其他机器建议先按首页命令手动启动。
- 启动脚本只在构建产物不存在时构建；修改源码后应手动重新构建。
- 停止脚本会结束占用 3000 和 8065 端口的进程，执行前需确认这些端口属于本项目。
- 日志与进程文件位于 `.local-run/`，已排除在 Git 之外。

## 验证与停止

```powershell
# 后端测试（部分测试可能依赖外部服务，参阅上游开发文档）
.\mvnw.cmd -s .mvn/datapilot-settings.xml -pl data-agent-management test

# 前端，在前端目录执行
pnpm test:unit
pnpm build
```

基础服务检查：打开前端页面、访问 `/echo/ok` 和 Swagger，并在页面测试数据源连接。AI 端到端验收需另行完成模型配置和真实问题测试。

手动启动的前后端可在各自终端按 Ctrl+C 停止；从项目根目录停止数据库：

```powershell
docker compose -f docker-file/docker-compose.yml -f docker-file/docker-compose.local.yml stop mysql mysql-data postgres-data
```

停止容器不会删除命名卷中的数据。
