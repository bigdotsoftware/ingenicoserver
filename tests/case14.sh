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


echo "###> Starting transaction"
echo ">>>>> (TESTER ACTION) SELECT NOT A DCC TRANSACTION"
curl -XPOST "$URI/v1/ingenico_transaction?fulldebug=true" -H 'Content-Type: application/json' -d '{
   "type": "purchase",
   "amount": 1051,
   "sequenceNb" : "-"
}'

COUNTER=0

while [  $COUNTER -lt 350 ]; do
    let COUNTER=COUNTER+1
    out=`curl -s -XGET "$URI/v1/ingenico_status" -H 'Content-Type: application/json'`
    echo "###> status: $out"
    if [[ "$out" == *"WaitTrEnd"* ]]; then
      break;
    fi
    sleep 1
done

echo ">>>>> (INFORMACJA DLA TESTERA) Transakcja sie udala lub nie, odczytujemy status ostatniej transakcji:"
out=`curl -s -XGET "$URI/v1/ingenico_status" -H 'Content-Type: application/json'`
echo "###> status: $out"
if [[ "$out" == *"WaitTrEnd"* ]]; then
   echo ">>>>> (INFORMACJA DLA TESTERA) Terminal oczekuja na zakonczenie transakcji.... "
   #echo "###> Closing transaction"
   curl -XGET "$URI/v1/ingenico_transaction_end" -H 'Content-Type: application/json'
fi

echo "###> Done"
