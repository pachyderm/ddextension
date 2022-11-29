#!/bin/sh

if [[ $(command -v brew) == "" ]] ; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "brew installed"
fi

if [[ $(command -v helm) == "" ]] ; then
    brew install helm
    brew link --overwrite helm
else
    echo "helm installed"
fi

if [[ $(command -v pachctl) == "" ]] ; then
    brew install pachctl@2.4
else
    brew upgrade pachctl@2.4
    brew link --overwrite pachctl@2.4
fi

helm uninstall pachd
sleep 5
helm repo add pach https://helm.pachyderm.com
helm repo update pach
helm install pachd pach/pachyderm --set deployTarget=LOCAL --set proxy.enabled=true --set proxy.service.type=LoadBalancer --set pachd.clusterDeploymentID=my-personal-pachyderm-deployment

pachctl config set active-context local

while [[ $(pachctl version | grep pachd) != "pachd"* ]]; do echo "waiting for pod" && sleep 1; done
