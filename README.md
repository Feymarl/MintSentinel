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
   drops replays, emits a `Callback` arming the gate. No off-chain watcher.
3. **Destination — Base Sepolia:** the callback calls `armMint()`, which
   records PENDING. The AI agent watches for it.
4. **AI agent (off-chain, part of the running system):** the MintGuard
   vetting engine (Sourcify verification + `eth_call` simulation + scoring)
   vets the mint contract and posts the verdict via `submitVerdict()`
   (SAFE + score, or RISKY + score + reasons).
5. **Gate enforcement:** `claimMint()` succeeds ONLY after a SAFE verdict;
   RISKY mints revert on-chain.

## Demo: two legs, same loop

| Leg | Mint contract | Vet result | Outcome |
|-----|---------------|-----------|---------|
| SAFE | `SentinelMint` (free, verified) | **SAFE 100** | claims successfully |
| RISKY | `SentinelMintRisky` (0.0001 ETH, verified) | **RISKY 45** | `claimMint()` reverts — blocked |

## Deployed contracts (testnet, verified on Sourcify)

| Contract | Chain | Address |
|----------|-------|---------|
| SentinelMint | Base Sepolia (84532) | `0xe5213387beb36e4d75020689c5694bc449122f16` |
| SentinelMintRisky | Base Sepolia (84532) | `0x161820a753adeb14b729961e71489abe2024fe4c` |
| SentinelReactive (SAFE origin) | Lasna (5318007) | `0x8ceba647e643ee72c9fc378245affc56cd901b25` |
| SentinelReactive (RISKY origin) | Lasna (5318007) | `0x46a5b6cd612787afa02424b73d02dfa6641863a5` |

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
  MinimalERC721.sol       # minimal ERC721 (no OpenZeppelin dependency)
script/
  DeployMint.s.sol        # deploy SentinelMint (Base Sepolia)
  DeployRiskyMint.s.sol   # deploy SentinelMintRisky (Base Sepolia)
  DeployReactive.s.sol    # deploy SentinelReactive (Lasna)
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

- [x] SAFE leg: react() runs, Callback emitted, vet SAFE 100
- [ ] Callback delivery → PENDING (waiting on the Reactive Signer)
- [x] RISKY leg: contract vets RISKY 45, reactive deployed + funded, test mint fired
- [ ] Full end-to-end demo (SAFE claims, RISKY blocked) + video < 3 min

See `DEBUG_LOOP.md` for the full investigation log (trigger receipt
analysis, debt/blacklist forensics, funding notes).

## License

MIT
