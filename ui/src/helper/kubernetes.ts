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
        let output = await ddClient.extension.host?.cli.exec("install", [
            "/windows/install-linux.sh",
        ], {
            stream: {
                onOutput(data) {
                    if (data.stdout) {
                        result = result.concat(data.stdout.toString());
                        console.log(data.stdout.toString());
                    }
                },
                splitOutputLines: false,
            },
        });
    } catch (e: any) {
        console.error(e);
        return e?.stderr;
    }
    console.log("Pachyderm installed and context set to local\n");
    console.log(result);
    return result;
};
