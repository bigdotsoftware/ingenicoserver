#!/bin/bash
URI="http://127.0.0.1:3020"

echo "###> Closing transaction"
curl -XGET "$URI/v1/ingenico_transaction_end" -H 'Content-Type: application/json'

echo "###> Done"
