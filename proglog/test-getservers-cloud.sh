#!/bin/bash

# Requires the service to be deployed to the cloud

ADDR=$(kubectl get service -l app=service-per-pod -o go-template='{{range .items}}{{(index .status.loadBalancer.ingress 0).ip}}{{"\n"}}{{end}}' | head -n 1)

go run cmd/getservers/main.go -addr=$ADDR:8400