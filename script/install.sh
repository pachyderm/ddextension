#!/bin/bash

set -u
PACHCTL_VER="$1"
PACHCTL_MAJOR_MINOR=$(echo "${PACHCTL_VER}" | cut -f -2 -d ".")

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

copyPachctl() {
    ARCH="$(uname -m)"
    MACH="$(uname)"
    URL=""
    if [ "${ARCH}" == "x86_64" ] || [ "${ARCH}" == "X86_64" ]; then
        ARCH=amd64
    elif [ "${ARCH}" == "arm"* ] || [ "${ARCH}" == "Arm"* ]; then
        ARCH=arm64
    fi
    if [ "${MACH}" == "Darwin" ] || [ "${MACH}" == "darwin" ]; then
        URL=https://github.com/pachyderm/pachyderm/releases/download/v${PACHCTL_VER}/pachctl_${PACHCTL_VER}_darwin_${ARCH}.zip
        curl -Ls -o pachctl.zip ${URL} > /dev/null 2>&1
        unzip pachctl.zip > /dev/null 2>&1
        chmod +x pachctl_${PACHCTL_VER}_darwin_${ARCH}/pachctl
        mv pachctl_${PACHCTL_VER}_darwin_${ARCH} pachctl_dir
        rm -f pachctl.zip
    elif [ "${MACH}" == "Linux" ] || [ "${MACH}" == "linux" ]; then
        URL=https://github.com/pachyderm/pachyderm/releases/download/v$PACHCTL_VER/pachctl_${PACHCTL_VER}_linux_${ARCH}.tar.gz
        curl -Ls -o pachctl.tar.gz ${URL} > /dev/null 2>&1
        tar -zxf pachctl.tar.gz
        chmod +x pachctl_${PACHCTL_VER}_linux_${ARCH}/pachctl
        mv pachctl_${PACHCTL_VER}_linux_${ARCH} pachctl_dir
        rm -f pachctl.tar.gz
    else
        abort "Cannot find ${MACH} for ${ARCH}"
    fi

    if [[ "$(cp -f pachctl_dir/pachctl /usr/local/bin/pachctl)" -ne 0 ]]; then
        IFS=: read -r -d '' -a path_array < <(printf '%s:\0' "${PATH}")
        set -o noglob
        for p in "${path_array[@]}"; do
            P_PATH="$p/pachctl"
            if [[ "$(cp -f pachctl_dir/pachctl ${P_PATH})" -eq 0 ]]; then
		echo "COPY file to ${P_PATH}"
                break
            fi
        done
    fi
    rm -rf pachctl_dir
}

installPachctl() {
    echo -n "Pachctl..."
    if [[ $(command -v brew) == "" ]] ; then
        copyPachctl
        echo "installed"
    else
        if [[ $(command -v pachctl) == "" ]] ; then
            brew install pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            echo "installed"
        else
            if [ -L "$(command -v pachctl)" ] &&
               [ "${PACHCTL_MAJOR_MINOR}" == "$(pachctl version --client-only | cut -d '.' -f -2)" ]; then
                brew upgrade pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            else
                brew install pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            fi
            brew unlink pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            brew link --overwrite pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            echo "upgraded"
        fi
    fi
    if [[ $(command -v pachctl) == "" ]] ; then
        abort "Pachctl not installed. Try installing \`pachctl\` manually"
    fi
}

waitForPachdReady() {
    PACH_TIMEOUT=200
    pachctl config set active-context local
    startTime=$(date +%S)
    while [[ $(pachctl version | grep pachd) != "pachd"* ]] ; do
       sleep 1
       currTime=$(date +%S)
       if [[ $((10#$currTime-$startTime)) -gt 10#${PACH_TIMEOUT} ]] ; then
           abort "Abort waiting for pachd for more than ${PACH_TIMEOUT} seconds"
       fi
    done
    echo "Pachyderm ready!!"
}

installPachctl
waitForPachdReady
