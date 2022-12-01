#!/bin/bash

set -u
PACHCTL_SCR="$1"
PACHCTL_VER="$2"
PACHCTL_MAJOR_MINOR=$(echo "$PACHCTL_VER" | cut -f -2 -d ".")

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

copyPachctl() {
    ARCH="$(uname -m)"
    MACH="$(uname)"
    URL=""
    if [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "X86_64" ]; then
        ARCH=amd64
    elif [ "$ARCH" == "arm"* ] || [ "$ARCH" == "Arm"* ]; then
        ARCH=arm64
    fi
    if [ "$MACH" == "Darwin" ] || [ "$MACH" == "darwin" ]; then
        URL=https://github.com/pachyderm/pachyderm/releases/download/v$PACHCTL_VER/pachctl_$PACHCTL_VER_$ARCH.zip
        curl -Ls -o pachctl.zip $URL > /dev/null 2>&1
        unzip pachctl.zip 2>&1-
        chmod +x pachctl_$PACHCTL_VER_darwin_$ARCH/pachctl
        cp pachctl_$PACHCTL_VER_$ARCH/pachctl $1
        rm -rf pachctl_$PACHCTL_VER_darwin_$ARCH pachctl.zip
    elif [ "$MACH" == "Linux" ] || [ "$MACH" == "linux" ]; then
        URL=https://github.com/pachyderm/pachyderm/releases/download/v$PACHCTL_VER/pachctl_$PACHCTL_VER_linux_$ARCH.tar.gz
        curl -Ls -o pachctl.tar.gz $URL > /dev/null 2>&1
        tar -zxf pachctl.tar.gz
        chmod +x pachctl_$PACHCTL_VER_linux_$ARCH/pachctl
        cp pachctl_$PACHCTL_VER_linux_$ARCH/pachctl $1
        rm -rf pachctl_$PACHCTL_VER_linux_$ARCH pachctl.tar.gz
    else
        abort "Cannot find $MACH for $ARCH"
    fi
}

forceInstallPachctl() {
    PACHCTL_INSTALL_PATH="$(command -v pachctl)"
    if [[ -z "$PACHCTL_INSTALL_PATH" ]]; then
        if [[ "$(touch /usr/local/bin/pachctl)" ]]; then
            IFS=: read -r -d '' -a path_array < <(printf '%s:\0' "$PATH")
            set -o noglob
            for p in "${path_array[@]}"; do
                P_PATH="$p/pachctl"
                if [[ -z "$(touch "$P_PATH")" ]]; then
                    PACHCTL_INSTALL_PATH="$P_PATH"
                    break
                fi
            done
        else
            PACHCTL_INSTALL_PATH="/usr/local/bin/pachctl"
        fi
        rm -f "$PACHCTL_INSTALL_PATH"
    fi
    copyPachctl $PACHCTL_INSTALL_PATH
}

installPachctl() {
    echo -n "Pachctl..."
    if [[ $(command -v brew) == "" ]] ; then
        forceInstallPachctl
        echo "installed"
    else
        if [[ $(command -v pachctl) == "" ]] ; then
            brew install pachctl@$PACHCTL_MAJOR_MINOR > /dev/null 2>&1
            echo "installed"
        else
            brew upgrade pachctl@$PACHCTL_MAJOR_MINOR > /dev/null 2>&1
            brew unlink pachctl@$PACHCTL_MAJOR_MINOR > /dev/null 2>&1
            brew link pachctl@$PACHCTL_MAJOR_MINOR > /dev/null 2>&1
            echo "upgraded"
        fi
    fi
    if [[ $(command -v pachctl) == "" ]] ; then
        abort "Pachctl not installed. Try installing \`pachctl\` manually"
    fi
}

waitForPachdReady() {
    pachctl config set active-context local
    startTime=$(date +%S)
    while [[ $(pachctl version | grep pachd) != "pachd"* ]] ; do
       sleep 1
       currTime=$(date +%S)
       if [[ $(($currTime-$startTime)) > 600 ]] ; then
           abort "Abort waiting for pachd for more than 600 seconds"
       fi
    done
    echo "Pachyderm ready!!"
}

installPachctl
waitForPachdReady
