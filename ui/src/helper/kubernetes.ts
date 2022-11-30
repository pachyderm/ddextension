import { v1 } from "@docker/extension-api-client-types";

export const DockerDesktop = "docker-desktop";
export const CurrentExtensionContext = "currentExtensionContext";
export const IsK8sEnabled = "isK8sEnabled";

export const updatePach = async (
  ddClient: v1.DockerDesktopClient
) => {
    var result = new String("Go to http://localhost\n\n");
    result = result.concat("Operations logs...\n");
    try {
        let output = await ddClient.extension.host?.cli.exec("kubectl", [
            "cluster-info",
            "--request-timeout",
            "2s",
        ]);
    } catch (e: any) {
        console.log("Kubernetes not enabled");
        return "Go to Settings -> Kubernetes -> Enable";
    }
    console.log("Kubernetes enabled\n");
    try {
        let out = await ddClient.extension.host?.cli.exec("helm", [
            "uninstall",
            "pachd",
        ]);
    } catch (e: any) {
        if (e.stderr !== "Error: uninstall: Release not loaded: pachd: release: not found\n") {
            console.error(e);
            return e?.stderr;
        }
    }
    console.log("Pach install clean\n");
    try {
        let out = await ddClient.extension.host?.cli.exec("helm", [
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
    console.log("Helm add repo (pach)\n");
    try {
        let out = await ddClient.extension.host?.cli.exec("helm", [
            "repo",
            "update",
            "pach",
        ]);
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    console.log("Helm update repo (pach)\n");
    try {
        let out = await ddClient.extension.host?.cli.exec("helm", [
            "install",
            "pachd",
            "pach/pachyderm",
            "--set",
            "deployTarget=LOCAL",
            "--set",
            "proxy.enabled=true",
            "--set proxy.service.type=LoadBalancer",
            "--set pachd.clusterDeploymentID=my-personal-pachyderm-deployment",
        ]);
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    console.log("Pachyderm installed\n");
    try {
        let output = await ddClient.extension.host?.cli.exec("install", [
            "/windows/install-linux.sh",
        ]);
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    console.log("Pachyderm installed and context set to local\n");
    console.log(result);
    return result;
};
