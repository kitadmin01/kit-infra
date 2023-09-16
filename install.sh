ANALYTICKIT_IP=$(kubectl get --namespace analytickit ingress analytickit -o jsonpath="{.status.loadBalancer.ingress[0].ip}" 2> /dev/null)
ANALYTICKIT_HOSTNAME=$(kubectl get --namespace analytickit ingress analytickit -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2> /dev/null)
if [ -n "$ANALYTICKIT_IP" ]; then
    ANALYTICKIT_INSTALLATION=$ANALYTICKIT_IP
fi
if [ -n "$ANALYTICKIT_HOSTNAME" ]; then
    ANALYTICKIT_INSTALLATION=$ANALYTICKIT_HOSTNAME
fi

if [ ! -z "$ANALYTICKIT_INSTALLATION" ]; then
    echo -e "\n----\nYour AanalyticKit installation is available at: http://${ANALYTICKIT_INSTALLATION}\n----\n"
else
    echo -e "\n----\nUnable to find the address of your AanalyticKit installation\n----\n"
fi