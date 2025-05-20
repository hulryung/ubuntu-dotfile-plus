# ~/bin/netrate_fast.sh  (실행시간 ≒ 1-2 ms)
#!/usr/bin/env bash
IF=${1:-ens18}
STATE="/tmp/.netrate.$IF"

NOW_RX=$(< /sys/class/net/$IF/statistics/rx_bytes)
NOW_TX=$(< /sys/class/net/$IF/statistics/tx_bytes)
NOW_TS=$(date +%s)

if [[ -f $STATE ]]; then
    read LAST_TS LAST_RX LAST_TX < "$STATE"
    DT=$(( NOW_TS - LAST_TS ))
    (( DT == 0 )) && DT=1        # 보호
    printf "↓%dKB/s ↑%dKB/s" $(( (NOW_RX-LAST_RX)/1024/DT )) \
                               $(( (NOW_TX-LAST_TX)/1024/DT ))
else
    printf "↓---KB/s ↑---KB/s"
fi

printf "\n"
echo "$NOW_TS $NOW_RX $NOW_TX" > "$STATE"
