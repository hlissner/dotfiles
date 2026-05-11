# Cloudflare API Token Age Secret

## 目标

把本地 Cloudflare API token 纳入 git 可追踪的 age 加密管理，同时保持 Cloudflare Tunnel 运行时凭证和 Cloudflare API 管理凭证分离。

## 问题陈述

当前根目录 `cloudflare` 是被 `.gitignore` 忽略的本地明文文件，其中包含 Cloudflare API 自动化需要的 `API_TOKEN`。已有的 `hosts/charlie/secrets/cloudflared-credentials.age` 解密后是 tunnel runtime credentials JSON，只包含 `AccountTag`、`TunnelSecret`、`TunnelID`、`Endpoint`，不适合混入 API token。缺少一个可提交、可重建、语义清晰的 API token 加密来源。

## 验收标准

- [ ] 新增独立的 `hosts/charlie/secrets/cloudflare-api-token.age`，解密后只提供 env 形态的 `API_TOKEN=...`。
- [ ] 新增 `hosts/charlie/secrets/secrets.nix`，为该 secret 声明可用 recipient，支持 agenix 解密和后续 rekey。
- [ ] 加密文件本身不包含明文 `cfut_` token 片段。
- [ ] 不修改或混用 `cloudflared-credentials.age`，避免把 tunnel runtime credentials 和 API management token 放在同一个 secret 里。
- [ ] Legion 文档记录设计、验证、评审和交付状态。

## 假设 / 约束 / 风险

- **假设**: 根目录本地文件 `cloudflare` 是当前可信的 API token 来源；`~/.ssh/id_ed25519` 是本机可用的 age/agenix 解密身份。
- **约束**: 不在终端输出 token 明文；不自动删除或改写现有 ignored 明文 `cloudflare` 文件，避免破坏仍在使用的手动工作流。
- **风险**: Cloudflare API token 已在前序工具输出中出现过，建议后续在 Cloudflare 侧轮换；本任务只把当前 token 加密纳入 git，不负责轮换、权限收敛或消费路径迁移。
- **分级**: Medium。变更面小且不改变运行时服务，但涉及高敏凭证的长期管理与误提交风险。

## 要点

- **职责分离**: `cloudflared-credentials.age` 继续只承载 tunnel runtime JSON；API token 使用独立 env-style age secret。
- **最小迁移**: 只新增加密来源和 agenix 规则，不改调用 Cloudflare API 的脚本或现有本地明文文件。
- **可验证性**: 通过受控解密匹配 `API_TOKEN=`、检查加密文件无明文 token、确认 git 跟踪新增 `.age` 文件完成验证。

## 范围

- `hosts/charlie/secrets/cloudflare-api-token.age` - 新的 API token age secret。
- `hosts/charlie/secrets/secrets.nix` - charlie secret recipient 规则。
- `.legion/tasks/cloudflare-api-token-age-secret/**` - 任务契约、设计、验证与交付证据。
- `.legion/config.json` - 登记当前 Legion 任务。

## 非目标

- 不把 `ACCOUNT_ID`、`ZONE_ID`、`TUNNEL_ID` 或 `EMAIL` 一并迁入 age。
- 不删除根目录 ignored 明文 `cloudflare` 文件。
- 不修改 `cloudflared-credentials.age` 或 cloudflared runtime 配置。
- 不实现脚本自动读取该 age secret，也不轮换 Cloudflare API token。

## 设计索引

> **Design Source of Truth**: `.legion/tasks/cloudflare-api-token-age-secret/docs/rfc.md`

**摘要**:
- 核心流程: 从本地 ignored `cloudflare` 读取现有 `API_TOKEN`，写入独立 env-style age secret，并通过 `secrets.nix` 记录 recipient。
- 验证策略: 解密只做模式匹配，不打印明文；同时检查加密文件不含 token 明文形态。

## 阶段概览

1. **Contract and Design** - 固化任务契约，记录 API token 与 tunnel credentials 分离的设计取舍。
2. **Implementation** - 生成独立 age secret 和 agenix 规则。
3. **Verification and Delivery** - 验证解密、明文泄露检查、代码评审、walkthrough 与 PR 交付。

---

*Created: 2026-05-11 | Updated: 2026-05-11*
