#!/bin/bash
URI="http://127.0.0.1:3020"

out=`curl -s -XGET "$URI/v1/ingenico_status" -H 'Content-Type: application/json'`
echo "###> status: $out"
if [[ "$out" == *"BatchCompleted"* ]]; then
   echo "###> Batch completed, terminal is waiting to read batch data (use script clearbatch.sh)"
   exit;
fi
if [[ "$out" == *"Reconciliation needed"* ]]; then
   echo "###> Reconciliation needed, wykonaj zamkniecie dnia"
   exit;
fi 


echo "###> Starting BLIK transaction (ask eService to generate sample BLIK codes)"
curl -XPOST "$URI/v1/ingenico_transaction?fulldebug=true" -H 'Content-Type: application/json' -d '{
   "type": "purchase",
   "amount": 5000,
   "title": "Hello world",
   "sequenceNb" : "-",
   "arguments" : {
      "blikCode" : 222333
   }
}'

COUNTER=0
while [  $COUNTER -lt 150 ]; do
    let COUNTER=COUNTER+1
    out=`curl -s -XGET "$URI/v1/ingenico_status" -H 'Content-Type: application/json'`
    echo "###> status: $out"
    if [[ "$out" == *"WaitTrEnd"* ]]; then
      break;
    fi
    sleep 1
done

echo "###> Closing transaction"
curl -XGET "$URI/v1/ingenico_transaction_end" -H 'Content-Type: application/json'

echo "###> Done"
