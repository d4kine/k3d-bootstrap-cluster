# Istio Service Mesh

### Precondition

Cluster has to be deployed with the *Kong Ingress Controller*.


### Installation

You can start the installation of Istio service mesh with the included shell script:

```bash
cd examples/istio
bash setup.sh
```

The following components are installed with the *setup.sh*:

- Istio HELM Chart is used to deploy Istio Service Mesh - https://istio-release.storage.googleapis.com/charts
  - Installs Istio base to namespace *istio-system*
  - Installs Istiod (daemon) to namespace *istio-system*
  - (Optional) Installs Istio Gateway to namespace *istio-ingress*
