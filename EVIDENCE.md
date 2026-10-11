# EVIDENCE — 断言 → 源码位置 → 复现命令

> 本文件为全文所有可核查断言的索引。快照基线：`zai-org/ZCode@872ad96`
> （v3.14.0，静态快照）。**标注规则**：
>
> - `[快照]` 可直接在本仓库引用的开源快照中复现验证；
> - `[社区]` 来自第三方独立复现，附出处；
> - `[媒体]` 来自公开报道，附出处；
> - `[负证据]` 快照中已不存在对应链路，属于“修复后”状态的证据。

---

## 0. 复现环境（一次准备，全部命令可用）

```bash
git clone --depth 1 https://github.com/zai-org/ZCode /tmp/zcode
cd /tmp/zcode
git log --oneline -1          # 期望: 872ad96 feat: open source
git rev-list --count HEAD     # 期望: 1
```

> 全部检查均为**只读**：不执行构建、不运行安装器。Windows 路径见 README 第六章。

---

## A. 仓库形态 `[快照]`

| # | 断言 | 验证命令 | 预期 |
|---|---|---|---|
| A1 | 全仓库只有 1 个 squash commit，无历史 | `git rev-list --count HEAD` / `git log --oneline --all` | `1` / 仅 `872ad96 feat: open source` |
| A2 | remote 只有 `main`（无 tag、无其他分支） | `git branch -a` / `git tag \| wc -l` | 仅 `main` / `0` |
| A3 | Issues / PR 在主仓被关闭 | `gh api repos/zai-org/ZCode --jq '{has_issues, open_issues_count, forks_count}'` | `has_issues=false`，issue 计数为 0（评测时点） |
| A4 | 反馈被导流到 `zai-org/feedback` | 快照 README 的反馈指引 | 指向 feedback 仓库 |
| A5 | 仓库导航没有 Issues Tab | 浏览器打开 `github.com/zai-org/ZCode` | 无 Issues 入口 |

## B. 代码实证（额度 / Computer Use / 升级入口） `[快照]`

| # | 断言 | 源码位置 | 复现命令 |
|---|---|---|---|
| B1 | Computer Use 是占位包：写死不可用 | `packages/zcode-cua/index.js`（约 1–14 行），`packages/zcode-cua/package.json` 自述 `fails closed` | `cat packages/zcode-cua/index.js`；`cat packages/zcode-cua/package.json` |
| B2 | 开源版**不享受额度活动**（注释原文） | `packages/ui/src/settings/model-provider-section/CodingPlanStatusActions.tsx:73` | `sed -n '70,75p' packages/ui/src/settings/model-provider-section/CodingPlanStatusActions.tsx` |
| B3 | 升级入口只展示操作，不带徽标、不带规则说明 | 同上文件 `:73-74` | 同上命令可见完整上下文 |
| B4 | 存在完整的“周额度 / 5 小时池 / 月额度 / 闲时票据”体系 | `packages/ui/.../zh-CN.ts:2971-3065`，`CodingPlanQuotaReset*` 系列 key | `grep -n "CodingPlanQuotaReset" packages/ui/src/.../zh-CN.ts` |
| B5 | `NOTICE.md` 关键句：“受第三方…约束，不承诺提供官方产品的全部功能及活动政策” | `NOTICE.md`（免责章节，约 27KB 全文） | `wc -c NOTICE.md`；`grep -n "活动政策" NOTICE.md` |
| B6 | NOTICE 中的安全要点（无 OS 沙箱、`yolo` 默认、凭据存储、本地日志、托盘常驻、回环服务） | `NOTICE.md` 对应小节 | `head -60 NOTICE.md`；`grep -n "沙箱\|credential\|托盘\|回环" NOTICE.md` |

## C. 规模统计 `[快照]`

| # | 断言 | 复现命令 | 预期（评测时点） |
|---|---|---|---|
| C1 | `*.ts` 3140 个 | `find . -name "*.ts" \| wc -l` | ≈3140 |
| C2 | `*.tsx` 756 个 | `find . -name "*.tsx" \| wc -l` | ≈756 |
| C3 | 全仓库 6973 个文件 | `find . -type f \| wc -l` | ≈6973 |
| C4 | 目录规模：`packages/ui` 1532 / `packages/desktop` 1479 / `apps/zcode-cli` 1488 / `packages/web` 1168 | `find packages/ui -type f \| wc -l` 等 | 同上 |

> 说明：数字会随快照版本变化，请以你自己 `git clone` 的最新快照实测为准；这里是评测时点的记录值。

## D. 事件链（第三方与公开报道） `[社区]` `[媒体]`

| # | 断言 | 来源 | 状态 |
|---|---|---|---|
| D1 | `~/.zcode` 下发现 **313MB `.enc`** 全量快照，`failureCount=564` → 565 持续重试 | ferstar 取证原文 | 社区独立复现 |
| D2 | 打包清单 42411 文件、**86.6% 为 `.git` 历史**；含 `passwords_final.csv` 等关键词文件 | 社区三份独立复现（Win 85MB/1311 次、Linux 1.1GB 包、28496 文件验证） | 社区 |
| D3 | 直传链路：`POST /api/v1/snapshot/upload-credential` → OSS PostObject 直传（不经业务服务器）→ 回调登记 | 逆向 `app.asar` 分析 | 社区 |
| D4 | 9·18 官方致歉：默认开启、上传、用完即销毁、已修复、将开源+第三方审查+全体用户额外一次周额度重置 | 凤凰网科技 / IT之家 9·18 报道 | 媒体 |
| D5 | 9·19–9·20 企业发函：6+ 工作区、最大 391.94MB、34549 文件≈425MB，12 问 | 红星新闻（承明科技） | 媒体 |
| D6 | v3.12.2 更新日志曾含“优化仓库快照上传的内存占用”，事件后条目被删 | 社区存档对比 | 社区 |
| D7 | `zai-org/feedback` 承接反馈，主仓只接受 Star/Fork | 同 A3/A4 | 快照 |

## E. 负证据：快照中已摘除/修复的部分 `[负证据]`

| # | 断言 | 验证命令 | 预期 |
|---|---|---|---|
| E1 | 快照中已搜不到上传链路关键字 | `grep -rn "snapshot/upload-credential" /tmp/zcode \| wc -l` | `0` |
| E2 | 对应接口返回 404 | 社区验证（2025-09 修复后） | 404 |
| E3 | 推论：开源的是“修复后”客户端，**对事发时行为零证明力**（服务端存什么、备份删没删、此前传了多少，快照均不可证） | 依赖 E1+E2+D4 综合判断 | 结论性表述 |

## F. 范围与免责（与 README 一致）

- 本文仅基于**公开报道 + 开源快照静态分析**；未做服务端渗透、未做 MITM。
- 事件定性以官方书面回复与司法结论为准。
- 所有 `[社区]`/`[媒体]` 断言可回溯到 README“参考与致谢”中的原始出处。

## G. 纠错机制

发现任何断言与事实不符，请开 Issue 并附：

1. 断言编号（如 `B2`）；
2. 复现命令与输出（或报道链接与原文段落）；
3. 结论修正建议。

错了我改，对了我加更——原则与 README 一致。
