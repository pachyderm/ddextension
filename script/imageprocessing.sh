#!/bin/bash

set -u

downloadLocal() {
    curl -Ls -o edges.json https://raw.githubusercontent.com/pachyderm/pachyderm/master/examples/opencv/edges.json
    curl -Ls -o montage.json https://raw.githubusercontent.com/pachyderm/pachyderm/master/examples/opencv/montage.json
    curl -Ls -o images.txt https://raw.githubusercontent.com/pachyderm/pachyderm/master/examples/opencv/images.txt
    curl -Ls -o images2.txt https://raw.githubusercontent.com/pachyderm/pachyderm/master/examples/opencv/images2.txt
}

cleanLocal() {
    rm -f edges.json montage.json images.txt images2.txt
}

runCreatePipeline() {
    if [[ -z "$(pachctl list repo | cut -f 1 -d ' ' | grep -w $1)" ]]; then
        pachctl create pipeline -f $2
	echo "[Create] Edges pipeline and repo"
    else
	echo "[Skip] Edges pipeline and repo exists"
    fi
}

runCreateRepo() {
    if [[ -z "$(pachctl list repo | cut -f 1 -d ' ' | grep -w $1)" ]]; then
        pachctl create repo $1
	echo "[Create] $1 repo"
    else
	echo "[Skip] $1 repo exists"
    fi
}

runAddiFile() {
    if [[ -z "$(pachctl list file $1 | grep -w $3)" ]]; then
        pachctl put file $1 -i $2
	echo "[Add] Add files from $2 to $1 repo"
    else
	echo "[Skip] Files in $2 already exists in $1 repo"
    fi
}

runOpenCV() {
    downloadLocal

    runCreateRepo images
    sleep 2
    runCreatePipeline edges edges.json
    sleep 2
    runCreatePipeline montage montage.json
    sleep 2
    runAddiFile images@master images.txt "$(cat images.txt | cut -d '/' -f 4 | head -1)"
    sleep 2
    runAddiFile images@master images2.txt "$(cat images2.txt | cut -d '/' -f 4 | head -1)"

    echo "Started processing images"
    cleanLocal
}

runOpenCV
