#!/usr/bin/env sh
set -ex

#
# This script setup AnalyticKit in DEV mode to do ingestion testing
#

sleep 10 # TODO: remove this. It was added as the command below often errors with 'unable to upgrade connection: container not found ("analytickit-web")'

WEB_POD=$(kubectl get pods -n analytickit -l role=web -o jsonpath="{.items[].metadata.name}")

kubectl exec "$WEB_POD" -n analytickit -- python manage.py setup_dev --no-data --create-e2e-test-plugin
