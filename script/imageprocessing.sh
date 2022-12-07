#!/bin/bash

set -u

downloadLocal() {
    curl -Ls -o edges.json https://raw.githubusercontent.com/pachyderm/pachyderm/master/examples/opencv/edges.json
    sleep 2
    curl -Ls -o montage.json https://raw.githubusercontent.com/pachyderm/pachyderm/master/examples/opencv/montage.json
    sleep 2
    curl -Ls -o images.txt https://raw.githubusercontent.com/pachyderm/pachyderm/master/examples/opencv/images.txt
    sleep 2
    curl -Ls -o images2.txt https://raw.githubusercontent.com/pachyderm/pachyderm/master/examples/opencv/images2.txt
}

cleanLocal() {
    rm -f edges.json montage.json images.txt images2.txt
}

runOpenCV() {
    downloadLocal
    if [[ -z "$(pachctl list repo | cut -f 1 -d ' ' | grep -w images)" ]]; then
        pachctl create repo images
	echo "[Create] Images repo"
    else
	echo "[Skip] Images repo exists"
    fi
    if [[ -z "$(pachctl list repo | cut -f 1 -d ' ' | grep -w edges)" ]]; then
        pachctl create pipeline -f edges.json
	echo "[Create] Edges pipeline and repo"
    else
	echo "[Skip] Edges pipeline and repo exists"
    fi
    if [[ -z "$(pachctl list repo | cut -f 1 -d ' ' | grep -w montage)" ]]; then
        pachctl create pipeline -f montage.json
	echo "[Create] Montage pipeline and repo"
    else
	echo "[Skip] Montage pipeline and repo exists"
    fi
    if [[ -z "$(pachctl list file images@master | grep -w `cat images.txt | cut -d '/' -f 4 | head -1`)" ]]; then
        pachctl put file images@master -i images.txt
	echo "[Add] Add one file to images repo"
    else
	echo "[Skip] File already exists in images repo"
    fi
    if [[ -z "$(pachctl list file images@master | grep -w `cat images2.txt | cut -d '/' -f 4 | head -1`)" ]]; then
        pachctl put file images@master -i images2.txt
	echo "[Add] Add two more file to images repo"
    else
	echo "[Skip] File already exists in images repo"
    fi
    echo "Started image processing example"
    cleanLocal
}

runOpenCV
