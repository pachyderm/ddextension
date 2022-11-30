#!/bin/bash

set -u

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

if [ -z "${BASH_VERSION:-}" ]
then
   abort "Bash is required to interpret this script."
fi

echo -n "Brew..."
if [[ $(command -v brew) == "" ]] ; then
    echo "installing"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ $(command -v brew) == "" ]] ; then
        echo "failed."
        abort "Brew not installed. Try installing \`brew\` manually"
    fi
else
    echo "installed"
fi

echo -n "Helm..."
if [[ $(command -v helm) == "" ]] ; then
    echo "installing"
    brew install helm
    brew link --overwrite helm 2>&1-
    if [[ $(command -v helm) == "" ]] ; then
        echo "failed"
        abort "Helm not installed. Try installing \`helm\` manually"
    fi
else
    echo "installed"
fi

echo -n "Pachctl..."
if [[ $(command -v pachctl) == "" ]] ; then
    echo "installing"
    brew install pachctl@2.4 2>-
else
    brew upgrade pachctl@2.4 2>-
    brew unlink pachctl@2.4 2>&1-
    brew link pachctl@2.4 2>&1-
    echo "upgraded"
fi

if [[ $(command -v pachctl) == "" ]] ; then
    abort "Pachctl not installed. Try installing \`pachctl\` manually"
fi

echo -n "Pachyderm..."
helm uninstall pachd 2>&1-
sleep 5
helm repo add pach https://helm.pachyderm.com 2>&1-
helm repo update pach 2>&1-
helm install pachd pach/pachyderm --set deployTarget=LOCAL --set proxy.enabled=true --set proxy.service.type=LoadBalancer --set pachd.clusterDeploymentID=my-personal-pachyderm-deployment 2>&1-
echo "deployed"

pachctl config set active-context local

while [[ $(pachctl version | grep pachd) != "pachd"* ]]; do sleep 1; done
echo "Pachyderm ready!!"
