#!/bin/bash
  
echo "###> Starting sttaus checker"
i=1
while [ $i -le 50 ]
do
  #echo Iteration: $i
  out=`curl -s -XGET 'http://127.0.0.1:3020/v1/ingenico_status' -H 'Content-Type: application/json'`
  echo $out
  let "i+=1" 
  sleep 1
done

echo "###> Done"
