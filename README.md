# Prometheus Operator Helm Chart Deployment

Deploys [Prometheus Operator](https://github.com/coreos/prometheus-operator) using the [Helm Chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator).

## Install

### Create UAA client for PKS API Monitor (Optional)

```bash
./create-pks-monitor-uaa-client.sh
```

### Create secrets for BOSH Exporter (Optional)

```bash
./create-bosh-exporter-secrets.sh
```

### Install Operator

```bash
./install.sh
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

```bash
./install.sh
```

The script will issue a command like this

```bash
helm upgrade -i --version "${version}" "${release}" \
    --namespace "${namespace}" \
    --values /tmp/overrides.yaml \
    ./charts/prometheus-operator
```

where `${version}` is the version of the chart that you want to upgrade to, and `${release}` is the name of the release that is managing the instance of the Operator that you are trying to upgrade. Although, not strictly necessary, the `--version` flag is useful for when the chart is maintained in a central Helm Chart Repository and not referenced from a local directory. In our case, the chart is located inside this git repository so the `--version` flag doesn't have any effect.

## Performing Blue/Green

How are we going to do blue/green deployments?

1. Deploy multiple replicas of Prometheus
2. Prometheus is deployed into multiple clusters... Do a canary upgrade to each Prometheus across the foundation

## Open Questions

- Since helm charts do not appear to track releases with a tag or branch in the helm git repository, how should we keep track of changes from one release to the next? After we run our upgrade-chart.sh script, the chart directory is updated with the version of the chart we download from helm repository, so we can diff all the changes in there to see what the differences are but this is a bit too low level and doesn't give us a summary or log of the changes that are going to be applied. I am wondering how other helm chart operators are dealing with this problem.
- The Prometheus Operator is sophisticated enough to handle more complex upgrade scenarios (i.e., rolling upgrades for more than 1 Prometheus instance), however, if we go a long time between upgrades then we might find ourselves having to perform a more complicated upgrade path to get us to the latest revision. This could include upgrading from current revision to multiple revisions to get to the latest release. This means there could be downtime while we perform the upgrade. In every upgrade scenario we'll want to perform some tests against the deployment to ensure the least amount of downtime. In the case where we are jumping major releases, we could have multiple instances of Prometheus running at the same time, what's known as a blue green deployment, whereby we slowly cut over traffic from the old (blue) to the new (green).  The best practice for managing a large Prometheus deployment is to have multiple instances of Prometheus scaled across clusters and federation across data centers. When there are multiple instances of Prometheus running, only one is actually being used to query metrics until there is an issue with it and then a smart proxy can be used to switch to a healthy one while the problematic instance is fixed. After the instance is fixed, it doesn't become actively used until there's an issue with the other Prometheus. In this scenario, you're not incurring much downtime as long as all the healthy Prometheus are able to handle the load. For upgrades to Prometheus, we can treat the system the same way, where we take a node down, upgrade it and bring it back up. We can bring down the nodes that are not being queried first, bring them up and do this in a round-robin fashion to minimize any loss of metrics or time that Prometheus is unable to be queried.

