#!/bin/bash --login

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

    CPY=$(cp -f pachctl_dir/pachctl /usr/local/bin/pachctl 2>&1)
    if [[ ! -z ${CPY} ]]; then
        IFS=: read -r -d '' -a path_array < <(printf '%s:\0' "${PATH}")
        set -o noglob
        for p in "${path_array[@]}"; do
            P_PATH="$p/pachctl"
            CPY=$(cp -f pachctl_dir/pachctl ${P_PATH} 2>&1)
            if [[ -z ${CPY} ]]; then
                break
            fi
        done
    fi
    rm -rf pachctl_dir
}

installPachctl() {
    echo -n "Pachctl..."
    if [[ $(which brew) == "" ]] ; then
        copyPachctl
        echo "force installed"
    else
        brew tap pachyderm/tap > /dev/null 2>&1
        if [[ $(which pachctl) == "" ]] ; then
            brew install pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            echo "brew installed"
        else
            if [[ "${PACHCTL_MAJOR_MINOR}" == "$(pachctl version --client-only | cut -d '.' -f -2)" ]]; then
                brew upgrade pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            else
                brew install pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            fi
            brew unlink pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            brew link --overwrite pachctl@${PACHCTL_MAJOR_MINOR} > /dev/null 2>&1
            echo "brew upgraded"
        fi
    fi
    sleep 5 # Sometimes check for pachctl fails right after brew install, so wait
    if [[ $(which pachctl) == "" ]] ; then
        abort "Pachctl not installed. Try installing \`pachctl\` manually"
    fi
}

waitForPachdReady() {
    PACH_TIMEOUT=200
    echo -n "Pachyderm run time..."
    pachctl config set active-context local
    startTime=$(date +%S)
    i=1
    sp="/-\|"
    while [[ $((pachctl version --client-only | grep pachd) 2>/dev/null) != "pachd"* ]]; do
        printf "\b${sp:i++%${#sp}:1}"
        sleep 1
        currTime=$(date +%S)
        if [[ $((10#$currTime-$startTime)) -gt 10#${PACH_TIMEOUT} ]] ; then
            printf "\b.abort\n"
            abort "Abort waiting for pachd for more than ${PACH_TIMEOUT} seconds"
        fi
    done
    printf "\b.ready!!\n"
}

installPachctl
waitForPachdReady
