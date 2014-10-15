#!/bin/bash

#scripts=('/var/www/tachyon/bin/forwardd' '/var/www/tachyon/bin/process_analytics_queue.pl')
scripts=('forwardd')

for script in "${scripts[@]}"; do
  result=`ps aux | grep "$script" | grep -v "grep" | wc -l`
  if [ $result != 1 ]
  then
  echo "daemon($script) is not running"
  fi
done

