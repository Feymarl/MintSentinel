// MintSentinel AI vetting agent — watches SentinelMint for PENDING mints,
// vets the mint contract with the MintGuard engine, and posts the verdict
// on-chain via submitVerdict(). The verdict has real on-chain effect:
// claimMint() only succeeds after a SAFE verdict; RISKY mints stay blocked.
//
// Usage:
//   DEPLOYER_PRIVATE_KEY=<key> npx tsx agent/agent.ts [--once] [--token <id>]
//   --once  : process currently-PENDING mints once, then exit.
//   (default: watch loop, polls every 30s until killed.)
//   --token : only process this token id (default: scan 0..nextTokenId-1).
//
// Env: MINT_ADDRESS (default SentinelMint on Base Sepolia),
//      BASE_SEPOLIA_RPC (default publicnode), DEPLOYER_PRIVATE_KEY (required
//      for submitVerdict — the agent IS the deployer EOA for this demo).
// The vetting engine is imported from the MintGuard project (dependency,
// NOT a copy): ../../../hackathon-near-mintguard/src/vetting/verdict.js

import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { vetContract } from "../../../hackathon-near-mintguard/src/vetting/verdict.js";

const execFileAsync = promisify(execFile);

const MINT =
  process.env.MINT_ADDRESS ??
  "0xe5213387beb36e4d75020689c5694bc449122f16";
const RPC =
  process.env.BASE_SEPOLIA_RPC ?? "https://base-sepolia-rpc.publicnode.com";
const KEY = process.env.DEPLOYER_PRIVATE_KEY ?? "";
const POLL_MS = 30_000;

const args = process.argv.slice(2);
const ONCE = args.includes("--once");
const tokenIdx = args.indexOf("--token");
const ONLY_TOKEN = tokenIdx >= 0 ? Number(args[tokenIdx + 1]) : null;

const CAST =
  process.env.CAST_BIN ?? `${process.env.HOME ?? "/home/hatch"}/.foundry/bin/cast`;

async function cast(...a: string[]): Promise<string> {
  const { stdout } = await execFileAsync(CAST, a, { maxBuffer: 1 << 20 });
  return stdout.trim();
}

async function mintStatus(tokenId: number): Promise<number> {
  const out = await cast(
    "call",
    "--rpc-url",
    RPC,
    MINT,
    "mints(uint256) returns (address,uint8,uint8,string)",
    String(tokenId),
  );
  // cast prints: minter \n status \n score \n reason
  const lines = out.split("\n").map((l) => l.trim());
  return Number(lines[1]);
}

async function nextTokenId(): Promise<number> {
  const n = Number(
    await cast("call", "--rpc-url", RPC, MINT, "nextTokenId() returns (uint256)"),
  );
  if (!Number.isFinite(n)) throw new Error("nextTokenId unreadable");
  return n;
}

async function submitVerdict(
  tokenId: number,
  safe: boolean,
  score: number,
  reason: string,
): Promise<string> {
  if (!KEY) throw new Error("DEPLOYER_PRIVATE_KEY is required to submitVerdict");
  const out = await execFileAsync(
    CAST,
    [
      "send",
      "--rpc-url",
      RPC,
      "--private-key",
      KEY,
      MINT,
      "submitVerdict(uint256,bool,uint8,string)",
      String(tokenId),
      safe ? "true" : "false",
      String(score),
      reason,
    ],
    { maxBuffer: 1 << 20 },
  );
  const m = out.stdout.match(/transactionHash\s+0x[0-9a-fA-F]{64}/);
  return m ? m[0].split(/\s+/)[1] : out.stdout.trim().slice(0, 120);
}

const done = new Set<number>();

async function processToken(tokenId: number): Promise<void> {
  if (done.has(tokenId)) return;
  const status = await mintStatus(tokenId);
  // 2 = PENDING (armed by the reactive callback, awaiting AI verdict)
  if (status !== 2) return;
  console.log(`[${new Date().toISOString()}] token ${tokenId} PENDING — vetting ${MINT}...`);
  const verdict = await vetContract(MINT, { chain: "base-sepolia" });
  const safe = verdict.verdict === "SAFE";
  const reason = `${verdict.verdict} ${verdict.score}: verified=${verdict.verified} exact=${verdict.exactMatch} price=${verdict.mintPriceWei} sim=${verdict.simulationOk ? "ok" : "FAIL:" + (verdict.simulationError ?? "?")}`.slice(0, 200);
  console.log(`[${new Date().toISOString()}] token ${tokenId} verdict: ${reason}`);
  const tx = await submitVerdict(tokenId, safe, verdict.score, reason);
  console.log(`[${new Date().toISOString()}] token ${tokenId} submitVerdict tx: ${tx}`);
  done.add(tokenId);
}

async function scan(): Promise<void> {
  let ids: number[];
  try {
    ids =
      ONLY_TOKEN !== null
        ? [ONLY_TOKEN]
        : Array.from({ length: await nextTokenId() }, (_, i) => i);
  } catch (e: any) {
    // Transient RPC failure (e.g. publicnode timeout) must NOT kill the
    // watch loop — log and retry on the next poll.
    console.error(`[${new Date().toISOString()}] nextTokenId error (retry next poll): ${e?.message ?? e}`);
    return;
  }
  for (const id of ids) {
    try {
      await processToken(id);
    } catch (e: any) {
      console.error(`[${new Date().toISOString()}] token ${id} error: ${e?.message ?? e}`);
    }
  }
}

async function main(): Promise<void> {
  console.log(`MintSentinel agent watching ${MINT} (chain base-sepolia, poll ${POLL_MS / 1000}s)`);
  await scan();
  if (ONCE) return;
  for (;;) {
    await new Promise((r) => setTimeout(r, POLL_MS));
    await scan();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
