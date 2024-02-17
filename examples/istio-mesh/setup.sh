#!/bin/bash
set -o errexit

source ../../helpers.sh
source helpers.sh

GATEWAY_FLAG=No

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

echo "Installing istio base Helm chart..."
installIstioBase

echo "Installing istio kubernetes daemon Helm chart..."
installIstioDaemon

read_value "Enable Istio as default for all namespaces? ${yes_no}" "Yes"
if (($(isYes ${INPUT_VALUE}) == 1)); then
    kubectl label namespace default istio-injection=enabled
fi

read_value "Install Istio Gateway and remove nginx-ingress? ${yes_no}" "${GATEWAY_FLAG}"
GATEWAY_FLAG=$(isYes ${INPUT_VALUE})
if (($GATEWAY_FLAG == 1)); then
    kubectl create namespace istio-ingress
    helm install istio-ingressgateway istio/gateway -n istio-ingress
    helm uninstall ingress-nginx -n ingress-nginx
fi


read_value "Install demo application? ${yes_no}" "Yes"
if (($(isYes ${INPUT_VALUE}) == 1)); then
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/platform/kube/bookinfo.yaml

    if (($GATEWAY_FLAG == 1)); then
        kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/networking/bookinfo-gateway.yaml
    fi
fi


echo "Everything setup! launch the demo app at http://localhost:8080/