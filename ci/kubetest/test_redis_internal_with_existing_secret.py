import logging

import pytest

from helpers.utils import (
    create_namespace_if_not_exists,
    helm_install,
    install_custom_resources,
    is_analytickit_healthy,
    wait_for_pods_to_be_ready,
)

log = logging.getLogger()

HELM_INSTALL_CMD = """
helm upgrade \
    --install \
    --timeout 30m \
    -f ../../ci/values/kubetest/test_redis_internal_with_existing_secret.yaml \
    --create-namespace \
    --namespace analytickit \
    analytickit ../../charts/analytickit
"""


def test_redis_secret(kube):
    create_namespace_if_not_exists()
    install_custom_resources("./custom_k8s_resources/redis_internal_with_existing_secret.yaml")
    helm_install(HELM_INSTALL_CMD)
    wait_for_pods_to_be_ready(kube)

    is_analytickit_healthy(kube)

    secrets = kube.get_secrets(namespace="analytickit", fields={"type": "Opaque"})

    default_redis_secret_name = "analytickit-analytickit-redis-external"
    assert default_redis_secret_name not in secrets.keys(), "Default Redis secret found (secret name: {})".format(
        default_redis_secret_name
    )

    expected_redis_secret_name = "redis-existing-secret"
    assert expected_redis_secret_name in secrets.keys(), "Expected Redis secret not found (secret name: {})".format(
        expected_redis_secret_name
    )
