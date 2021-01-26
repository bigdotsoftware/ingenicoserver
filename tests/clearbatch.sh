#!/bin/bash
  
echo "###> Performing 5 iterations"
i=1
while [ $i -le 5 ]
do
  echo Iteration: $i
  curl -s -XGET 'http://127.0.0.1:3020/v1/ingenico_transaction_recon_info' -H 'Content-Type: application/json'
  curl -s -XGET 'http://127.0.0.1:3020/v1/ingenico_status' -H 'Content-Type: application/json'
  let "i+=1" 
done

echo "###> Done"
