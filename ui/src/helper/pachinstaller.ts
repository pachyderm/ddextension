import { v1 } from "@docker/extension-api-client-types";
import { isWindows } from "./utils"

export const DockerDesktop = "docker-desktop";
export const CurrentExtensionContext = "currentExtensionContext";
export const IsK8sEnabled = "isK8sEnabled";

const installPach = async (
    ddClient: v1.DockerDesktopClient,
    helmbin: string,
    pachver: string,
) => {
    var result: string = '';
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "repo",
            "add",
            "pach",
            "https://helm.pachyderm.com",
        ]);
    } catch (e: any) {
        if (e.stderr !== "Error: repository name (pach) already exists, please specify a different name\n") {
            console.error(e);
            return [false, e?.stderr];
        }
    }
    result = result.concat("[add] pachyderm helm repo...done\n");
    console.log("Helm add repo (pach)\n");
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "repo",
            "update",
            "pach",
        ]);
    } catch (e: any) {
        console.error(e);
        return [false, e?.stderr];
    }
    result = result.concat("[update] pachyderm helm repo...done\n");
    console.log("Helm update repo (pach)\n");
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "search",
            "repo",
            "pach/pachyderm",
            "--version",
            pachver,
        ]);
        if (out?.stdout === "No results found\n") {
            result = result.concat("[check] Did not find helm chart for ", pachver);
            console.log("Helm version not found\n");
            return [false, result];
        }
    } catch (e: any) {
        console.error(e);
        return [false, e?.stderr];
    }
    result = result.concat("[check] pachyderm helm chart...done\n");
    console.log("Pachyderm helm chart exists\n");
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "uninstall",
            "pachd",
        ]);
    } catch (e: any) {
        if (e.stderr !== "Error: uninstall: Release not loaded: pachd: release: not found\n") {
            console.error(e);
            return [false, e?.stderr];
        }
    }
    result = result.concat("[uninstall] pachyderm...done\n");
    console.log("Pach install clean\n");
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "install",
            "pachd",
            "pach/pachyderm",
            "--version",
            pachver,
            "--set deployTarget=LOCAL",
            "--set proxy.enabled=true",
            "--set proxy.service.type=LoadBalancer",
            "--set pachd.clusterDeploymentID=my-personal-pachyderm-deployment",
        ]);
    } catch (e: any) {
        console.error(e);
        return [false, e?.stderr];
    }
    result = result.concat("[install] pachyderm local deployment...done\n");
    console.log("Pachyderm installed\n");
    return [true, result];
};

const installJupyter = async (
    ddClient: v1.DockerDesktopClient,
    helmbin: string,
    pachver: string,
) => {
    var result: string = '';
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "uninstall",
            "jupyter",
        ]);
    } catch (e: any) {
        if (e.stderr !== "Error: uninstall: Release not loaded: jupyter: release: not found\n") {
            console.error(e);
            return [false, e?.stderr];
        }
    }
    result = result.concat("[uninstall] jupyter...done\n");
    console.log("Jupyter install clean\n");
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "uninstall",
            "jupyterhub",
        ]);
    } catch (e: any) {
        if (e.stderr !== "Error: uninstall: Release not loaded: jupyterhub: release: not found\n") {
            console.error(e);
            return [false, e?.stderr];
        }
    }
    result = result.concat("[uninstall] jupyterhub...done\n");
    console.log("JupyterHub install clean\n");
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "repo",
            "add",
            "jupyterhub",
            "https://jupyterhub.github.io/helm-chart/",
        ]);
    } catch (e: any) {
        if (e.stderr !== "Error: repository name (juypterhub) already exists, please specify a different name\n") {
            console.error(e);
            return [false, e?.stderr];
        }
    }
    result = result.concat("[add] juypterhub helm repo...done\n");
    console.log("Helm add repo (juypterhub)\n");
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "repo",
            "update",
            "jupyterhub",
        ]);
    } catch (e: any) {
        console.error(e);
        return [false, e?.stderr];
    }
    result = result.concat("[update] jupyterhub helm repo...done\n");
    console.log("Helm update repo (jupyterhub)\n");
    /* TODO: need a robust way to specify extraContainers[0] -- we should not be using [0]
     */
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "upgrade",
            "--cleanup-on-fail",
            "--install",
            "--version 2.0.0",
            "jupyter",
            "jupyterhub/jupyterhub",
            "-f https://raw.githubusercontent.com/pachyderm/ddextension/main/script/jupyter.yaml",
            ''.concat('--set singleuser.image.tag=v',pachver),
            ''.concat('--set singleuser.extraContainers[0].image=pachyderm/mount-server:',pachver),
        ]);
    } catch (e: any) {
        console.error(e);
        return [false, e?.stderr];
    }
    result = result.concat("[install] notebook deployment...done\n");
    console.log("Notebook installed\n");
    return [true, result];
};

export const updatePach = async (
  ddClient: v1.DockerDesktopClient,
  installVer: string,
) => {
    let run = "run.sh";
    let helmbin = "helm";
    let kcbin = "kubectl";
    var result: string = "Explore Pachyderm via Console or Notebook\n\n";
    result = result.concat("Operations logs...\n");
    /* TODO: There is likely a way to pass default parameter for installVer
     */
    var pachver = installVer;
    if (installVer === "") {
	pachver = "2.4.1";
    }
    console.log(pachver);
    if (isWindows()) {
        run = "run.ps1";
        helmbin = "helm.exe";
        kcbin = "kubectl.exe";
    }

    /* Check if k8s is enabled
     */
    try {
        let output = await ddClient.extension.host?.cli.exec(kcbin, [
            "cluster-info",
            "--request-timeout",
            "2s",
        ]);
    } catch (e: any) {
        console.log("Kubernetes not enabled");
        return "Go to Settings -> Kubernetes -> Enable";
    }
    result = result.concat("[check] kubernetes...enabled\n");
    console.log("Kubernetes enabled\n");

    /* Install Pachyderm
     */
    {
        let [done, output] = await installPach(ddClient, helmbin, pachver);
        result = result.concat(output);
        console.log(result);
        if (done === false) {
            console.log("[install] pachyerm... failed\n");
            result = result.concat("[install] pachyderm...failed\n");
            return result;
        }
    }

    /* Run script to install binary on the host. Pachctl
     */
    try {
        let output = await ddClient.extension.host?.cli.exec(run, [
            pachver,
        ]);
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    result = result.concat("[install] pachctl...done\n");

    /* Install notebook, with pach extension
     */
    {
        let [done, output] = await installJupyter(ddClient, helmbin, pachver);
        result = result.concat(output);
        console.log(result);
        if (done === false) {
            console.log("[install] Notebook... failed\n");
            result = result.concat("[install] Notebook...failed\n");
            return result;
        }
    }

    console.log("Pachyder + Pachctl + Console + Notebook installed\n");
    return result;
};

export const runImageProcessing = async (
  ddClient: v1.DockerDesktopClient
) => {
    let run = "runexample.sh";
    var result: string = "Navigate to the default project in Console to see image processing\n\n";
    if (isWindows()) {
        run = "runexample.ps1";
    }
    try {
        let output = await ddClient.extension.host?.cli.exec(run, [
            "imageprocessing.sh",
        ]);
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    result = result.concat("CLI steps to do image processing in Pachyderm...\n");
    result = result.concat("\t1. pachctl create repo images\n");
    result = result.concat("\t2. pachctl create pipeline -f edges.json\n");
    result = result.concat("\t3. pachctl create pipeline -f montage.json\n");
    result = result.concat("\t4. pachctl put file images@master -i images.txt\n");
    result = result.concat("\t5. pachctl put file images@master -i images2.txt\n");
    result = result.concat("\nAll files on GitHub: https://github.com/pachyderm/pachyderm/master/examples/opencv\n");
    console.log("Image processing example started\n");
    console.log(result);
    return result;
};
