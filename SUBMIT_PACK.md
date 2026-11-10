# MintSentinel — DoraHacks Submission Pack

**Event:** Reactive Omni Buildathon (DoraHacks) — track **Reactive Meets AI** (winner-take-all, 1st place $1,000 in REACT)
**Project:** MintSentinel — event-driven AI mint guard
**Submit target: 4 Dec 2026** (deadline 5 Dec 2026 / DoraHacks page: 6 Dec 2026 03:00 WIB)
**Pack prepared:** 10 Nov 2026. Every hash/address below was re-verified on-chain on 10 Nov 2026 (cast, Base Sepolia RPC `base-sepolia-rpc.publicnode.com`, Lasna RPC `lasna-rpc.rnk.dev`) or is quoted from `DEBUG_LOOP.md` where marked "recorded".

## 1. Repo (public)

https://github.com/Feymarl/MintSentinel — public, default branch `master`, 7 commits (seed + 6). Verified live 10 Nov 2026.

## 2. Contracts

All on testnet. No mainnet anywhere.

| Role | Chain | Address | Deploy tx |
|---|---|---|---|
| SentinelMint v2 — SAFE mint (ACTIVE, video leg) | Base Sepolia (84532) | `0x11f163d82ba0be90dca99113b44cf1cfa719bee2` | `0x69c7ba7278264da9b1b6241dbb2e0ae1ef34046bce562f41a29d50748660aed6` (recorded) |
| SentinelMintRisky — RISKY mint (ACTIVE, video leg) | Base Sepolia (84532) | `0x161820a753adeb14b729961e71489abe2024fe4c` | `0xc70a02510a460047266223ba349f8d6a102584e8dcfa8d81312351cdb1d124c5` (recorded) |
| SentinelReactiveV4 — SAFE reactive | Lasna (5318007) | `0xe5bef718142b911ac234ca524970e34d1496bc66` | `0xc3a96239ee7e9d9ef2653c52fb4ff15c14b7fb348eae14c33a9095a4bad35f2e` (recorded) |
| SentinelReactiveV4 — RISKY reactive | Lasna (5318007) | `0x06869e9e1e0fad23f6e05a9c35893fdf97339f5d` | `0xe341ea2b0fc312f5ef18d906f3f7e88d3c6191c0cfd6fb8028ff6f727b31f28e` (recorded) |
| Callback proxy (Reactive network) | Base Sepolia (84532) | `0x476F44b11F5C942c58f4c8E3d0300E5710743585` | — |
| System contract (callbacks) | Lasna (5318007) | `0x8888888888888888888888888888888888888888` | — |

Both mint contracts are **Sourcify-verified** (exact_match). Both v4 reactives were **pre-funded with 0.05 lREACT BEFORE any mint** and include `coverDebt()`. Only ONE reactive is subscribed to each mint.

**lREACT balances re-verified 10 Nov 2026:** SAFE v4 `0.0348793`, RISKY v4 `0.032878`.

⚠️ **DO NOT USE the old mint `0xe5213387beb36e4d75020689c5694bc449122f16`** — poisoned by the v1 `vmOnly` debt (0.0123389 lREACT); its callbacks never deliver and its tokens #0–#9 are orphaned. Its v3-era proof runs remain valid history only.

## 3. Proven loop — full tx-hash sets (both legs)

### SAFE leg — fresh mint #0 (tokenId 0, nonce 0), 10 Nov ~01:09 WIB

| Step | Tx hash | Block | On-chain evidence (re-verified 10 Nov) |
|---|---|---|---|
| requestMint | `0x8bd32ce76fae97797c0cc28f530441ad770f813de260b1c29c4c53a4046e5bd9` | 56629114 | status 1; MintRequested log (minter 0xa9Fc…, tokenId 0, nonce 0) |
| Callback → agent verdict SAFE 100 | `0xeaf461c3688da43d54cdbf91b8125bdd1a283d7928393cb0340b573e182eb1cf` | 56629241 | status 1; VerdictSubmitted log: "SAFE 100: verified=true exact=true price=0 sim=ok" |
| claimMint(0) SUCCESS | `0x7a166a1180f28170f66cbc02f0a26be9b6c5c3ee38e24ed5e05bb933af885214` | 56629403 | status 1; Transfer log (0x0 → deployer, tokenId 0) + MintClaimed |

Final state re-verified 10 Nov: `mints(0)` = status **5 (CLAIMED)**, score **100**; `ownerOf(0)` = deployer `0xa9Fc6461303EC7DA70A4faA7820a63EeB9c952da`. Callback delivered ~30 seconds after the mint.

### RISKY leg — mint #4 (tokenId 4, nonce 4), 9 Nov ~23:49 WIB

| Step | Tx hash | Block | On-chain evidence (re-verified 10 Nov) |
|---|---|---|---|
| requestMint (paid 0.0001 ETH) | `0x12d51ce4f7cf46cf171ed57ebb2349f2da53257b8454174b5810b34063c89994` | 56605431 | status 1; MintRequested log (tokenId 4, nonce 4) |
| Callback → agent verdict RISKY 45 | `0x613120bdccf8338240650144aab6cf6270d00ff912f5d12ed7e93751b635174d` | 56605493 | status 1; VerdictSubmitted log: "RISKY 45: … price=100000000000000 sim=FAIL:pay mint price" |
| claimMint(4) REVERTED | — (no tx: reverts at estimation) | — | Read-only `cast call claimMint(4)` re-verified 10 Nov: **"execution reverted: BadStatus"** (`0x5c975bda`) — the gate blocks risky mints on-chain |

Final state re-verified 10 Nov: `mints(4)` = status **4 (RISKY)**, score **45**.

## 4. Demo video

- File: `demo/MintSentinel-demo.mp4` — **92.1 s**, 1920×1080 30 fps, H.264 + AAC, ~13.3 MB. Re-verified 10 Nov (ffprobe + end-card frames inspected; audio mean −29.0 dB, max −5.8 dB).
- **End card now includes the repo URL** `github.com/Feymarl/MintSentinel` (re-rendered 10 Nov; narration and all other scenes unchanged).
- **At submit time the video must be uploaded to YouTube as a PUBLIC link** (DoraHacks requires a video link, <3 min — ours is 92 s). Upload it from Rakha's YouTube account and paste the link into the form. The mp4 file itself is NOT the submission.

## 5. How the loop works (for the form description)

1. User calls `requestMint()` on Base Sepolia → emits `MintRequested(minter, tokenId, nonce)`.
2. `SentinelReactive` on Lasna subscribes; `react()` requests a callback via `SYSTEM.requestCallbackV_1_0` on `0x8888…8888` (the Omni pattern — the legacy Callback event is deprecated and fails on Lasna).
3. Callback calls `armMint()` on Base Sepolia → status PENDING.
4. The AI agent (MintGuard vetting engine — Sourcify + on-chain simulation + scoring) vets the mint contract and posts the verdict on-chain via `submitVerdict()` (SAFE + score, or RISKY + score).
5. `claimMint()` succeeds ONLY after a SAFE verdict; RISKY mints revert `BadStatus` on-chain.

The AI is part of the running system (it vets every mint live), not just a code-writing tool. MintGuard's engine is a dependency; the reactive contracts, gate, and agent wiring are new work built during the event.

## 6. Checklist — what Rakha must do himself on 4 Dec

- [ ] Log into **his DoraHacks account** (the submitter; I cannot submit for him).
- [ ] Open the Reactive Omni Buildathon submission form; pick track **Reactive Meets AI**.
- [ ] Paste the repo link: https://github.com/Feymarl/MintSentinel
- [ ] Paste the contract addresses from §2 (fresh SAFE mint v2, RISKY mint, both v4 reactives).
- [ ] Paste the tx hashes from §3 (both legs, full sets).
- [ ] Upload `demo/MintSentinel-demo.mp4` to **YouTube (public)** and paste the video link.
- [ ] Write the project description (use §5; keep it short — the loop, the two outcomes, the AI vetting).
- [ ] Submit and confirm the submission went through (screenshot the confirmation).

## 7. Still open before 4 Dec

- **YouTube upload** — only at submit time (needs his account).
- **DoraHacks form fields** — the exact form is only visible when submitting; if it asks for anything not in this pack (e.g. a deployed-app URL), tell me and I'll prepare it.
- **Agents stay running** — both AI vetting agents (SAFE on fresh mint v2, RISKY on 0x1618…) are alive as of 10 Nov ~02:40 WIB; they only act if a new mint goes PENDING. No further on-chain action is needed before submit. If a VM restart kills them, relaunch per `DEBUG_LOOP.md` (agent relaunch pattern) — they are NOT required for the submission itself, which rests on the already-recorded proof runs.
- **Repo must stay public** through judging; do not push unrelated changes to `master` before submit (the submitted snapshot should stay clean).
