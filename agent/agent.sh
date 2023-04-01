#!/usr/bin/env bash
set -u

echo "Starting agent.."

chmod 666 /dev/ttyS0
echo "Starting agent.." > /dev/ttyS0

while true; do

  sleep 1

  result=$(cat /proc/interrupts | grep NMI)
  result=$(echo $result | sed 's/[^0-9]*//g')
  result=$(echo $result | sed 's/^0*//')

  if [ "$result" != "" ]; then

    echo "Received shutdown request.."
    echo "Received shutdown request.." > /dev/ttyS0

    /usr/syno/sbin/synopoweroff
    exit

  fi

done
