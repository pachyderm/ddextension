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
    if [[ -z "$(pachctl list repo | cut -f 1 -d ' ' | grep -w images)" ]]; then
        downloadLocal
        pachctl create repo images
        pachctl create pipeline -f edges.json
        pachctl create pipeline -f montage.json
        pachctl put file images@master -i images.txt
        pachctl put file images@master -i images2.txt
        cleanLocal
        echo "Started image processing example"
    else
        echo "Image processing already running"
    fi
}

runOpenCV
