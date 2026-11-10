# MintSentinel

**An event-driven AI mint guard on Reactive Network (Omni).** A free mint fires
an event on Base Sepolia → a reactive contract on Lasna reacts → a callback
arms the gate back on Base Sepolia → an off-chain AI agent vets the mint
contract (MintGuard engine: Sourcify verification + on-chain simulation +
scoring) and posts the verdict on-chain → only SAFE mints can be claimed.
RISKY mints are blocked by the gate, on-chain, with no human in the loop.

Built for the **Reactive Omni Buildathon** (DoraHacks, Nov 5 – Dec 5 2026),
track **Reactive Meets AI**. The AI is part of the running system, not just
the tool that wrote the code: its verdict has real on-chain effect.

## The loop

```
Base Sepolia (84532)                Lasna (5318007)               Base Sepolia
┌─────────────────┐   MintRequested  ┌──────────────────┐  Callback  ┌─────────────────┐
│ SentinelMint    │ ───────────────► │ SentinelReactive │ ──────────► │ SentinelMint    │
│ requestMint()   │                  │ react() + route  │  armMint() │ status: PENDING │
└─────────────────┘                  └──────────────────┘            └────────┬────────┘
                                                                              │ AI agent
                                                                              │ vets + verdict
                                                                              ▼
                                                                     ┌─────────────────┐
                                                                     │ SAFE → claimMint│
                                                                     │ RISKY → blocked │
                                                                     └─────────────────┘
```

1. **Origin — Base Sepolia:** user calls `requestMint()` → emits
   `MintRequested(minter, tokenId, nonce)`.
2. **Reactive — Lasna:** `SentinelReactive` subscribes to `MintRequested`,
   drops replays, requests a callback via `SYSTEM.requestCallbackV_1_0`
   on `0x8888…8888` arming the gate. No off-chain watcher.
3. **Destination — Base Sepolia:** the callback calls `armMint()`, which
   records PENDING. The AI agent watches for it.
4. **AI agent (off-chain, part of the running system):** the MintGuard
   vetting engine (Sourcify verification + `eth_call` simulation + scoring)
   vets the mint contract and posts the verdict via `submitVerdict()`
   (SAFE + score, or RISKY + score + reasons).
5. **Gate enforcement:** `claimMint()` succeeds ONLY after a SAFE verdict;
   RISKY mints revert on-chain.

## Demo: two legs, same loop (proven live, recorded)

| Leg | Mint contract | Vet result | Outcome | Proof txs |
|-----|---------------|-----------|---------|-----------|
| SAFE | `SentinelMint` v2 (free, verified) | **SAFE 100** | claims successfully, NFT #0 minted | request `0x8bd32ce7…e5bd9` · verdict `0xeaf461c3…2eb1cf` · claim `0x7a166a11…885214` |
| RISKY | `SentinelMintRisky` (0.0001 ETH, verified) | **RISKY 45** | `claimMint()` reverts `BadStatus` — blocked | request `0x12d51ce4…c89994` · verdict `0x613120bd…5174d` · claim reverts |

Demo video: [`demo/MintSentinel-demo.mp4`](demo/MintSentinel-demo.mp4) — 92 s,
1920×1080, both legs on real on-chain data. End card includes the repo
URL (re-rendered 10 Nov 2026; narration and all other scenes unchanged).

Submission pack (repo link, contracts, full proof tx sets, Rakha's 4 Dec
checklist): [`SUBMIT_PACK.md`](SUBMIT_PACK.md).

## Deployed contracts (testnet, verified on Sourcify)

| Contract | Chain | Address |
|----------|-------|---------|
| SentinelMint v2 (SAFE leg) | Base Sepolia (84532) | `0x11f163d82ba0be90dca99113b44cf1cfa719bee2` |
| SentinelMintRisky (RISKY leg) | Base Sepolia (84532) | `0x161820a753adeb14b729961e71489abe2024fe4c` |
| SentinelReactiveV4 (SAFE leg) | Lasna (5318007) | `0xe5bef718142b911ac234ca524970e34d1496bc66` |
| SentinelReactiveV4 (RISKY leg) | Lasna (5318007) | `0x06869e9e1e0fad23f6e05a9c35893fdf97339f5d` |

Superseded (kept for the record in `DEBUG_LOOP.md`, do not use): the
original `SentinelMint` `0xe521…` is poisoned — a v1 `vmOnly` debt of
0.0123389 lREACT sits on its address and re-accrues on every callback
attempt, so its callbacks never deliver. The v1/v2/v3 reactives are dead
ends for the same reason; v4 adds `coverDebt()` and is always pre-funded
with 0.05 lREACT **before** any mint fires.

## The Omni lesson (why v1 died)

The first reactive contract inherited `AbstractReactive` from
`reactive-lib` v0.2.0, whose `react()` is guarded by `vmOnly`.
`detectVm()` sets `vm = (extcodesize(0xfffFfF) == 0)`. On Omni Lasna the
system contract at `0xfffFfF` **has code**, so the single deployed copy has
`vm = false` and `react()` reverts with `Error("VM only")` on every
trigger — proven on-chain (trigger tx
`0xcf5939…1b23c7cb`, Lasna block 7924555: `ReactiveContractReverted` +
`PaymentFailure` 0.0123389 REACT + `BlacklistContract`, subscription went
INACTIVE). The old dual-deployment RVM copy where `vm = true` no longer
exists post-Omni, and upstream `reactive-lib` master still ships the same
`vmOnly` code — the library pattern is broken for new Omni contracts.

**v2** does not inherit `AbstractReactive`: it subscribes directly through
the service and guards `react()` with the address the network actually
calls from — the Lasna system contract
`0x8888888888888888888888888888888888888888` (proven direct caller in the
trigger receipt) — plus the owner for manual tests. It also fixes a v1
logic bug: `lastNonce` started at 0, so the check `nonce <= lastNonce`
would have dropped mint #0 (nonce 0) even without the revert. Replay
protection is now a mapping.

## Project layout

```
src/
  SentinelMint.sol        # free mint + gate (origin & destination)
  SentinelMintRisky.sol   # paid mint + gate (RISKY leg)
  SentinelReactive.sol    # Omni-native reactive contract (v2)
  SentinelReactiveV3.sol  # v2 + requestCallbackV_1_0 (Omni callback format)
  SentinelReactiveV4.sol  # v3 + coverDebt() — the production reactive
  MinimalERC721.sol       # minimal ERC721 (no OpenZeppelin dependency)
script/
  DeployMint.s.sol        # deploy SentinelMint (Base Sepolia)
  DeployRiskyMint.s.sol   # deploy SentinelMintRisky (Base Sepolia)
  DeployReactive.s.sol    # deploy SentinelReactive (Lasna)
  DeployReactiveV3.s.sol  # deploy SentinelReactiveV3 (Lasna)
  DeployReactiveV4.s.sol  # deploy SentinelReactiveV4 (Lasna)
agent/
  agent.ts                # AI vetting agent: watch PENDING → vet → verdict
```

The vetting engine is a **dependency**, not a copy: the agent imports
`vetContract` from the MintGuard project
(`../hackathon-near-mintguard/src/vetting/`), which also powers the NEAR
Hackathon submission. MintGuard's vetting engine is chain-agnostic — the
Base Sepolia adapter (`src/vetting/adapters/base-sepolia.ts`) was added
for this project.

## Run the demo

```shell
# 1. Build
forge build

# 2. Deploy the mint (Base Sepolia) — needs a funded throwaway key
DEPLOYER_PRIVATE_KEY=$KEY forge script script/DeployMint.s.sol \
  --rpc-url https://base-sepolia-rpc.publicnode.com --broadcast

# 3. Deploy the reactive contract (Lasna) — needs lREACT for callbacks
#    (faucet: send Sepolia ETH to 0x9b9BB25f1A81078C544C829c5EB7822d747Cf434,
#    1 ETH -> 100 lREACT)
DEPLOYER_PRIVATE_KEY=$KEY MINT_ADDRESS=<mint> forge script script/DeployReactive.s.sol \
  --rpc-url https://lasna-rpc.rnk.dev/ --broadcast

# 4. Fund the reactive contract with 0.05 lREACT, then fire a test mint
cast send --rpc-url https://base-sepolia-rpc.publicnode.com \
  --private-key $KEY <mint> "requestMint()"

# 5. Run the AI agent (watches for PENDING, vets, posts the verdict)
DEPLOYER_PRIVATE_KEY=$KEY MINT_ADDRESS=<mint> \
  npx --prefix <mintguard> tsx agent/agent.ts
```

## Status

- [x] SAFE leg: react() runs, callback DELIVERED (~30 s), vet SAFE 100,
  claimMint succeeds — NFT #0 claimed (10 Nov 2026 ~01:09 WIB)
- [x] RISKY leg: callback DELIVERED, vet RISKY 45, claimMint reverts
  `BadStatus` — blocked on-chain (9 Nov 2026 ~23:49 WIB)
- [x] Full end-to-end demo (both legs) + video < 3 min
  (`demo/MintSentinel-demo.mp4`, 92 s)
- [x] Submission pack ready (`SUBMIT_PACK.md`, 10 Nov 2026) — submit target
  4 Dec 2026 (DoraHacks, track Reactive Meets AI); video must be uploaded
  to YouTube (public) at submit time
- [x] State re-verified 10 Nov 2026 ~02:40 WIB: both AI agents alive
  (SAFE tree PID 12414, RISKY tree PID 12740); `mints(0)` status 5
  (CLAIMED) score 100, `mints(4)` status 4 (RISKY) score 45; all five
  proof tx receipts status 1; RISKY claim revert re-verified read-only
  (`BadStatus`); lREACT SAFE v4 0.0348793 / RISKY v4 0.032878

See `DEBUG_LOOP.md` for the full investigation log (trigger receipt
analysis, debt/blacklist forensics, funding notes).

## License

MIT
