import { v1 } from "@docker/extension-api-client-types";

export const DockerDesktop = "docker-desktop";
export const CurrentExtensionContext = "currentExtensionContext";
export const IsK8sEnabled = "isK8sEnabled";

export const updatePach = async (
  ddClient: v1.DockerDesktopClient
) => {
    let result = "Go to http://localhost";
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
        let output = await ddClient.extension.host?.cli.exec("install", [
            "/windows/install-linux.sh",
        ]);
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    console.log("Pachyderm installed and context set to local\n");
    return result;
};
