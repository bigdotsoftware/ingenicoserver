#!/bin/bash
URI="http://127.0.0.1:3020"

echo "###> Starting reconciliation"
curl -XPOST "$URI/v1/ingenico_transaction" -H 'Content-Type: application/json' -d '{
   "type": "reconciliation"
}'

COUNTER=0
while [  $COUNTER -lt 150 ]; do
    let COUNTER=COUNTER+1
    echo "###> Checking status"
    out=`curl -s -XGET "$URI/v1/ingenico_status" -H 'Content-Type: application/json'`
    echo $out
    if [[ "$out" == *"WaitTrEnd"* ]]; then
      break;
    fi
    sleep 1
done

echo "###> Closing reconciliation"
curl -XGET "$URI/v1/ingenico_transaction_end" -H 'Content-Type: application/json'

echo "###> Done"
