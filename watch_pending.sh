#!/bin/bash
# Watch mint #2 status until PENDING (2) or timeout (~20 min). Logs to watch_pending.log
export PATH="$HOME/.foundry/bin:$PATH"
MINT=0xe5213387beb36e4d75020689c5694bc449122f16
RPC=https://base-sepolia-rpc.publicnode.com
LOG=~/workspace/hackathons/mintsentinel/watch_pending.log
for i in $(seq 1 10); do
  S=$(cast call --rpc-url $RPC $MINT "mints(uint256) returns (address,uint8,uint8,string)" 2 2>/dev/null | sed -n '2p' | tr -d ' \r')
  echo "$(date '+%H:%M:%S') check $i: mint2 status=$S" | tee -a $LOG
  if [ "$S" = "2" ]; then echo "$(date '+%H:%M:%S') PENDING REACHED" | tee -a $LOG; exit 0; fi
  sleep 120
done
echo "$(date '+%H:%M:%S') TIMEOUT after 10 checks, still not PENDING" | tee -a $LOG
exit 1
