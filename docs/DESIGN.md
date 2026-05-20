# Urban Mobility Explorer — 产品设计 & 迭代计划

| 文档类型 | 设计说明书（Design Spec） |
|----------|---------------------------|
| **版本** | 1.0 |
| **状态** | Baseline — 编码前设计评审通过 |
| **日期** | 2026-05-19 |
| **作者** | Newt Ding |
| **视觉参考** | [Rooda — Arrive Scooters (Dribbble)](https://dribbble.com/shots/25137003-Rooda-Arrive-Scooters-Mobile-App-Screen) · Shahid Miah |
| **下游文档** | [ADR 001](ADR/001-architecture.md)（架构决策）· [skills/urban-mobility-ios](../skills/urban-mobility-ios/SKILL.md)（AI 编码约束）· [README](../README.md)（交付说明） |

> **阅读说明**：本文档记录 **先设计、再拆分、再排期、最后编码** 的过程产出。  
> 不重复 ADR 中的技术权衡与 README 中的功能清单；聚焦 **产品定义、体验规格、模块边界、迭代里程碑与契约优先的网络层设计**。

---

## 0. 文档链路（设计驱动开发）

```text
Phase A  本文档 DESIGN.md          → 做什么、做成什么样、分几期交付
Phase B  ADR 001                    → 关键技术选型与架构约束（Why）
Phase C  skills/urban-mobility-ios  → AI/人工编码规范（How）
Phase D  实现 + 测试 + README Demo
```

**原则**：未在设计中定义验收标准（Acceptance Criteria）的需求，不进入当期迭代。

---

## 1. 产品愿景

### 1.1 一句话

为城市通勤者与访客提供 **「打开即地图」** 的共享单车探索体验：在真实地理上下文中发现站点、判断余量、结合天气决定是否骑行，并快速收藏常用站点。

### 1.2 问题陈述

| 现状痛点 | 本产品应对 |
|----------|------------|
| 传统 App 以列表为主，空间感弱 | 地图常驻，列表/详情作为 Sheet 叠层 |
| 多个运营商 App 分散 | 通过 CityBikes 聚合全球网络（单 App 多城） |
| 弱网下白屏 | 设计阶段即要求「先缓存后刷新」 |
| 骑行决策缺少上下文 | 发现页集成 Open-Meteo 天气 + 英文骑行建议 |

### 1.3 目标用户（Personas）

| Persona | 场景 | 核心诉求 |
|---------|------|----------|
| **城市访客 Ava** | 伦敦出差 3 天 | 快速找到最近、有车、可还桩的站点 |
| **通勤者 Ben** | 每日固定路线 | 收藏 2–3 个站点，打开即看余量 |
| **QA 工程师 Dana** | 弱网 / 回归测试 | 无 API Key、无登录即可走通主路径 |

### 1.4 成功标准（V1 发布）

| 指标 | 目标 |
|------|------|
| 冷启动可交互 | ≤ 2s 内看到地图 + 默认城市站点（缓存或 Bundled） |
| 主路径完成率 | 发现 → 列表 → 选站 → 详情 → 收藏，无断点 |
| 离线演示 | 飞行模式下仍可浏览伦敦样本 + 已收藏站点 |
| 工程可维护 | 设计文档 + ADR + Skill + 单测可对应到模块 |

---

## 2. 产品范围（V1）

### 2.1 In Scope

- 全屏地图 + 底部 Discovery Sheet（常驻）
- 城市切换（目录 + Current location）
- 站点浏览（搜索 / 排序 / 筛选）
- 站点详情（余量、推荐分、收藏、Apple Maps 导航）
- 收藏列表
- 城市级天气 + 骑行文案
- 定位 FAB、地图 Pin 选中态
- 离线 Bundled 样本 + 磁盘缓存

### 2.2 Out of Scope（V1 明确不做）

- 用户注册 / 登录 / 云同步
- 扫码租车、支付、行程历史
- 推送、Widget、Live Activity
- 多语言全站翻译（天气建议可为英文）
- 自建后端、GBFS 聚合服务
- ML 个性化推荐

---

## 3. 体验规格（做成什么样）

### 3.1 信息架构

```text
App 启动
 └── MapDiscoveryView（唯一根，无 TabBar）
      ├── Map 层（站点 Pin、用户位置、选中高亮）
      ├── TopBar（城市名 · 网络名 · 设置入口）
      ├── FAB（回中心：城市 Hub 或 GPS）
      └── Discovery Sheet（固定高度，不可下滑关闭）
           ├── 问候 + Bike Stations / Your Favorite 卡片
           ├── 城市天气条（温度 + 图标 + 骑行建议）
           └── [Nested Sheet]
                ├── 站点列表（可拖 Detent）
                ├── 收藏列表
                ├── 城市选择器
                └── 站点详情（高度随内容）
```

### 3.2 核心界面验收标准

#### 3.2.1 发现页（Discovery Sheet）

| ID | 验收标准 |
|----|----------|
| D-01 | 显示个性化问候（可配置用户名） |
| D-02 | 两张品类卡片：Bike Stations、Your Favorite，点击进入对应 Nested Sheet |
| D-03 | 天气区：有数据时显示温度 + SF Symbol + 一行骑行建议；加载中显示占位且不跳动布局 |
| D-04 | Sheet 高度固定，不遮挡地图全貌；地图仍可平移/缩放 |

#### 3.2.2 地图

| ID | 验收标准 |
|----|----------|
| M-01 | 街道级缩放（约 500m 视野），切换 Sheet 时不无理由 zoom |
| M-02 | Pin 数量有上限，超出按距离裁剪 |
| M-03 | 列表选站后 Pin 保持选中；详情 Sheet 打开 |
| M-04 | 打开列表 Sheet 时不因相机误报而清空所有 Pin |
| M-05 | 支持 pinch 缩放 |

#### 3.2.3 顶栏 & 定位

| ID | 验收标准 |
|----|----------|
| T-01 | 城市名 + 运营商网络名视觉居中 |
| T-02 | 点击设置进入城市选择器 |
| F-01 | 选城市时 FAB 回到 Hub；Current location 时 FAB 回到 GPS（带屏幕偏移） |
| F-02 | 列表 Sheet 拖至全高时 FAB 上移有上限（不飞出屏幕） |

#### 3.2.4 站点列表

| ID | 验收标准 |
|----|----------|
| L-01 | 搜索防抖；支持名称/地址 |
| L-02 | 排序：最近 / 推荐 / 名称 |
| L-03 | 筛选：全部 / 有车 / 有空桩 / 仅收藏 |
| L-04 | 行内展示距离（相对城市 Hub 或 GPS，与顶栏模式一致） |
| L-05 | 点选行不关闭列表 Sheet，地图联动 |

#### 3.2.5 站点详情

| ID | 验收标准 |
|----|----------|
| S-01 | 展示余量、地址、推荐星级、最后更新时间（若有） |
| S-02 | 收藏 toggle，有 HUD 反馈 |
| S-03 | 跳转 Apple Maps 步行导航 |
| S-04 | 切换 Pin 时 Sheet 不闪烁重建 |

#### 3.2.6 城市 & 天气

| ID | 验收标准 |
|----|----------|
| C-01 | 城市目录来自 Bundled JSON，支持搜索 |
| C-02 | Current location 行显示逆地理城市名或 Unknown |
| C-03 | 换城后地图中心、站点、顶栏、天气同步更新 |
| W-01 | 天气仅在 bootstrap / 换城 / 切 Current location 时请求，不在地图拖动时请求 |

### 3.3 视觉参考（Visual Reference）

V1 发现页与地图叠层的 **布局与信息层级** 参考以下社区设计稿（微出行 / 地图 + 底部面板范式）：

| 项 | 说明 |
|----|------|
| **作品** | *Rooda — Arrive Scooters Mobile App Screen* |
| **链接** | [https://dribbble.com/shots/25137003-Rooda-Arrive-Scooters-Mobile-App-Screen](https://dribbble.com/shots/25137003-Rooda-Arrive-Scooters-Mobile-App-Screen) |
| **设计师** | **Shahid Miah**（Dribbble） |

**从参考稿吸收并落地的模式**（实现为共享单车场景，非 1:1 像素复刻）：

| 参考要素 | 本产品对应 |
|----------|------------|
| 全屏地图 + 底部白色面板 | `MapDiscoveryView` + 常驻 Discovery Sheet |
| 个性化问候 + 双品类入口卡片 | `DiscoveryBottomCard`（Bike Stations / Your Favorite） |
| 大圆角面板与卡片阴影 | `MapBottomPanelMetrics.sheetCornerRadius`、`CategoryCardStyle` |
| 地图上浮操作（定位等） | 右下角 Location FAB + `MapTopBar` |
| 清爽绿色主行动色 | `AppTheme.primaryGreen` |

**范围说明**：参考稿为滑板车品牌 UI；本产品数据与文案面向 **CityBikes 共享单车**，并在其之上扩展天气条、多城切换等工程化能力。品牌名、插图与租车流程不照搬。

### 3.4 视觉基调（V1）

| 元素 | 规格 |
|------|------|
| 主色 | 品牌绿 `AppTheme.primaryGreen` |
| 卡片 | 大圆角（~24pt）、轻阴影 |
| Sheet | 顶角 ~50pt，与全面屏曲线协调 |
| 字体 | 系统 Dynamic Type，标题 Semibold |

---

## 4. 模块拆分（编码前 WBS）

设计阶段将系统拆为 **可并行、可独立验收** 的模块包：

| 模块 ID | 名称 | 交付物 | 依赖 |
|---------|------|--------|------|
| **M0** | 工程骨架 | Xcode 工程、SPM、目录结构、文件头规范 | — |
| **M1** | 契约与网络层 | OpenAPI YAML、生成脚本、Bootstrap、**禁止手写 DTO** | M0 |
| **M2** | 领域模型 | `MobilityStation`、`MobilityNetwork`、协议 | M1 |
| **M3** | 数据韧性 | Cache Actor、SwiftData、Bundled、Decorator Provider | M2 |
| **M4** | 定位与城市 | Location、SelectedCityStore、逆地理 | M2 |
| **M5** | 地图壳 | MapView、MapManager、Metrics、FAB | M3, M4 |
| **M6** | 发现 & Sheet | DiscoveryCard、Panel、StackedSheet 状态机 | M5 |
| **M7** | 列表 & 详情 | ViewModel 列表逻辑、详情、收藏 | M3, M6 |
| **M8** | 天气 | Open-Meteo 映射、WMO 展示、发现卡片 | M1, M6 |
| **M9** | 推荐 | `StationRecommendationEngine` | M2 |
| **M10** | 测试 & 预览 | 单测、Preview 工厂、离线路径 | M1–M9 |

**接口契约**：M5 及以后 **只依赖** `StationDataProviding` / `WeatherProviding`，不 import 生成 API 类型。

---

## 5. 网络层设计（契约优先 · 强制 OpenAPI）

> **设计决策（编码前锁定）**：所有 HTTP 客户端 **必须** 由 OpenAPI Generator 从 YAML 生成，**禁止** 在业务模块手写 URLSession/Alamofire 请求与 JSON DTO。

### 5.1 为什么契约优先

| 收益 | 说明 |
|------|------|
| 单一事实来源 | YAML 即文档，Code Review 可先审契约 |
| Swift 6 一致 | 生成器 `-g swift6`，与工程语言版本对齐 |
| 可回归 | 改 YAML → 跑脚本 → 映射层单测红灯/绿灯 |
| 边界清晰 | App Target 只接触 Domain 模型 |

### 5.2 服务拆分

| 服务 | 规范文件 | 生成输出目录 | Base URL |
|------|----------|--------------|----------|
| CityBike | `Networking/Scripts/Spec/CityBikeAPI.yaml` | `OpenApiClientGenerated/CityBike_OpenAPI/` | `https://api.citybik.es/v2` |
| Open-Meteo | `Networking/Scripts/Spec/OpenMeteoAPI.yaml` | `OpenApiClientGenerated/OpenMeteo_OpenAPI/` | `https://api.open-meteo.com/v1` |
| 共享基础设施 | （首次生成提取） | `OpenApiClientGenerated/Shared/` | — |

### 5.3 生成流水线（设计定稿）

```bash
# 前置：安装 openapi-generator-cli（文档化在脚本头部）
cd Networking
./Scripts/generate-openapi-clients.sh
```

**生成器参数（不可随意更改，需架构评审）**：

| 参数 | 值 | 目的 |
|------|-----|------|
| `-g` | `swift6` | Swift 6 并发与类型 |
| `--library` | `alamofire` | 统一 HTTP 栈 |
| `responseAs` | `AsyncAwait` | 与 ViewModel async 一致 |
| `readonlyProperties` | `true` | DTO 不可变 |
| `hideGenerationTimestamp` | `true` | 减少无意义 diff |

**脚本职责**（`generate-openapi-clients.sh`）：

1. 按服务循环生成到临时目录；
2. 提取 `Infrastructure` 至 `Shared/`（仅首次）；
3. 扁平化 `APIs/` + `Models/` 到 `{Service}_OpenAPI/`；
4. 删除临时目录，保持仓库可审结构。

### 5.4 手写允许范围（白名单）

| 允许 | 路径 | 职责 |
|------|------|------|
| ✅ | `Networking/Core/MobilityAPIBootstrap.swift` | 注入 baseURL、超时、RequestBuilder 工厂 |
| ✅ | `Networking/Core/MobilityHTTPRequestBuilder.swift` | 超时、公共 Header |
| ✅ | `Networking/Core/MobilityServiceHost.swift` | 默认 Host 常量 |
| ✅ | `Networking/Package.swift` | SPM 依赖 Alamofire |
| ✅ | App `Data/API/OpenAPIDomainMapping.swift` | DTO → `MobilityStation` |
| ✅ | App `Data/API/CityBikesAPIClient.swift` | 调用生成 API 的薄封装 |
| ❌ | `OpenApiClientGenerated/**` | **禁止手改** |
| ❌ | Features / Domain 内 | **禁止** `import` 生成 Model |

### 5.5 契约变更流程

```text
1. 修改 YAML（PR 必须附带 YAML diff 说明）
2. 运行 generate-openapi-clients.sh
3. 更新 OpenAPIDomainMapping + CityBikesDTOTests
4. xcodebuild test
5. ADR 附录记录破坏性变更（若有）
```

### 5.6 App 侧 API 配置（设计常量）

| 常量 | 设计值 | 说明 |
|------|--------|------|
| `requestTimeout` | 20s | 弱网容忍 |
| `cacheTTL` | 300s | 内存 fresh |
| `staleTTL` | 3600s | 可展示陈旧数据 |
| `defaultNetworkId` | `santander-cycles` | 伦敦默认 |

---

## 6. 数据设计摘要（编码前）

### 6.1 领域实体（逻辑模型）

**MobilityStation**（站点）

- 标识：`id` + `networkId` → `favoriteKey`
- 空间：`latitude`, `longitude`
- 余量：`freeBikes`, `emptySlots`, `totalSlots`
- 运营：`renting`, `returning`, `ebikes`, `rentalURL`
- 衍生：`recommendationScore`（拉取时计算）

**MobilityNetwork**（运营商网络）

- `id`, 展示名, 城市名, Hub 坐标

### 6.2 持久化（SwiftData）

| 实体 | 用途 |
|------|------|
| `FavoriteStation` | 收藏快照 |
| `FavoriteNetwork` | 收藏网络 |
| `CachedStationRecord` | 磁盘站点缓存 |
| `CachedNetworkRecord` | 磁盘网络目录缓存 |

### 6.3 Bundled 资源

| 文件 | 用途 |
|------|------|
| `networks.json` | 城市选择器离线目录 |
| `london_stations.json` | 伦敦断网演示 |

---

## 7. 迭代计划（6 个 Sprint）

> 设计评审通过后按序实施；每期结束需满足 **DoD**（Definition of Done）。

### Sprint 0 — 基座（2 天）

**目标**：可编译空壳 + 契约生成通路。

| 任务 | 产出 |
|------|------|
| Xcode 工程 + SPM `UrbanMobilityNetworking` | 工程树 |
| CityBike / OpenMeteo YAML 初版 | `Scripts/Spec/*.yaml` |
| `generate-openapi-clients.sh` 跑通 | `OpenApiClientGenerated/` |
| `MobilityAPIBootstrap` + 单测映射骨架 | 可 `import UrbanMobilityNetworking` |

**DoD**：脚本一键生成；CI/本地 `swift build`（Networking）通过；ADR 草稿提交。

---

### Sprint 1 — 领域与数据韧性（3 天）

**目标**：无 UI，数据链路可测。

| 任务 | 产出 |
|------|------|
| `MobilityStation` / 协议 | Domain |
| `CachedStationDataProvider` + `StationCacheActor` | 降级链 |
| SwiftData 模型 + hydrate | 磁盘缓存 |
| Bundled Provider | 离线样本 |
| 单测：Provider / Cache / DTO | `UrbanMobilityExplorerTests` |

**DoD**：断网单测可返回 bundled；`DataSourceKind` 正确。

---

### Sprint 2 — 地图壳（3 天）

**目标**：地图 + 相机 + 空 Pin。

| 任务 | 产出 |
|------|------|
| `MapDiscoveryMapView` | MapKit |
| `MapManager` + `GeoUtilities` | framing |
| `MapBottomPanelMetrics` | 布局常量 |
| `StationListViewModel` 视口筛站 | `mapStations` |
| 定位服务 + 城市 Store | M4 |

**DoD**：默认伦敦有 Pin；FAB 回中心；M-01~M-05 部分满足。

---

### Sprint 3 — 发现 Sheet（2 天）

**目标**：主面板可演示。

| 任务 | 产出 |
|------|------|
| `DiscoveryBottomCard` | D-01~D-02 |
| 常驻 Discovery Sheet | D-04 |
| `MapTopBar` | T-01~T-02 |
| Bootstrap 并行加载 + HUD | 冷启动 |

**DoD**：D-01~D-04 验收；问候语 + 双卡片可点。

---

### Sprint 4 — 列表 / 详情 / 收藏（4 天）

**目标**：主路径闭环。

| 任务 | 产出 |
|------|------|
| `StationBrowseSheet` + 搜索排序筛选 | L-01~L-05 |
| `MobilityStationDetailPanel` + 收藏 | S-01~S-04 |
| `FavoritesBrowseSheet` | 收藏列表 |
| `MapStackedSheet` 状态机 | 禁止错误 dismiss |
| 推荐引擎接入列表排序 | M9 |

**DoD**：发现 → 列表 → 详情 → 收藏 → 杀进程重启收藏仍在。

---

### Sprint 5 — 城市 / 天气 / 打磨（3 天）

**目标**：V1 功能完整。

| 任务 | 产出 |
|------|------|
| `CityPickerSheet` | C-01~C-03 |
| Current location 语义 | F-01, T-02 |
| Open-Meteo + WMO 文案 | W-01, D-03 |
| FAB 全高列表上限 | F-02 |
| Preview 场景 + README Demo 位 | 可交付 |

**DoD**：全部 §3.2 验收表通过；`xcodebuild test` 绿。

---

### 并行轨（贯穿）

| 轨 | 内容 |
|----|------|
| **文档** | 本文档定稿 → ADR → Skill |
| **AI 约束** | Sprint 1 起启用 `urban-mobility-ios` skill |
| **设计走查** | 每 Sprint 末对照 §3.2 验收表 |

```text
时间线示意：

S0 ──► S1 ──► S2 ──► S3 ──► S4 ──► S5
 │      │      │      │      │      │
 M1     M3     M5     M6     M7     M8
```

---

## 8. 风险登记（设计阶段）

| 风险 | 影响 | 缓解 |
|------|------|------|
| CityBikes 字段缺失 | 详情空白 | Domain 可选字段 + UI 占位 |
| 大网络站点过多 | 内存/卡顿 | Pin 上限 + 视口过滤 |
| SwiftUI Sheet 嵌套行为差异 | 交互 Bug | 真机清单 §3.2 |
| OpenAPI 生成布局变更 | 脚本失败 | 脚本内 layout 断言 + 文档化 |
| 现场无网络 | 无法演示 | Bundled + SwiftData 强制路径 |

---

## 9. 测试策略（设计层）

| 层级 | 范围 |
|------|------|
| 契约 | DTO 映射单测（改 YAML 必跑） |
| 领域 | 推荐引擎、Geo 过滤 |
| 数据 | Provider 降级、Cache TTL、SwiftData |
| UI | Preview + 手工验收表 §3.2 |
| E2E | 不做自动化 E2E；用 Demo 视频 + 清单 |

---

## 10. 交付清单（V1 Release）

- [ ] 本文档（DESIGN.md）与 ADR、Skill 一致
- [ ] OpenAPI 脚本可复现生成
- [ ] 主路径验收表 §3.2 全部通过
- [ ] 单元测试绿
- [ ] README Demo 视频
- [ ] 离线可用（Bundled + 收藏）

---

## 11. 文档索引

| 文档 | 角色 |
|------|------|
| **本文档** `docs/DESIGN.md` | 产品 & 体验 & 迭代 & 契约网络层 |
| `docs/ADR/001-architecture.md` | 架构决策与实现细节 |
| `skills/urban-mobility-ios/SKILL.md` | 编码规范 |
| `README.md` | 仓库入口、运行方式 |

---

## 12. 致谢与设计参考（Acknowledgements）

### 12.1 UI / UX 设计参考

发现页地图 + 底部 Sheet 的 **视觉与交互灵感** 来自 Dribbble 作品 [*Rooda — Arrive Scooters Mobile App Screen*](https://dribbble.com/shots/25137003-Rooda-Arrive-Scooters-Mobile-App-Screen)。

我们向该稿件的设计师 **Shahid Miah** 致以致谢。其在版式、问候语区域、双卡片入口与大圆角面板上的一体化处理方式，为本产品的 V1 体验定调提供了重要参考。本仓库实现由工程团队独立完成，交互细节、数据层与共享单车业务逻辑均为原创扩展。

### 12.2 数据与开源

| 来源 | 用途 |
|------|------|
| [CityBikes API](https://api.citybik.es/v2) | 全球共享单车网络与站点余量 |
| [Open-Meteo](https://open-meteo.com/) | 城市天气（WMO Code） |

### 12.3 使用说明

上述 Dribbble 参考仅用于 **内部产品设计与实现对照**。公开发布时请遵守 [Dribbble](https://dribbble.com) 平台及原作者关于作品展示与衍生使用的条款；本仓库不包含参考稿源文件或导出资产。

---

## 修订历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2026-05-19 | 产品规格、模块拆分、六期迭代、OpenAPI 强制策略、Dribbble 视觉参考（Shahid Miah）与致谢 |
