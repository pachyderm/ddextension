import { v1 } from "@docker/extension-api-client-types";
import { isWindows } from "./utils"

export const DockerDesktop = "docker-desktop";
export const CurrentExtensionContext = "currentExtensionContext";
export const IsK8sEnabled = "isK8sEnabled";
export const pachVersion = "2.4.1";

const installPach = async (
    ddClient: v1.DockerDesktopClient,
    helmbin: string,
) => {
    var result = new String("");
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "uninstall",
            "pachd",
        ]);
    } catch (e: any) {
        if (e.stderr !== "Error: uninstall: Release not loaded: pachd: release: not found\n") {
            console.error(e);
            return e?.stderr;
        }
    }
    result = result.concat("[uninstall] pachyderm...done\n");
    console.log("Pach install clean\n");
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
            return e?.stderr;
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
        return e?.stderr;
    }
    result = result.concat("[update] pachyderm helm repo...done\n");
    console.log("Helm update repo (pach)\n");
    try {
        let out = await ddClient.extension.host?.cli.exec(helmbin, [
            "install",
            "pachd",
            "pach/pachyderm",
            "--version",
            pachVersion,
            "--set deployTarget=LOCAL",
            "--set proxy.enabled=true",
            "--set proxy.service.type=LoadBalancer",
            "--set pachd.clusterDeploymentID=my-personal-pachyderm-deployment",
        ]);
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    result = result.concat("[install] pachyderm local deployment...done\n");
    console.log("Pachyderm installed\n");
    return result;
};

export const updatePach = async (
  ddClient: v1.DockerDesktopClient
) => {
    let run = "run.sh";
    let helmbin = "helm";
    let kcbin = "kubectl";
    var result = new String("Go to http://localhost\n\n");
    result = result.concat("Operations logs...\n");
    if (isWindows()) {
        run = "run.ps1";
        helmbin = "helm.exe";
        kcbin = "kubectl.exe";
    }
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
    try {
       let output = await installPach(ddClient, helmbin);
       result = result.concat(output);
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    try {
        let output = await ddClient.extension.host?.cli.exec(run, [
            pachVersion,
        ]);
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    result = result.concat("[install] pachctl...done\n");
    console.log("Pachctl installed and context set to local\n");
    console.log(result);
    return result;
};


export const runImageProcessing = async (
  ddClient: v1.DockerDesktopClient
) => {
    let run = "runexample.sh";
    var result = new String("Navigate to the default project in Console to see image processing\n\n");
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
