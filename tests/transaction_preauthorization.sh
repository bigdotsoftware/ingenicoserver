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
if [[ "$out" == *"WaitTrEnd"* ]]; then
   echo "###> WaitTrEnd, finish previously opened transaction"
   exit;
fi 

echo "###> Starting preauthorization transaction"
curl -XPOST "$URI/v1/ingenico_transaction?fulldebug=true" -H 'Content-Type: application/json' -d '{
   "type": "preauthorization",
   "amount": 1000,
   "sequenceNb" : "-"
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
out=`curl -XGET "$URI/v1/ingenico_transaction_end" -H 'Content-Type: application/json'`
echo $out

#echo '{ "ansactionNumber":174,"transactionDetails":{"authorizationCode":"072760","serverMessage":""}}' | jq -r '.transactionDetails.authorizationCode'
authorizationCode=`echo $out | jq -r '.terminal.transactionDetails.authorizationCode'`
echo "###> Transaction closed with '$authorizationCode'"

if [ -z "$authorizationCode" ]; then
   echo "###> No transaction code returned, transaction refused"
else
   echo ">>>>> (AKCJA TESTERA) Wybierz akcje dla preutoryzacji $authorizationCode"
   echo ">>>>> (AKCJA TESTERA) 1) completion"
   echo ">>>>> (AKCJA TESTERA) 2) cancel"
   
   select opt in 1 2
   do
      case $opt in 1)
         out=`curl -s -XPOST "$URI/v1/ingenico_transaction?fulldebug=true" -H 'Content-Type: application/json' -d '{
            "type": "completion",
            "amount": 1000,
            "sequenceNb" : "$authorizationCode"
         }'`
         break;
      esac
      
      case $opt in 2)
         out=`curl -s -XPOST "$URI/v1/ingenico_transaction?fulldebug=true" -H 'Content-Type: application/json' -d '{
            "type": "preauthorization_cancel",
            "amount": 1000,
            "sequenceNb" : "$authorizationCode"
         }'`
         break;

      esac
   done
   
   echo $out
   
   out=`curl -s -XGET "$URI/v1/ingenico_status" -H 'Content-Type: application/json'`
   echo "###> status: $out"
   
   echo "###> Closing preauthorization_cancel or completion"
   out=`curl -XGET "$URI/v1/ingenico_transaction_end" -H 'Content-Type: application/json'`
   echo $out
fi


echo "###> Done"
