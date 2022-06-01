#!/usr/bin/env bash

go build -ldflags "-X main.pmh=$(echo $HASHED_PRIVATE) -X main.sf=$(echo $SOCKET_PATH)" crypto.go