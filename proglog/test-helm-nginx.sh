#!/bin/bash

POD_NAME=$(kubectl get pod \
--selector=app.kubernetes.io/name=nginx \
--template '{{index .items 0 "metadata" "name" }}')

SERVICE_IP=$(kubectl get svc \
--namespace default my-nginx --template "{{ .spec.clusterIP }}")

kubectl exec $POD_NAME curl $SERVICE_IP