import pytest

from helpers.utils import helm_install, wait_for_pods_to_be_ready

HELM_INSTALL_CMD = """
helm upgrade \
    --install \
    -f ../../ci/values/kubetest/test_analytickit_hpa_enabled.yaml \
    --timeout 30m \
    --create-namespace \
    --namespace analytickit \
    analytickit ../../charts/analytickit
"""


def test_helm_install(kube):
    helm_install(HELM_INSTALL_CMD)
    wait_for_pods_to_be_ready(kube)
