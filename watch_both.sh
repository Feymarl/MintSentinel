#!/bin/bash
# Watch BOTH mints until PENDING (2) — SAFE mint #2 + RISKY mint #0.
# Polls every 2 min, up to 90 checks (~3h). Logs to watch_both.log.
# Exits early (0) when either mint reaches PENDING.
export PATH="$HOME/.foundry/bin:$PATH"
SAFE=0xe5213387beb36e4d75020689c5694bc449122f16
RISKY=0x161820a753adeb14b729961e71489abe2024fe4c
RPC=https://base-sepolia-rpc.publicnode.com
LOG=~/workspace/hackathons/mintsentinel/watch_both.log
for i in $(seq 1 90); do
  S2=$(cast call --rpc-url $RPC $SAFE "mints(uint256) returns (address,uint8,uint8,string)" 2 2>/dev/null | sed -n '2p' | tr -d ' \r')
  R0=$(cast call --rpc-url $RPC $RISKY "mints(uint256) returns (address,uint8,uint8,string)" 0 2>/dev/null | sed -n '2p' | tr -d ' \r')
  echo "$(date '+%H:%M:%S') check $i: safe2=$S2 risky0=$R0" | tee -a $LOG
  if [ "$S2" = "2" ] || [ "$R0" = "2" ]; then echo "$(date '+%H:%M:%S') PENDING REACHED (safe2=$S2 risky0=$R0)" | tee -a $LOG; exit 0; fi
  sleep 120
done
echo "$(date '+%H:%M:%S') TIMEOUT after 90 checks" | tee -a $LOG
exit 1
