import { v1 } from "@docker/extension-api-client-types"

/**
 * openBrowser opens a URL in the host system's browser
 */
export async function openBrowser(ddClient: v1.DockerDesktopClient, url: string) {
  return ddClient.host.openExternal(url)
}

/**
 * isWindows detects if the current host system is Windows. We rely on the
 * assumption that the Electron instance will give us the right `userAgent`
 * string.
 */
export function isWindows() {
  return navigator.userAgent.match(/Windows/i)
}

/**
 * isMacOS detects if the current host system is MacOS. We rely on the
 * assumption that the Electron instance will give us the right `userAgent`
 * string.
 */
export function isMacOS() {
  return navigator.userAgent.match(/Macintosh/i)
}
