import { v1 } from "@docker/extension-api-client-types";

export const DockerDesktop = "docker-desktop";
export const CurrentExtensionContext = "currentExtensionContext";
export const IsK8sEnabled = "isK8sEnabled";

export const listHostContexts = async (ddClient: v1.DockerDesktopClient) => {
  const output = await ddClient.extension.host?.cli.exec("kubectl", [
    "config",
    "view",
    "-o",
    "jsonpath='{.contexts}'",
  ]);
  console.log(output);
  if (output?.stderr) {
    console.log(output.stderr);
    return output.stderr;
  }

  return output?.stdout;
};

export const setDockerDesktopContext = async (
  ddClient: v1.DockerDesktopClient
) => {
  const output = await ddClient.extension.host?.cli.exec("kubectl", [
    "config",
    "use-context",
    "docker-desktop",
  ]);
  console.log(output);
  if (output?.stderr) {
    return output.stderr;
  }
  return output?.stdout;
};

export const updatePach = async (
  ddClient: v1.DockerDesktopClient
) => {
  const out2 = await ddClient.extension.host?.cli.exec("helm", [
    "repo",
    "update",
  ]);
  console.log(out2);
  if (out2?.stderr) {
    return out2.stderr;
  }
  const out3 = await ddClient.extension.host?.cli.exec("helm", [
    "install",
    "pachd",
    "pach/pachyderm",
    "--set",
    "deployTarget=LOCAL",
    "--set",
    "proxy.enabled=true",
    "--set proxy.service.type=LoadBalancer",
  ]);
  console.log(out3);
  if (out3?.stderr) {
    return out3.stderr;
  }
  return "Past the following in your terminal. echo '{\"pachd_address\":\"grpc://127.0.0.1:80\"}' | pachctl config set context local --overwrite && pachctl config set active-context local"
};

export const getCurrentHostContext = async (
  ddClient: v1.DockerDesktopClient
) => {
  const output = await ddClient.extension.host?.cli.exec("kubectl", [
    "config",
    "view",
    "-o",
    "jsonpath='{.current-context}'",
  ]);
  console.log(output);
  if (output?.stderr) {
    return output.stderr;
  }
  return output?.stdout;
};

export const checkK8sConnection = async (ddClient: v1.DockerDesktopClient) => {
  try {
    let output = await ddClient.extension.host?.cli.exec("kubectl", [
      "cluster-info",
      "--request-timeout",
      "2s",
    ]);
    console.log(output);
    if (output?.stderr) {
      console.log(output.stderr);
      return "Kubernetes not enabled. Go to Settings -> Kubernetes -> Enable";
    }
    return "Kubernetes enabled";
  } catch (e: any) {
    console.log("[checkK8sConnection] error : ", e);
    return "Kubernetes not enabled. Go to Settings -> Kubernetes -> Enable";
  }
};

export const listNamespaces = async (ddClient: v1.DockerDesktopClient) => {
  const output = await ddClient.extension.host?.cli.exec("kubectl", [
    "get",
    "namespaces",
    "--no-headers",
    "-o",
    'custom-columns=":metadata.name"',
    "--context",
    "docker-desktop",
  ]);
  console.log(output);
  if (output?.stderr) {
    return output.stderr;
  }
  return output?.stdout;
};
