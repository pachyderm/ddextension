#!/bin/bash --login

set -u
curl -s https://raw.githubusercontent.com/pachyderm/ddextension/main/script/install.sh | bash -s "$@"
