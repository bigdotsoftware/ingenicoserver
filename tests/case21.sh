#!/bin/bash
URI="http://127.0.0.1:3020"
COUNTER=0
CACTION="";

out=`curl -s -XGET "$URI/v1/ingenico_status" -H 'Content-Type: application/json'`
echo "###> status: $out"
if [[ "$out" == *"BatchCompleted"* ]]; then
   echo "###> Batch completed, terminal is waiting to read batch data (use script clearbatch.sh)"
   exit;
fi

while [ $COUNTER -lt 350 ]; do
   let COUNTER=COUNTER+1
   if [[ "$out" == *"Reconciliation needed"* ]]; then
      echo ">>>>> (AKCJA TESTERA) Reconciliation needed, wykonaj zamkniecie dnia na terminalu"
      CACTION="wait_for_recon"
   else
      if [ "$CACTION" == "wait_for_recon" ]; then
         echo "###> Wykonano zamkniecie, przechodze do rozpoczecia transakcji"
         break;
      else
         #echo ">>>>> (AKCJA TESTERA) wykonaj test nastepnego dnia aby terminal oczekiwal na zamkniecie dnia poprzedniego"
         #exit;
         break;
      fi
   fi
   sleep 1
done

echo "###> Starting transaction"
curl -XPOST "$URI/v1/ingenico_transaction?fulldebug=true" -H 'Content-Type: application/json' -d '{
   "type": "purchase",
   "amount": 1000,
   "sequenceNb" : "-"
}'

while [ $COUNTER -lt 650 ]; do
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

