# Prometheus Operator Helm Chart Deployment

Deploys [Prometheus Operator](https://github.com/coreos/prometheus-operator) using the [Helm Chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator).

## Deploying Prometheus BOSH Exporter

1. Download and push the [bosh-exporter](https://hub.docker.com/r/boshprometheus/bosh-exporter) docker image

```bash
./push-image.sh
```

1. Deploy the [bosh-exporter](https://github.com/bosh-prometheus/bosh_exporter)

```bash
./deploy-bosh-exporter.sh monitoring opsman-hostname opsman-username opsman-password
```

1. Install Prometheus

```bash
./install.sh
```
