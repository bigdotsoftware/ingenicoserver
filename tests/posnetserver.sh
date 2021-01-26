#!/bin/bash
  
curl -s -XGET 'http://localhost:3020/v1/ingenico_async_transaction_process?fulldebug=true' -H 'Content-Type: application/json' -d '
{
  "type": "purchase",
  "amount": "1000",
  "title": "Hello",
  "callback" :{
    "uri" : "http://myhost.pl.domain", 
    "method" : "POST"
  },
  "posnetserver" : {
    "lines": [
      { "na": "Towar 1", "il": 1.0, "vtp": "23,00", "pr": 2350 },
      { "na": "Towar 2", "il": 1.0, "vtp": "23,00", "pr": 1150 }
    ], 
    "summary": { "to": 3500 } 
  }
}

'