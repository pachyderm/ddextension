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

pachctl config set active-context local

while [[ $(pachctl version | grep pachd) != "pachd"* ]]; do sleep 1; done
echo "Pachyderm ready!!"
