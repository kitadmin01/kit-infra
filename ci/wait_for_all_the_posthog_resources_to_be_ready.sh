#!/usr/bin/env sh
#
# This script waits for all AnalyticKit resources in k8s to be ready
#
echo "Waiting for jobs to be ready..."
while ! kubectl -n analytickit wait --for=condition=Complete jobs --all --timeout 10s > /dev/null 2>&1; do
    sleep 1
done
echo "All jobs are now ready!"

echo "Waiting for all deployments to be ready..."
for deployment in $(kubectl -n analytickit get deployments --no-headers -o custom-columns=NAME:.metadata.name)
do
    while ! kubectl -n analytickit rollout status deployment "$deployment" > /dev/null 2>&1; do
        sleep 1
    done
done
echo "All deployments are now ready!"
