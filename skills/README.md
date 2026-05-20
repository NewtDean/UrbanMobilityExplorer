# Cursor Agent Skills (Urban Mobility Explorer)

本目录存放 **项目级 AI 开发规范**，用于在 Cursor 中约束 Swift / SwiftUI 实现方式，确保生成代码符合本仓库的架构与 Swift 6 最佳实践。

## 技能列表

| Skill | 路径 | 用途 |
|-------|------|------|
| **urban-mobility-ios** | [urban-mobility-ios/SKILL.md](./urban-mobility-ios/SKILL.md) | iOS 18 / Swift 6 / SwiftUI、Map-first、缓存、测试、文件头 |

扩展说明见 [urban-mobility-ios/reference.md](./urban-mobility-ios/reference.md)。

## 在 Cursor 中使用

1. 确保仓库内存在 **`.cursor/skills/urban-mobility-ios/`**（与 `skills/` 同步，供 Cursor 自动发现）。
2. 在 Agent 对话中提及：「遵循 `urban-mobility-ios` skill」或「按项目 skill 实现」。
3. 新功能开发前先阅读 [docs/ADR/001-architecture.md](../docs/ADR/001-architecture.md)。

## 与文档的关系

```
docs/DESIGN.md                       ← 产品设计 & 迭代计划（WHAT / WHEN）
docs/ADR/001-architecture.md         ← 架构决策（WHY）
skills/urban-mobility-ios/SKILL.md   ← AI 编码约束（HOW）
README.md                            ← 仓库入口 & 运行说明
```

---

*本技能集用于指导 AI 辅助开发与人工 Code Review，与 Urban Mobility Explorer 主工程配套。*
