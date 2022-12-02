<p align="center">
	<img src='./Pachyderm_Icon-01.svg' height='225' title='Pachyderm Docker Desktop Extension'>
</p>

# Intro
Docker desktop is supported on all platfrom -- Linux, Mac, and Windows. It also has the AMD64 and ARM64 version. This enables the ONE click deployment of Pachyderm on personal comuters.

Ideal state of our getting started doc.
## Mac/Linux
- Install Docker Desktop with k8s enabled
- Click Extension -> Pachyderm -> Install

## Windows
- Install Docker Desktop with WSL2 and k8s enabled
- Click Extension -> Pachyderm -> Install

Happy Paching!!!

- http://localhost for Console
- type `pachctl version` on your terminal

# Current state
- Works on amd64 Mac
- [TODO] Need a arm64 mac to build and test
- [TODO] Need to test amd64 Linux should also be similar amd64 Mac
- [TODO] Need to test on Windows - it is mostly figuring out how to install pachctl on Windows (rest should work)
- [TODO] Need to add linux/arm64 in Makefile to build arm support (takes too long to build) (Update to use buildx and specify --platform)
- [TODO] Testing story is still open
- [TODO] Lots of UI improvements -- eg. change from Install to Upgrade (if extension is already installed)
- [TODO] Need a way to know the latest pach release -- right now there is no easy way to know the latest stable/ga release. k8s checks in a stable.txt in their repo, which can be pulled by anyone. Good way to keep the community to the latest release.

# How to install extension?
- Install Docker Desktop on your machine
- Clone this repo
- `make install-extension` or `make update-extension` (if already installed)
- "Pachyderm" should show up in you Docker Desktop Dashboard
- Check "Pachyderm" -> "Install"
- Wait for instructions to connect to Console



# What's is the extension doing?
- Installs helm, kubectl in the installer (so we don't need to have this on the host)
- helm uninstall/install for a LOCAL deployment
- installs pachctl on the host (uses brew if available otherwise puts it into a bin path)
- setup the context to local
- waits for pachd to be functional before returing to the user
