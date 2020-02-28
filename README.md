# Prometheus Operator Helm Chart Deployment

Deploys [Prometheus Operator](https://github.com/coreos/prometheus-operator) using the [Helm Chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator).

## Install / Uninstall

### Install Operator

Install operator into a single cluster

```bash
./install.sh
```

Install operator into all clusters

```bash
./install-all.sh
```

### Uninstall Operator

Uninstall operator from a single cluster

```bash
./uninstall.sh
```

Uninstall operator from all clusters

```bash
./uninstall-all.sh
```

## Upgrade

To upgrade a Helm Chart you'll want to find the version of the Chart you've installed already and check to see if the `version` and `appVersion` values have changed.

The version of the Chart as well as the application it deploys is contained in the `Chart.yaml` located at the root of the [chart directory](./charts/prometheus-operator/Chart.yaml). These two versions: `version` and `appVersion`, correspond to the version of the Prometheus Helm Chart and Prometheus Operator, respectively. You'll find the latest releases of the Prometheus Operator Helm Chart [here](https://hub.helm.sh/charts/stable/prometheus-operator) and the latest releases of the Prometheus Operator [here](https://github.com/coreos/prometheus-operator/releases). You can also get the current chart details by running `helm show` or `helm inspect`.

The Operator version is always going to be behind the Chart version. A lot of work goes into maintaining the Prometheus Helm Chart, so you'll notice that there are many versions for the Chart without any changes to the Operator version.

We've created a script to make it easier to upgrade the chart. Run the following script to upgrade the chart to version `8.5.2`:

```bash
./upgrade-chart.sh 8.5.2
```

This will download a tarball of version `8.5.2` of the Chart and untar it into the local `./charts` directory, overwriting what is in that directory.

### Incremental changes

After installation, you may find yourself needing to make updates to the Prometheus Operator or Helm configuration. Similar to installing the chart, customizations are made in the form of overrides via the `--values` or `--set` options. However, instead of `helm install`, you'll use `helm upgrade`.

It's important that you make your updates using the `helm upgrade` command instead of using `kubectl` or manually editing chart resources. This is to ensure that all resources are updated appropriately.

The install script runs `helm upgrade -i` where the `-i` tells helm to install the chart if it doesn't exist.

The script will issue a command like this:

```bash
helm upgrade -i --version "${version}" "${release}" \
    --namespace "${namespace}" \
    --values /tmp/overrides.yaml \
    ./charts/prometheus-operator
```

where `${version}` is the version of the chart that you want to upgrade to, and `${release}` is the name of the release that is managing the instance of the Operator that you are trying to upgrade. Although, not strictly necessary, the `--version` flag is useful for when the chart is maintained in a central Helm Chart Repository and not referenced from a local directory. In our case, the chart is located inside this git repository so the `--version` flag doesn't have any effect.

## Pipeline

The [Concourse](https://concourse-ci.org/) CI [pipeline](./ci/pipeline.yml) runs lint, installs or upgrades the Prometheus Operator including the [bosh-exporter](./charts/prometheus-operator/charts/bosh-exporter) and [pks-monitor](./charts/prometheus-operator/charts/pks-monitor) and runs helm tests on each deployment. The upgrade pulls the latest code from `develop` and gets the latest version of the chart, then upgrades the deployment on a single cluster. If that passes all the checks, then we merge into master and the upgrade runs on all the clusters.

![alt text](pipeline.png "Concourse Pipeline")

### Setup

To create the pipeline run:

```bash
./ci/set-pipeline.sh
```

You'll need to create a [creds.yml](./ci/creds.yml.sample) file before you run this script.

## Performing Blue/Green

TBD: How are we going to do blue/green deployments?

1. Deploy multiple replicas of Prometheus
2. Prometheus is deployed into multiple clusters... Do a canary upgrade to each Prometheus across the foundation
