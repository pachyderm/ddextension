Invoke-WebRequest https://raw.githubusercontent.com/pachyderm/ddextension/main/script/install.sh -OutFile pach-install.sh
wsl -e ./pach-install.sh $args
