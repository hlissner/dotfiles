# Axiom SSH Autossh and Opencode Cloudflared Fix

## 目标

修复 axiom/azar SSH 访问问题，并让 axiom 的 opencode server 作为本地 systemd 服务通过新建 cloudflared tunnel 暴露到 opencode-axiom.0xc1.space。

## 问题陈述

当前有三类相关访问问题：SSH wrapper 把 $XDG_CONFIG_HOME/ssh/config 当成字面路径传给 ssh，导致已有 ~/.config/ssh/config 仍被认为不存在；azar 还没有像 charlie/axiom 那样可靠的 autossh reverse SSH service；axiom 还没有 declarative opencode server systemd service 和 cloudflared ingress 暴露。cloudflared 需要新建 axiom tunnel 并把凭证以 age secret 纳入 host 配置。

## 验收标准

- [ ] ssh/scp wrapper 在存在 XDG SSH config 时使用实际 $XDG_CONFIG_HOME 展开后的路径，不再把 "$XDG_CONFIG_HOME/ssh/config" 作为字面 -F 参数传入。
- [ ] azar 获得与 charlie/axiom 模式一致的 autossh reverse SSH service，使用 daemon-backed local ssh target 和独立 remote loopback port。
- [ ] axiom 获得 opencode-server systemd service，监听 127.0.0.1:4096，使用 c1 HOME 与 opencode 环境变量，并具备失败重启。
- [ ] 为 axiom 新建 cloudflared tunnel，凭证以 hosts/axiom/secrets/cloudflared-credentials.age 管理，ingress 将 opencode-axiom.0xc1.space 指向 http://127.0.0.1:4096。
- [ ] 相关 Nix eval/build 或 targeted assertions 通过；外部 Cloudflare/Auth/Access 无法自动证明时记录明确 blocker 或人工验证项。

## 假设 / 约束 / 风险

- **假设**: 用户确认 cloudflared 采用新建 axiom tunnel，并可配合 cloudflared login/create 的浏览器认证。
- **假设**: azar reverse SSH 使用 root@8.159.128.125，继承 charlie/axiom 的 remote loopback bind 决策；若无冲突，azar 使用下一个端口 2224。
- **假设**: axiom 的 opencode 可执行入口为 /home/c1/.opencode/bin/opencode，运行用户为 c1。
- **假设**: Cloudflare Access policy 配置可能需要在 Cloudflare 控制台人工完成，本仓库只管理 tunnel connector 和 ingress。
- **约束**: 遵守 Legion workflow；稳定 contract 后进入 git-worktree-pr envelope。
- **约束**: 不读取或输出 cloudflared credential 内容，不提交明文 token/JSON。
- **约束**: opencode server 只监听 loopback，公网入口必须经 cloudflared/Access。
- **约束**: 保持 charlie 现有 tunnel 和 opencode 配置不变。
- **风险**: cloudflared 登录和 DNS/Access 配置依赖外部 Cloudflare 状态，可能无法完全自动化验证。
- **风险**: azar remote port 2224 若已占用或 SSH key/known_hosts 未就绪，autossh runtime 会失败。
- **风险**: age secret 若使用错误 recipient 加密，部署到 axiom 后 cloudflared 无法读取凭证。

## 要点

- Root cause: 修复 XDG SSH wrapper 的 runtime expansion/quoting。
- Autossh: 给 azar 增加 host-local NixOS systemd reverse tunnel。
- Opencode: 给 axiom 增加 loopback-only systemd service。
- Cloudflared: 新建 axiom tunnel 和 hostname ingress，避免复用 charlie tunnel。
- Security: secret 只以 age 文件落盘，opencode 不直接监听公网。

## 范围

- modules/xdg.nix - SSH wrapper path expansion fix。
- hosts/azar/default.nix - azar autossh reverse SSH service and OpenSSH activation mode if needed。
- hosts/axiom/default.nix - opencode-server service and cloudflared host config。
- modules/services/cloudflared.nix - directly related Linux secret group fix required by enabling cloudflared on axiom。
- hosts/axiom/secrets/cloudflared-credentials.age - generated encrypted tunnel credentials only。
- .legion/tasks/axiom-ssh-opencode-cloudflared-fix/** - task evidence。
- .legion/wiki/** - closing writeback only。

## 非目标

- 不更改 `charlie` 现有 autossh、opencode 或 cloudflared 行为。
- 不把 opencode 直接暴露到非 loopback 地址，也不在仓库中提交明文 Cloudflare token/JSON。
- 不替用户代配 Cloudflare Access allow policy；若需要控制台操作，只记录上线前人工检查项。
- 不部署 `hey sync` / `nixos-rebuild switch` 到实体主机，除非用户另行确认。

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/rfc.md

**摘要**:
- 核心流程: 先修 SSH wrapper 的字面 $XDG_CONFIG_HOME 问题，再按现有 charlie/axiom 模式给 azar 增加独立 autossh service，最后为 axiom 建立 loopback opencode service 与 cloudflared ingress。
- 验证策略: 使用 targeted nix eval 检查 wrapper/service/ingress shape，尽可能运行 axiom/azar build；Cloudflare 登录、DNS 和 Access policy 的外部状态作为人工验证或 blocker 记录。

## 阶段概览

1. **Contract** - 创建稳定 Legion 任务契约
2. **Design** - 形成 SSH/autossh/opencode/cloudflared design-lite/RFC
3. **Implementation** - 实现 bounded dotfiles 变更并生成 cloudflared secret
4. **Verification** - 运行 targeted eval/build 与可行的 cloudflared/ssh 检查
5. **Delivery** - 完成 review、walkthrough、wiki writeback 与 PR 生命周期

---

*创建于: 2026-05-10 | 最后更新: 2026-05-10*
