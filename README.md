# ZCode 开源了，但没完全开：一次“捏着鼻子”的开源，与一份扒底裤级的源码剖析

> 3.0k star，784 fork，1 个 commit，0 个 issue，1 个永远返回 `isError: true` 的 Computer Use。
> 这不是开源，这是危机公关式的“交作业”。
>
> 本文基于 `zai-org/ZCode@872ad96`（v3.14.0，快照）全量静态分析 + 公开事件链复盘。
> 不拿代码换，就别想拿免费鸡蛋——这句话，ZCode 用源码亲手写出来了。

如果你只想记住一句话：

**ZCode 的开源，解决的是“信任危机”，不是“开放问题”。客户端给你看，服务端照样黑盒；额度给你看，活动不给你享；开关给你看，链路照样跑。**

⭐ 觉得写得狠、写得实？点个 Star，让更多人看到 Agent 厂商自己也该被审计：https://github.com/CodeAlex52/inside-zcode

---

## TL;DR：先说结论，代码不会撒谎

| 你的体感 | 源码实锤 | 位置 |
|---|---|---|
| git 没有历史 | 全仓库 6973 个文件，1 个 squash commit | `872ad960 feat: open source`，remote 只有 `main` 一个分支一个 hash |
| issues 被禁用 | 仓库导航栏根本没有 Issues Tab，PR 也是 0 | 反馈被导流到 `zai-org/feedback`，主仓只接受 Star 和 Fork |
| Computer Use 没开源 | 占位包，写死不可用 | `packages/zcode-cua/index.js:1-14`，`package.json` 自述 `fails closed` |
| 开源版不享受额度活动 | 注释原文，一字不改 | `packages/ui/src/settings/model-provider-section/CodingPlanStatusActions.tsx:73` |
| 升级入口只展示操作 | 同上，不带徽标、不带规则说明 | 同上 `:73-74` |
| 周五领 token，周六没了 | 代码里有完整的“周额度 / 5小时池 / 月额度 / 闲时票据”体系 | `zh-CN.ts:2971-3065`，`CodingPlanQuotaReset*`，9·18 官方曾“额外提供一次周额度重置” |
| 泄露工程是真的 | 官方已致歉认了“默认开启 + 上传 + 立即销毁”，企业已发函 | 见第二章时间线；开源快照里上传链路已被摘除，恰好反证“以前有” |

技术栈一句话：**Electron 桌面 + Web + Server + CLI/TUI 四端同源，pnpm monorepo，Node 24.14.0，React 19，Zustand + RPC，Agent 运行时在 `apps/zcode-cli`。**

规模：`*.ts 3140` + `*.tsx 756`，`packages/ui 1532 文件`，`packages/desktop 1479`，`apps/zcode-cli 1488`，`packages/web 1168`。这不是小玩具，是百万用户量级的生产工作台——所以它“偷传”才致命。

---

## 一、背景：一个 313MB 的 `.enc` 文件，掀翻了“大模型第一股”

时间线很干净，干净到像取证报告：

- **起点：磁盘异常。** 博主 `ferstar` 清理磁盘，发现 `~/.zcode` 700MB+，其中 `v2/checkpoints/` 躺着一个 **313MB 的 `.enc`**，配着状态元数据：全量快照、workspace 约 10GB、剔除依赖剩 345MB 核心资产、`failureCount=564` 还在 pending 重试。手动删掉，半小时后又长出来，失败计数变成 565。
- **拆包：86.6% 是 `.git`。** 密文解不开，但打包时留下的明文 Manifest 可读：42411 个文件，**86.6% 是 `.git` 历史**——不只是当前代码，是仓库从出生到现在的所有提交、reflog、LFS 缓存。顺手还带走了 `passwords_final.csv` 这类关键词文件（社区另一份 28496 文件验证）。
- **链路：直传阿里云 OSS。** 逆向 `app.asar` 还原：`POST /api/v1/snapshot/upload-credential` 拿 OSS 表单签名 + RSA 公钥 → 本地 tar.gz 流式加密 → **PostObject 直传 OSS，不经过智谱业务服务器** → OSS 回调登记。信封加密 `AES-256-CTR + RSA-OAEP-SHA256`，**私钥只在云端，本地永远解不开**。断点恢复要这种设计干嘛？ cross-device 同步密钥就该留本地。
- **开关：两个都拦不住。** “体验优化”只管训不训练，“仓库快照索引”只管服务端建不建索引，**上传链路零引用**。唯一门禁是 `tokenProvider()`——**登录即触发**。触发点：每次发 Prompt 前的 `captureBeforePrompt` + 任务结束的 `repo-wiki-update`，单个会话最多 62 次捕获。
- **实锤补刀：v3.12.2 更新日志写着“优化仓库快照上传的内存占用”。** 给“意外行为”优化内存？事件发酵后这条日志被删了。删记录本身就是第二个问题。
- **官方认了。** 9·18 智谱在用户群致歉：代码库索引功能默认开启，Repo Wiki 云端生成时触发上传，用完即销毁，已修复，将开源 + 第三方审查 + 全体用户额外一次周额度重置。3.14.0 经社区复查，上传代码已摘、接口 404。
- **升级：企业发函。** 9·19/9·20 太原承明科技发函：8·28–9·14，6+ 工作区被传，最大 391.94MB，共 34549 文件约 425MB，含完整源码、架构、版本历史、数据库口令、云凭证、员工信息。12 问：删干净了吗？备份呢？衍生数据呢？新加坡主体是怎么回事？有没有出境？智谱回“不实消息”，但沟通已在安排。
- **今天：你看到的开源。** `zai-org/ZCode`，单 commit，3.0k star 起步。上传链路在快照里已经没了——**开源的是“修复后”，不是“事发时”。对过去零证明力。**

这就是为什么说“好多公司的底裤被扒了个遍”：`.git` 里有什么？删掉的密钥、没 push 的草稿、`.env`、内网地址、离职员工的邮箱。打包一次，全有了。

---

## 二、不甘心的三件套：单 commit、无 issues、假 Computer Use

### 1. git 历史？直接 `squash` 成一个包

```bash
$ git rev-list --count HEAD
1
$ git log --oneline
872ad96 feat: open source
```

7000+ 文件一次性 `feat: open source`。没有演进，没有 blame，没有 review 记录，没有“优化仓库快照上传内存占用”是谁写的、为什么写的。

开源社区的老话：**没有历史的开源叫“丢代码”（code drop），不叫“开放开发”（open development）。** 你可以看，但你不知道它怎么长成这样的，更审计不了“以前长什么样”。

对比隔壁：OpenAI Codex CLI、Gemini CLI 至少是持续提交的。这次 ZCode 是典型的“被迫开源”节奏：先致歉说要开源 → 20 号被发函 → 21 号凌晨 `05:14` push。一个 commit 解决信任危机，KPI 拉满。

### 2. Issues？不存在的。想骂？去隔壁排队

主仓导航：Code / Pull requests(0) / Actions / Projects / Security(0) / Insights——**没有 Issues**。

想反馈？去 `zai-org/feedback`（16 star，306 issue 那边）。主仓只负责涨 star，不负责挨骂。PR 也是 0，`architecture-policy.yaml` + `architecture-check` 卡得很死，外部贡献先过审再说。

好处是清净，坏处是：**安全问题没有公开编号、没有 CVE、没有 timeline，全靠博主自费取证。**

### 3. Computer Use？给你留了个“墓碑接口”

```js
// packages/zcode-cua/index.js
const UNAVAILABLE_TEXT = "Computer Use is not available in this build.";
export function createComputerUseRuntime(_options) {
  return {
    async execute() {
      return { content: [{ type: "text", text: UNAVAILABLE_TEXT }], isError: true };
    },
    async closeSession() {},
    async dispose() {},
  };
}
```

`package.json` 自己都写了：`API-compatible placeholder... fails closed`。

翻译成人话：**最性感、最危险、也最可能涉及截屏 + 系统操作的 Computer Use，这次根本没开。** 接口形状留着，能力抽掉。NOTICE.md 也老实承认了：`本仓库随附的 Computer Use 包为不可用占位实现`（见 `NOTICE.md:24`）。

你想要的“真·开源 Computer Use”？没有。怕你看到什么，还是怕你用到什么，自己品。

---

## 三、代码里的真心话：“开源版不享受额度活动权益”

全仓最诚实的一行注释，不在 README，在 UI 组件里：

```tsx
// packages/ui/src/settings/model-provider-section/CodingPlanStatusActions.tsx:73
// 开源版不享受额度活动权益，升级入口只展示操作，不附带优惠徽标或规则说明。
```

逐字翻译：

- **“不拿代码换，就不要想拿免费鸡蛋”**——你自编译、不用官方发行版，周五那点限量 token、节日活动、补贴额度，对不起，没有。
- 升级按钮还在，但就是个“门把手”：点开看看可以，优惠徽标、规则说明都不给你。想薅羊毛？请回官方客户端登录。

配套证据链很完整：

- `zh-CN.ts:2971+`：周额度重置、5 小时 Prompt 池、每周额度、工具月额度，全套订阅话术。
- `CodingPlanQuotaResetAction/Status` + `useCodingPlanQuotaResetUi`：重置、排队、票据状态同步、核销，后台可持续请求。
- `sidebarCodingPlanUpgrade.ts:11`：API Key 模式不注入套餐 key，头像升级入口直接受影响——**用自己的 key，就别蹭套餐**。
- 9·18 公告原文：“全体用户额外提供一次周额度重置，今起发放。”——额度是官方安抚的核心货币，但开源版没有兑换权。

再补一刀：`.env.example` 里 `ZCODE_BASE_URL=https://zcode.z.ai`，`ZAI_OAUTH_ORIGIN=https://chat.z.ai`，`ZCODE_CDN_BASE_URL=https://cdn-zcode.z.ai` 全是官方域名。自建？可以，但网关转发、套餐、支付、更新 feed 全指回官方（见 NOTICE 第二章表格）。**开源的是客户端，Billing 和 Gateway 还是人家的。**

---

## 四、架构剖析：大而全，四个字——“工作台野心”

```
packages/desktop      Electron Main + Host + Renderer，打包 DMG
packages/web          Web 客户端
packages/server       HTTP/WS + 远程连接（SSH/WSL/容器）
packages/zcode-server-cli  独立 Server 启动与进程管理
packages/ui           共享 React 组件 + hooks + Zustand
packages/services     业务服务与持久化（订阅、分享、记忆、MCP…）
packages/shared/rpc/client  协议、类型、RPC、Agent SDK
packages/provider(+node)    Provider 公共能力 + Node 实现
apps/zcode-cli        Agent CLI、TUI、运行时与工具（1488 文件，真正的心脏）
scripts/config/third-party  构建、内置配置、第三方声明
```

几个值得 Star 的技术点（骂归骂，技术要认）：

1. **四端同源**：Desktop / Web / TUI / Server 共用 Agent 运行时，`zcode` 一个二进制分流：无参进 TUI，`--web` 起 Web。`README` 写得很细，连 `--host 0.0.0.0` 自动发 token 都考虑了。
2. **架构治理是真格的**：`architecture-policy.yaml` + `architecture-check` + `AGENTS.md` 强约束跨包导入、禁止 UI 直调 Repo、Zustand 回环防护。7000 文件不烂，全靠这套“家法”。
3. **设计系统偏执狂**：`DESIGN.md` 537 行，强制 `text-ui-*` 字阶，禁 Tailwind 原生字号，禁改 `html fontSize`。 dense、operational，长会话优先——确实是给程序员用的审美。
4. **插件/MCP/技能/hook 全套**：生命周期 hooks（SessionStart/UserPromptSubmit/PreToolUse/PermissionRequest/PostToolUse…）可改写工具输入、参与权限决策；工作区 MCP 自动连接；技能同步可带走整个目录。能力强，攻击面也大，NOTICE 用了一整页讲这个。
5. **网关转发写得很直白**：对两个官方 Anthropic 兼容端点按协议+主机+端口+路径匹配，命中自动改发 ZCode 网关，**保留 method/body/query + 除 Host 外所有头（含认证信息）**，无逐次确认。NOTICE 原话，不是我编的。

---

## 五、`NOTICE.md`：史上最老实的免责声明（翻译成人话版）

27KB 的 NOTICE，全仓最值得读的文件。别的项目 NOTICE 是法务套话，这个是**安全研究员代笔**。我给你翻译一下：

| 原文 | 人话 |
|---|---|
| 共享适配器不提供 OS 沙箱；`build` 默认，`--prompt` 默认 `yolo` | Agent 跑在你账号权限下，能读写删文件、起进程、上网。非交互模式默认全自动，不问你 |
| 模型说“已完成/已安全/已授权”不算数 | 别信模型的嘴，信退出码和 diff |
| 快照、Git checkpoint 不能替代备份 | 它回滚失败了，你的数据就没了 |
| 分享默认公开可导入，附件可能先传后发 | 点分享前先脱敏；本地删了，云上还有 |
| CLI 凭据加密，密钥可从本机环境派生，也接受明文；桌面凭据非系统钥匙串；Web OAuth 可放 localStorage | 别把这套凭据存储当保险柜，丢电脑就等于丢钥匙 |
| 模型输入输出日志默认写本地，生产有轮转，测试除外 | 你的 prompt 和代码，磁盘上有份明文（部分脱敏），注意清理 |
| 桌面定时任务关窗口可能只是隐藏到托盘 | 你以为退出了，它还在跑 |
| 独立远端服务只听回环，无外部账号鉴权 | 暴露到公网就是裸奔，自己加网关和 TLS |

**最狠的一句**（第四章末尾）：`受第三方版权、许可及再分发条件等约束，不承诺提供官方产品的全部功能及活动政策，具体以实际发布的源码和构建产物为准。`

——官方版有什么，开源版不一定有。额度、Computer Use、某些模型能力，随时可以没有。先小人，后君子。

---

## 六、为什么所有 Agent 厂商都该抄这份作业（安全课）

ZCode 事件 + Grok Build（7 月，传整个项目到 GCS，连“不要读”的文件都传）+ Claude Code（每小时轮询远配、可绕过权限提示）说明一件事：

**过去两年 Agent 安全全在防“模型失控”和“提示词投毒”，没人防“厂商自己”。**

事后诸葛亮，开三副药，技术上都不难，难的是动力：

1. **出口声明**：厂商公开 Agent 会连哪些域名、传哪些类别、CORS/OSS 直传有哪些。验证成本从“逆向 asar”降到“抓包比对”。
2. **本地外传日志**：每次发送写一条可读记录：体积、目的地、类别、触发堆栈。别让 313MB 的加密包躺在 `~/.zcode` 里等用户自己发现。
3. **可复现构建 + 事发版本开源**：只开源修复后版本 = 零证明力。至少给出二进制 hash 对应源码 tag，让社区能 `diff` 3.12.3 → 3.14.0 到底删了哪几行。

在这三条落地前，企业自保清单（可直接抄）：

```bash
# 1. 看看你有没有中招（只读，别删证据）
du -sh ~/.zcode/v2/checkpoints/ 2>/dev/null
ls -lh ~/.zcode/v2/checkpoints/ | head
# Windows: %LOCALAPPDATA%\Programs\ZCode\resources\app.asar + ~/.zcode/v2/checkpoints/

# 2. 跑 Agent 用专用账号 + 最小权限目录，别在 monorepo 根目录开 Agent
# 3. 发 Prompt 前检查 .gitignore 是否覆盖 .env、*credential*、*password*、LFS 缓存
# 4. 轮换一次云凭证（承明科技已经这么干了）
# 5. 抓包看出口：POST /api/v1/snapshot/upload-credential、OSS PostObject、repo-wiki-update
```

---

## 七、自问自答：你肯定想问的

**Q：开源了就能证明清白了吗？**
A：不能。只能证明“现在的客户端没这段代码”。服务端存了什么、备份删没删、以前传了多少，开源看不到。36kr 引的从业者说法很准：三关——说清楚、关得掉、证明已删除。ZCode 目前只过了前 1.5 关。

**Q：那还值得 Star / 研究吗？**
A：值得。7000 文件的生产级 Agent 工作台全量开放，架构治理、RPC 协议、四端同源、TUI 打包，都是中文社区稀缺样本。骂是骂，学是学。Star 是给“被迫透明”的监督价值，不是给完美。

**Q：周五 token 到底怎么领？**
A：官方客户端登录等周五放量，手速要快，周六一般没了。开源自编译版没有活动权益（源码注释原话）。别拿代码换，就别想拿免费鸡蛋——这就是现状。

**Q：普通用户现在能放心用吗？**
A：3.14.0 上传链路已摘（社区验证 404），短期风险收敛。但 `.git` 全量打包的教训是：**永远假设 Agent 能看到整个工作区**。敏感仓库先做 `git clean -ndx` 心理预演，再开 Agent。

---

## 复现本文

```bash
git clone --depth 1 https://github.com/zai-org/ZCode /tmp/zcode
git -C /tmp/zcode log --oneline --all
cat /tmp/zcode/packages/zcode-cua/index.js
sed -n '70,75p' /tmp/zcode/packages/ui/src/settings/model-provider-section/CodingPlanStatusActions.tsx
wc -l /tmp/zcode/NOTICE.md && head -30 /tmp/zcode/NOTICE.md
find /tmp/zcode -type f | wc -l
```

## 参考与致谢

- ferstar 取证原文与社区三份独立复现（Win 只读 85MB/1311 次、Linux 1.1GB 加密包、28496 文件过滤漏洞验证）
- 凤凰网科技 / IT之家 9·18 致歉报道；InfoQ《比 Grok、Cursor 都狠？》；36kr《智谱，被上了一课》；红星新闻承明科技 12 问；OSCHINA 9·18 快讯
- `zai-org/ZCode@872ad96`、`NOTICE.md`、`README.md`、`packages/zcode-cua/*`、`CodingPlanStatusActions.tsx:73`

> 免责：本文基于公开报道 + 开源快照静态分析，未做服务端渗透与 MITM，仅做客户端代码与文档审计。事件定性以官方书面回复与司法结论为准。欢迎 PR 纠错，错了我改，对了我加更。

---

*如果你是被 ZCode 传过的公司同学，欢迎在 Issue 贴出你的 `checkpoints` 体积与版本（脱敏后），我们一起把“影响面”拼出来。Star 过 1k，我加更《网关转发与分享链路逐行审计篇》。*
