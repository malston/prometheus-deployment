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

## Upgrade

To upgrade a Helm Chart you'll want to find the version of the Chart you've installed already and check to see if the `version` and `appVersion` values have changed.

The version of the Chart as well as the application it deploys is contained in the `Chart.yaml` located at the root of the [chart directory](./charts/prometheus-operator/Chart.yaml). These two versions: `version` and `appVersion`, correspond to the version of the Prometheus Helm Chart and Prometheus Operator, respectively. You'll find the latest releases of the Prometheus Operator Helm Chart [here](https://hub.kubeapps.com/charts/stable/prometheus-operator) and the latest releases of the Prometheus Operator [here](https://github.com/coreos/prometheus-operator/releases). You can also get the current chart details by running `helm show` or `helm inspect`.

The Operator version is always going to be behind the Chart version. A lot of work goes into maintaining the Prometheus Helm Chart, so you'll notice that there are many versions for the Chart without any changes to the Operator version.

We've created a script to make it easier to upgrade the chart. Run the following script to upgrade the chart to version `8.5.2`:

```bash
./upgrade-chart.sh 8.5.2
```

This will download a tarball of version `8.5.2` of the Chart and untar it into the local `./charts` directory, overwriting what is in that directory.

### Incremental changes

After installation, you may find yourself needing to make updates to the Prometheus Operator or Helm configuration. Similar to installing the chart, customizations are made in the form of overrides via the `--values` or `--set` options. However, instead of `helm install`, you'll use `helm upgrade`.

It's important that you make your updates using the `helm upgrade` command instead of using `kubectl` or manually editing chart resources. This is to ensure that all resources are updated appropriately.

We also maintain a script that allows us to run this easily with only a few parameters:

```bash
/upgrade.sh
```

The script will issue a command like this

```bash
helm upgrade --version "${version}" "${release}" \
    --namespace "${namespace}" \
    --values /tmp/overrides.yaml \
    ./charts/prometheus-operator
```

where `${version}` is the version of the chart that you want to upgrade to, and `${release}` is the name of the release that is managing the instance of the Operator that you are trying to upgrade.

