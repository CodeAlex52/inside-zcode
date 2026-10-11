# ZCode went open source — but not fully: a "hold-your-nose" release, dissected line by line

> 3.0k stars, 784 forks, **1 commit**, **0 issues**, and a Computer Use that always returns `isError: true`.
> This is not open source. This is crisis PR shipped as homework.
>
> Based on full static analysis of `zai-org/ZCode@872ad96` (v3.14.0 snapshot) plus a reconstruction of the public incident timeline.
> "No code trade, no free eggs" — ZCode wrote that sentence into its own source.

If you remember one sentence:

**ZCode's open-sourcing answers a *trust crisis*, not the *openness question*. The client is visible; the server stays a black box. Quota is visible; the campaign is not honored. Toggles are visible; the pipeline still runs.**

⭐ Found this useful? Star the repo so more people audit Agent vendors: https://github.com/CodeAlex52/inside-zcode

Every checkable claim below is indexed in **[EVIDENCE.md](./EVIDENCE.md)** (claim → source location → verification command).

---

## TL;DR — the code does not lie

| What you felt | What the source shows | Where |
|---|---|---|
| git has no history | 6,973 files, 1 squashed commit | `872ad960 feat: open source`; remote has a single branch, a single hash |
| issues are disabled | no Issues tab in the repo navigation; 0 PRs | feedback is routed to `zai-org/feedback` |
| Computer Use is not open-sourced | a placeholder package, hard-wired to fail | `packages/zcode-cua/index.js:1-14`; its `package.json` says `fails closed` |
| the OSS build gets no campaign quota | the comment is right there, verbatim | `packages/ui/src/settings/model-provider-section/CodingPlanStatusActions.tsx:73` |
| the upgrade entry is display-only | same file, no badge, no rules | `CodingPlanStatusActions.tsx:73-74` |
| Friday tokens vanish by Saturday | a full "weekly quota / 5-hour pool / monthly quota / off-peak ticket" system exists in code | `zh-CN.ts:2971-3065`, `CodingPlanQuotaReset*` |
| the leak is real | official apology acknowledged "default on + upload + immediate destroy"; a company sent a formal letter | see the timeline in Chapter 1 |

Tech stack in one line: **Electron desktop + Web + Server + CLI/TUI, four clients sharing one runtime; pnpm monorepo, Node 24.14.0, React 19, Zustand + RPC; the Agent runtime lives in `apps/zcode-cli`.**

Scale: `*.ts` 3,140 + `*.tsx` 756; `packages/ui` 1,532 files, `packages/desktop` 1,479, `apps/zcode-cli` 1,488, `packages/web` 1,168. This is not a toy — it is a production workbench at a million-user scale. Which is exactly why the silent upload was fatal.

---

## 1. Background: one 313 MB `.enc` file that shook an AI company

The timeline reads like a forensic report — clean to the point of being suspicious:

- **Trigger: a disk anomaly.** Blogger `ferstar` was cleaning up disk space and found `~/.zcode` at 700 MB+. Inside `v2/checkpoints/` sat a **313 MB `.enc`** with status metadata: a full snapshot, a ~10 GB workspace, ~345 MB of core assets after excluding dependencies, `failureCount=564` still pending retry. Deleted by hand. It regrew within half an hour, failure count now 565.
- **Unpacked: 86.6% is `.git`.** The ciphertext is opaque, but the plaintext manifest left behind while packing is readable: 42,411 files, **86.6% `.git` history** — not just current code, but the repository's whole life: commits, reflog, LFS cache. Plus keyword files like `passwords_final.csv` (independently confirmed by a second community dump of 28,496 files).
- **Pipeline: direct upload to Alibaba Cloud OSS.** Reverse-engineering `app.asar` recovered the chain: `POST /api/v1/snapshot/upload-credential` fetches an OSS form signature + RSA public key → local tar.gz streamed and encrypted → **PostObject straight to OSS, never through the business servers** → OSS callback registers it. Envelope scheme: `AES-256-CTR + RSA-OAEP-SHA256`; **the private key lives only in the cloud — it is undecryptable locally, forever.** Why would resumable recovery need that design? A cross-device sync key belongs on the device.
- **Toggles: neither stops it.** The "experience optimization" switch governs training only; the "repository snapshot indexing" switch governs server-side indexing only. **The upload path references neither.** The only gate is `tokenProvider()` — **login triggers it.** Triggers: `captureBeforePrompt` before every prompt, plus `repo-wiki-update` at task end; up to 62 captures per session.
- **Nail in the coffin: v3.12.2 release notes said "optimize memory usage of repository snapshot upload".** Optimizing memory for an "accidental" behavior? After the firestorm the note was deleted. Deleting the record is the second problem.
- **The vendor admitted it.** On Sep 18, Zhipu apologized in user groups: repository indexing was on by default, uploads fired during cloud Repo Wiki generation, data was destroyed after use, the bug was fixed, and they would open-source + submit to third-party review + grant every user one extra weekly quota reset. Community rechecks of 3.14.0 found the upload code removed and the endpoint returning 404.
- **Escalation: a company sent a formal letter.** On Sep 19/20, Taiyuan Chengming Technology wrote: between Aug 28 and Sep 14, 6+ workspaces were uploaded, the largest 391.94 MB, totaling 34,549 files ≈ 425 MB — source code, architecture, version history, database passwords, cloud credentials, employee data. Twelve questions: was deletion complete? Backups? Derivatives? What about the Singapore entity? Did data leave the country? Zhipu replied "false rumors", but talks were being arranged.
- **Today: the open release you see.** `zai-org/ZCode`, one commit, starting from 3.0k stars. The upload path is already gone from the snapshot — **what was open-sourced is the post-fix build, with zero probative value for the past.**

This is why "a lot of companies had their pants pulled down": what lives inside `.git`? Deleted keys, unpushed drafts, `.env` files, internal addresses, ex-employee emails. Package it once and you have everything.

---

## 2. Unwilling trio #1–#3: one commit, no issues, fake Computer Use

### 2.1 Git history? Squashed into a single blob

```bash
$ git rev-list --count HEAD
1
$ git log --oneline
872ad96 feat: open source
```

7,000+ files in one `feat: open source`. No evolution, no blame, no review trail — no way to ask who wrote the "optimize snapshot upload memory" line, or why.

An old saying in open source: **a release without history is a "code drop", not "open development".** You may look, but you cannot know how it grew — and you certainly cannot audit what it used to be.

For contrast: OpenAI Codex CLI and Gemini CLI were developed in the open, commit by commit. ZCode followed the classic "forced open source" cadence: apologize and promise to open-source → receive a formal letter on the 20th → push at `05:14` on the 21st. One commit solves a trust crisis; KPIs maxed.

### 2.2 Issues? Nonexistent — go queue up elsewhere

Repo navigation: Code / Pull requests (**0**) / Actions / Projects / Security (**0**) / Insights — **no Issues**.

Want to complain? Go to `zai-org/feedback` (16 stars, 306 issues over there). The main repo collects stars, not complaints. PRs are 0 as well; `architecture-policy.yaml` + `architecture-check` gate everything hard, and external contributions go through review first.

The upside is quiet. The downside: **security problems get no public ID, no CVE, no timeline — everything rests on a blogger paying for his own forensics.**

### 2.3 Computer Use? You got a tombstone interface

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

The package's own `package.json` says it: `API-compatible placeholder... fails closed`.

In plain words: **the sexiest, riskiest feature — the one involving screen capture and system control — is not shipped at all.** The interface shape is preserved; the capability is extracted. `NOTICE.md` admits it too: `本仓库随附的 Computer Use 包为不可用占位实现` (see `NOTICE.md:24`).

A "true open-source Computer Use"? No. Is it fear of what you'd see, or fear of what you'd do with it? You decide.

---

## 3. The honest line in the source: "the OSS build gets no campaign quota"

The most honest comment in the entire repository is not in the README — it is in a UI component:

```tsx
// packages/ui/src/settings/model-provider-section/CodingPlanStatusActions.tsx:73
// 开源版不享受额度活动权益，升级入口只展示操作，不附带优惠徽标或规则说明。
```

Translation, word by word:

- **"No code trade, no free eggs"** — if you self-compile instead of using the official distribution: the Friday limited tokens, holiday campaigns, subsidized quota? Not for you.
- The upgrade button remains, but it's just a doorknob: click to look, no discount badge, no rules. Want to grab the perks? Log into the official client.

The supporting evidence chain is complete:

- `zh-CN.ts:2971+`: weekly quota reset, 5-hour prompt pool, weekly quota, monthly tool quota — the full subscription vocabulary.
- `CodingPlanQuotaResetAction/Status` + `useCodingPlanQuotaResetUi`: reset, queuing, ticket status sync, redemption — polling the backend.
- `sidebarCodingPlanUpgrade.ts:11`: API-key mode does not inject the plan key; the avatar upgrade entry is directly affected — **bring your own key, forget the plan.**
- Sep 18 announcement, verbatim: "全体用户额外提供一次周额度重置，今起发放。" — Quota was the core currency of the apology. The OSS build cannot redeem it.

One more cut: `.env.example` points `ZCODE_BASE_URL=https://zcode.z.ai`, `ZAI_OAUTH_ORIGIN=https://chat.z.ai`, `ZCODE_CDN_BASE_URL=https://cdn-zcode.z.ai` — all official domains. Self-host? Sure — but gateway forwarding, plans, billing and the update feed all point back to the vendor (see the Chapter 2 table in NOTICE). **What is open-sourced is the client; billing and gateway stay theirs.**

---

## 4. Architecture: big and complete — ambition of a workbench

```
packages/desktop      Electron Main + Host + Renderer, DMG packaging
packages/web          Web client
packages/server       HTTP/WS + remote connections (SSH/WSL/containers)
packages/zcode-server-cli  Standalone server launch and process management
packages/ui           Shared React components + hooks + Zustand
packages/services     Business services and persistence (subscription, sharing, memory, MCP…)
packages/shared/rpc/client  Protocol, types, RPC, Agent SDK
packages/provider(+node)    Provider common capabilities + Node implementation
apps/zcode-cli        Agent CLI, TUI, runtime and tools (1,488 files — the real heart)
scripts/config/third-party  Build, embedded config, third-party notices
```

A few parts that deserve a star (criticize where due, but credit real engineering):

1. **Four clients, one runtime**: Desktop / Web / TUI / Server share the Agent runtime; a single `zcode` binary dispatches — no args enters TUI, `--web` starts the web app. The README even covers auto-minting a token for `--host 0.0.0.0`.
2. **Architecture governance is serious**: `architecture-policy.yaml` + `architecture-check` + `AGENTS.md` enforce cross-package import rules, ban UI-from-Repo calls, and guard Zustand loops. 7,000 files stay unrotten because of these house rules.
3. **Design system obsession**: `DESIGN.md` at 537 lines enforces `text-ui-*` scales, bans raw Tailwind font sizes, forbids touching `html fontSize`. Dense, operational, long-session-first — an aesthetic genuinely built for programmers.
4. **Full plugin / MCP / skill / hook stack**: lifecycle hooks (SessionStart / UserPromptSubmit / PreToolUse / PermissionRequest / PostToolUse…) can rewrite tool inputs and participate in permission decisions; workspace MCP auto-connects; skill sync can move entire directories. Powerful — and a large attack surface, which NOTICE spends a full page on.
5. **Gateway forwarding, stated plainly**: for two official Anthropic-compatible endpoints it matches by protocol + host + port + path, rewrites to the ZCode gateway, **preserving method/body/query and every header except Host (including credentials)**, with no per-request confirmation. Their words, not mine.

---

## 5. `NOTICE.md`: the most honest disclaimer ever (translated)

A 27 KB NOTICE, the most valuable read in the repo. Other projects write legal boilerplate; this one reads like a security researcher wrote it. Translated:

| Original | Plain words |
|---|---|
| Shared adapters provide no OS sandbox; `build` is the default, `--prompt` defaults to `yolo` | The Agent runs with your account's permissions: it can read, write, delete files, spawn processes, reach the network. Non-interactive mode is fully automatic. |
| Model claims like "done / safe / authorized" don't count | Trust exit codes and diffs, not the model's mouth. |
| Snapshots and git checkpoints are not backups | If rollback fails, your data is gone. |
| Sharing is public-importable by default; attachments may be uploaded before sending | Redact before sharing. Deleting locally does not delete the cloud copy. |
| CLI credentials encrypted, key derivable from local env, plaintext accepted; desktop credentials not in the system keychain; web OAuth may live in localStorage | Do not treat this credential storage as a vault. Losing the laptop loses the keys. |
| Model I/O logs written locally by default; production rotates, tests do not | Your prompts and code sit on disk in (partially redacted) plaintext. Clean up. |
| Closing the desktop window may just hide it to the tray | You think it exited; it is still running. |
| Standalone remote services listen on loopback only, no external auth | Expose it publicly and you are naked — add a gateway and TLS yourself. |

**The sharpest line** (end of Chapter 4): `受第三方版权、许可及再分发条件等约束，不承诺提供官方产品的全部功能及活动政策，具体以实际发布的源码和构建产物为准。`

— What the official build has, the OSS build may not: quota, Computer Use, certain model capabilities can vanish at any time. Small print first, fine print later.

---

## 6. Why every Agent vendor should copy this homework (the security lesson)

ZCode + Grok Build (July: uploaded entire projects to GCS, including files marked "do not read") + Claude Code (hourly remote-config polling that can bypass permission prompts) prove one thing:

**For two years, Agent security focused on "the model going rogue" and "prompt injection". Nobody defended against "the vendor itself".**

Three prescriptions — technically easy, motivationally hard:

1. **Egress manifest**: vendors publish which domains the Agent contacts, which data classes it sends, and where CORS/OSS direct uploads go. Verification drops from "reverse-engineer the asar" to "compare a packet capture".
2. **Local egress log**: write one readable record per send — size, destination, category, trigger stack. Don't leave a 313 MB encrypted blob in `~/.zcode` for users to discover themselves.
3. **Reproducible builds + open-source the *incident* version**: releasing only the post-fix build has zero probative value. At minimum map binary hashes to source tags so the community can `diff` 3.12.3 → 3.14.0 and see which lines were deleted.

Until those land, here is a self-defense checklist for companies (copy-paste):

```bash
# 1. See if you were hit (read-only; keep the evidence)
du -sh ~/.zcode/v2/checkpoints/ 2>/dev/null
ls -lh ~/.zcode/v2/checkpoints/ | head
# Windows: %LOCALAPPDATA%\Programs\ZCode\resources\app.asar + ~/.zcode/v2/checkpoints/

# 2. Run Agents under a dedicated account + least-privilege directory; never open one at a monorepo root
# 3. Before prompting, check .gitignore covers .env, *credential*, *password*, LFS cache
# 4. Rotate cloud credentials once (Chengming already did)
# 5. Watch the egress: POST /api/v1/snapshot/upload-credential, OSS PostObject, repo-wiki-update
```

A read-only scanner for step 1 is included: [`scripts/scan-local-traces.sh`](./scripts/scan-local-traces.sh).

---

## 7. Q&A

**Q: Does open-sourcing prove innocence?**
A: No. It only proves "the current client no longer contains that code". What the server stores, whether backups were purged, how much was uploaded before — invisible. As one practitioner told 36kr, there are three gates: explain clearly, turn it off, prove deletion. ZCode passed the first 1.5.

**Q: Is it still worth starring / studying?**
A: Yes. A production-grade Agent workbench with 7,000 files is a rare sample for the Chinese community: architecture governance, RPC protocol, four clients on one runtime, TUI packaging. Criticize while studying. The star is for the supervisory value of *forced transparency*, not for perfection.

**Q: How do the Friday tokens actually work?**
A: Log into the official client and wait for Friday's drop; be fast, they are usually gone by Saturday. Self-compiled builds get no campaign benefits (source comment, verbatim). No code trade, no free eggs — that is the current state of affairs.

**Q: Is it safe to use now?**
A: 3.14.0 removed the upload path (community-verified 404), so short-term risk is contained. But the `.git` packaging lesson remains: **always assume an Agent can see the entire workspace.** Before opening one on a sensitive repo, rehearse `git clean -ndx` in your head.

---

## Reproduce this analysis

```bash
git clone --depth 1 https://github.com/zai-org/ZCode /tmp/zcode
git -C /tmp/zcode log --oneline --all
cat /tmp/zcode/packages/zcode-cua/index.js
sed -n '70,75p' /tmp/zcode/packages/ui/src/settings/model-provider-section/CodingPlanStatusActions.tsx
wc -l /tmp/zcode/NOTICE.md && head -30 /tmp/zcode/NOTICE.md
find /tmp/zcode -type f | wc -l

# Local trace self-check (read-only, included in this repo):
./scripts/scan-local-traces.sh
```

## References

- ferstar's forensic write-up and three community reproductions (Windows read-only 85 MB / 1,311 hits; Linux 1.1 GB encrypted bundle; 28,496-file filter-gap verification)
- Media: Phoenix Tech / ITHome (Sep 18 apology), InfoQ, 36kr, Red Star News (Chengming's 12 questions), OSCHINA (Sep 18)
- Snapshot: `zai-org/ZCode@872ad96`, `NOTICE.md`, `README.md`, `packages/zcode-cua/*`, `CodingPlanStatusActions.tsx:73`

> Disclaimer: This article is based on public reporting + static analysis of the open snapshot. No server-side penetration, no MITM — only client code and document auditing. Characterization of the incident defers to official written responses and judicial conclusions. PRs correcting errors are welcome.

---

*If your company's data was uploaded by ZCode, post your (redacted) `checkpoints` size and version in an Issue so we can map the blast radius together. At 1k stars I will add a chapter auditing the gateway forwarding and sharing pipeline line by line.*
