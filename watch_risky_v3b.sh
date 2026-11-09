#!/bin/bash
# Poll risky v3 reactive + risky mint #1 until RISKY verdict (status 4) or 8 checks (~16 min).
export PATH="$HOME/.foundry/bin:$PATH"
V3=0xb899f2E139C227B78b10d09B70d10b7A63bB4B8A
MINT=0x161820a753adeb14b729961e71489abe2024fe4c
LOG=watch_risky_v3b.log
for i in $(seq 1 8); do
  ts=$(date '+%H:%M:%S')
  ln=$(cast call --rpc-url https://lasna-rpc.rnk.dev/ $V3 "lastNonce()" 2>/dev/null)
  rt=$(cast call --rpc-url https://lasna-rpc.rnk.dev/ $V3 "routed(uint256)" 2 2>/dev/null)
  st=$(cast call --rpc-url https://base-sepolia-rpc.publicnode.com $MINT "mints(uint256)(address,uint256,uint256,uint8)" 2 2>/dev/null | sed -n 2p)
  echo "[$ts] check $i: lastNonce=$ln routed(1)=$rt risky_mint2_status=$st" | tee -a $LOG
  if [ "$st" = "4" ]; then echo "[$ts] RISKY VERDICT REACHED (mint2)" | tee -a $LOG; exit 0; fi
  sleep 120
done
echo "[$(date '+%H:%M:%S')] watch done, risky mint still not RISKY" | tee -a $LOG
