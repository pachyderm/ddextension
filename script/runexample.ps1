#!/bin/bash

Invoke-WebRequest https://raw.githubusercontent.com/pachyderm/ddextension/main/script/$1 -OutFile imageprocessing.sh
wsl -e ./imageprocessing.sh $args
