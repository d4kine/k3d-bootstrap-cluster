#!/bin/bash

# bold text
bold=$(tput bold)
normal=$(tput sgr0)
yes_no="(${bold}Y${normal}es/${bold}N${normal}o)"

read_value ()
{
  read -p "${1} [${bold}${2}${normal}]: " INPUT_VALUE
  if [ "${INPUT_VALUE}" = "" ]
  then
      INPUT_VALUE=$2
  fi
}

top()
{
  echo -e "\n\n${bold}${1}${normal}\n-------------------------------------"
}

bottom()
{
  echo -e "-------------------------------------"
}

configValues ()
{
  REGISTRY_NAME=registry
  REGISTRY_PORT=5002
  REGISTRY_FLAG=$(isYes "Yes")
  read_value "Cluster Name" "${CLUSTER_NAME}"
  CLUSTER_NAME=${INPUT_VALUE}
  read_value "Number of Servers" "${SERVERS}"
  SERVERS=${INPUT_VALUE}
  read_value "Number of Agents" "${AGENTS}"
  AGENTS=${INPUT_VALUE}
  read_value "LoadBalancer HTTP Port" "${HTTP_PORT}"
  HTTP_PORT=${INPUT_VALUE}
  read_value "LoadBalancer HTTPS Port" "${HTTPS_PORT}"
  HTTPS_PORT=${INPUT_VALUE}
  read_value "Install NGINX Ingress? ${yes_no}" "${NGINX_FLAG}"
  NGINX_FLAG=$(isYes ${INPUT_VALUE})
  read_value "Install Calico Network? ${yes_no}" "${CALICO_FLAG}"
  CALICO_FLAG=$(isYes ${INPUT_VALUE})
  read_value "Deploy httpbin sample? ${yes_no}" "${HTTPBIN_SAMPLE_FLAG}"
  HTTPBIN_SAMPLE_FLAG=$(isYes ${INPUT_VALUE})
}

isYes()
{
  if [ "${1}" = "Yes" ] || [ "${1}" = "yes" ] || [ "${1}" = "Y" ]  || [ "${1}" = "y" ];
  then
    echo 1
  else
    echo 0
  fi
}

configureEtcHosts()
{
# Prepare local /etc/hosts - add container registry hostname
grep -qxF '# Local K8s registry' /etc/hosts || echo "# Local K8s registry
127.0.0.1 ${REGISTRY_NAME}-${CLUSTER_NAME}.localhost
# End of section" | sudo tee -a /etc/hosts
echo 'Created /etc/hosts entry for local registry!'
}

uninstallCluster()
{
  top "Deleting existing cluster"
  k3d cluster delete ${CLUSTER_NAME}
  bottom
}

templateConfigFile()
{
    rm -f $2 temp.yaml
  ( echo "cat <<EOF >$2";
    cat $1;
    echo "EOF";
  ) >temp.yaml
  . temp.yaml
  cat $2
  rm -f temp.yaml
}

deploySamples()
{
  # Get images to local registry
  docker pull kennethreitz/httpbin
  docker tag kennethreitz/httpbin ${REGISTRY_NAME}-${CLUSTER_NAME}.localhost:${REGISTRY_PORT}/kennethreitz/httpbin
  docker push ${REGISTRY_NAME}-${CLUSTER_NAME}.localhost:${REGISTRY_PORT}/kennethreitz/httpbin

  templateConfigFile "samples/httpbin-template.yaml" "samples/httpbin.yaml"

  # Deploy demo app
  kubectl apply -n demo -f samples/httpbin.yaml
  if (($NGINX_FLAG == 1)); then
      kubectl apply -n demo -f samples/sample-ingress-nginx.yaml
  else
      kubectl apply -n demo -f samples/sample-ingress.yaml
  fi
}