#!/bin/bash

installIstioBase() {
  helm upgrade --install istio-base istio/base \
  --values istio-base-values.yaml \
  --set defaultRevision=default \
  --namespace istio-system --create-namespace \
  --wait
}

installIstioDaemon() {
  helm install istiod istio/istiod \
  --values istiod-values.yaml \
  --set defaultRevision=default \
  -n istio-system --wait
}
