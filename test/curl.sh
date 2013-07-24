#!/bin/sh
#curl -X POST -H "Accept: application/json" -H "Content-Type: application/json" -d post.json http://localhost:3010/deploy
curl -i -H "Content-Type: application/json" -H "Accept: application/json" -X POST --data @request.json localhost:3010/deploy