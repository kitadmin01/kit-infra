import pytest

from helpers.metrics import install_external_statsd
from helpers.utils import create_namespace_if_not_exists, install_chart, is_analytickit_healthy, wait_for_pods_to_be_ready

VALUES_YAML = """
cloud: local

externalStatsd:
  host: "external-prometheus-statsd-exporter"
  port: "9125"
"""


def test_analytickit_healthy(kube):
    create_namespace_if_not_exists()
    install_external_statsd()
    install_chart(VALUES_YAML)
    wait_for_pods_to_be_ready(kube)

    is_analytickit_healthy(kube)
