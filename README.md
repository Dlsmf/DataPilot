# DataPilot · 企业级智能数据分析 Agent

基于自然语言进行数据查询、Python 分析与报告生成的学习和演示项目。

> 本项目基于 [Spring AI Alibaba DataAgent](https://github.com/spring-ai-alibaba/DataAgent)，遵循 Apache License 2.0。核心 Agent、RAG、NL2SQL、沙盒和前端能力来自上游；本仓库整理了 DataPilot 项目入口、本地部署配置与运行资料，不将上游实现表述为个人原创。上游基线：`27e7baa`。

[本地运行](docs/LOCAL_DEVELOPMENT.md) · [架构说明](docs/ARCHITECTURE.md) · [上游介绍](README-upstream.md) · [English](README-en.md)

## 核心能力

| 能力 | 实现方式 |
| --- | --- |
| 自然语言查询 | Schema 检索、表关系补全、SQL 生成、语义检查与失败重试 |
| Agent 工作流 | Spring AI Alibaba Graph 状态图编排、条件路由和共享状态 |
| Python 数据分析 | Docker 沙盒执行、资源限制和失败重试 |
| RAG 业务增强 | 业务术语、元数据与知识的向量检索 |
| 人工确认 | 分析计划确认、修改及恢复执行 |
| 分析报告 | HTML / Markdown 报告与 ECharts 可视化 |
| 模型与工具接入 | OpenAI 兼容模型接口、模型配置和 MCP 服务 |

## 技术栈与目录

Java 17+ · Spring Boot 3.4.8 · Spring AI Alibaba 1.1.2.2 · Nuxt 4 / Vue 3 · MySQL · Docker

```text
data-agent-management/      Java 后端、Agent 工作流、SQL 与知识管理
data-agent-frontend-nuxt/   Nuxt 前端与可视化
docker-file/                容器配置与演示数据
scripts/                    当前 Windows 环境的启停辅助脚本
docs/                       架构、开发和部署文档
.mvn/                       Maven Wrapper 与可选镜像配置
```

## 快速开始

准备 JDK 17+、Node.js 22+、pnpm 11 和 Docker。以下命令在项目根目录的 **PowerShell** 中运行：

```powershell
git clone https://github.com/Dlsmf/DataPilot.git
cd DataPilot

# 启动管理数据库和两套演示数据库
docker compose -f docker-file/docker-compose.yml -f docker-file/docker-compose.local.yml up -d --wait mysql mysql-data postgres-data

# 初始化管理库并启动后端
$env:DATA_AGENT_DATASOURCE_URL = 'jdbc:mysql://127.0.0.1:13307/nl2sql_db?useUnicode=true&characterEncoding=utf-8&allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=Asia/Shanghai'
$env:DATA_AGENT_DATASOURCE_USERNAME = 'root'
$env:DATA_AGENT_DATASOURCE_PASSWORD = 'root'
$env:DATA_AGENT_DATASOURCE_SQL_INIT = 'always'
.\mvnw.cmd -s .mvn/datapilot-settings.xml -pl data-agent-management spring-boot:run
```

另开终端启动前端：

```powershell
cd data-agent-frontend-nuxt
pnpm install --frozen-lockfile
pnpm dev
```

访问 <http://localhost:3000>，在“模型配置”中配置并激活 Chat 和 Embedding 模型，再创建智能体、关联数据源并初始化 Schema。API 文档位于 <http://localhost:8065/swagger-ui.html>。

**运行边界：** 启动页面和数据库并不代表 AI 分析已可用；完整分析需要有效模型配置，Python 步骤还需要后端能够连接 Docker 沙盒。数据库默认账号用于本地演示，部署到服务器前需要调整密码、网络暴露和访问控制。

## 演示问题

- 统计每个用户的订单数和已支付金额，按金额降序展示 SQL 与结果。
- 分析各商品分类的销售额，使用 Python 计算占比并生成报告。
- 开启人工反馈，先修改分析计划，再确认执行。

## 文档

- [本地开发与演示](docs/LOCAL_DEVELOPMENT.md)：端口、模型配置、脚本限制与验证命令。
- [上游快速开始](docs/QUICK_START.md)：通用安装方式。
- [架构设计](docs/ARCHITECTURE.md)：工作流与模块说明。
- [开发者指南](docs/DEVELOPER_GUIDE.md)：扩展和配置。
- [高级能力](docs/ADVANCED_FEATURES.md)：MCP、检索与 Python 沙盒。
- [知识配置](docs/KNOWLEDGE_USAGE.md)：业务知识和语义模型。

## 来源与许可

保留上游源码版权声明、贡献文档和 [Apache License 2.0](LICENSE)。原始介绍见 [README-upstream.md](README-upstream.md)。本仓库以当前源码快照作为发布起点；原有本地历史、私人简历及面试笔记、模型凭据、数据库卷、日志与构建产物不包含在发布内容中。
