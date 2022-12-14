import base64
import logging

import pytest

from helpers.utils import helm_install, is_analytickit_healthy, wait_for_pods_to_be_ready

log = logging.getLogger()

HELM_INSTALL_CMD = """
helm upgrade \
    --install \
    --timeout 30m \
    -f ../../ci/values/kubetest/test_redis_internal_with_password.yaml \
    --create-namespace \
    --namespace analytickit \
    analytickit ../../charts/analytickit
"""


def test_redis_secret(kube):

    helm_install(HELM_INSTALL_CMD)
    wait_for_pods_to_be_ready(kube)

    is_analytickit_healthy(kube)

    secrets = kube.get_secrets(namespace="analytickit", fields={"type": "Opaque"})

    default_redis_secret_name = "analytickit-analytickit-redis-external"
    assert default_redis_secret_name not in secrets.keys(), "Default Redis secret found (secret name: {})".format(
        default_redis_secret_name
    )

    expected_redis_secret_name = "analytickit-analytickit-redis"
    assert expected_redis_secret_name in secrets, "Unable to find the Redis secret (secret name: {})".format(
        expected_redis_secret_name
    )
    expected_redis_secret_data = {"redis-password": base64.b64encode(b"staff-broken-apple-misplace-lamp").decode()}
    assert (
        secrets[expected_redis_secret_name].obj.data == expected_redis_secret_data
    ), "Unexpected Redis secret data (secret name: {})".format(expected_redis_secret_name)
