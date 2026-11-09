#!/bin/bash
# Poll v3 reactive + mint #3 until PENDING (status 2) or 8 checks (~16 min).
export PATH="$HOME/.foundry/bin:$PATH"
V3=0xa2b63c8e2f3530379aca441cd8c59bd84b6bd692
MINT=0xe5213387beb36e4d75020689c5694bc449122f16
LOG=watch_v3.log
for i in $(seq 1 8); do
  ts=$(date '+%H:%M:%S')
  ln=$(cast call --rpc-url https://lasna-rpc.rnk.dev/ $V3 "lastNonce()" 2>/dev/null)
  rt=$(cast call --rpc-url https://lasna-rpc.rnk.dev/ $V3 "routed(uint256)" 3 2>/dev/null)
  st=$(cast call --rpc-url https://base-sepolia-rpc.publicnode.com $MINT "mints(uint256)" 3 2>/dev/null | head -1)
  echo "[$ts] check $i: lastNonce=$ln routed(3)=$rt mint3_status=$st" | tee -a $LOG
  if echo "$st" | grep -q "2$"; then echo "[$ts] PENDING REACHED" | tee -a $LOG; exit 0; fi
  sleep 120
done
echo "[$(date '+%H:%M:%S')] watch done, still not PENDING" | tee -a $LOG
