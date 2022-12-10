import React from "react";
import Button from "@mui/material/Button";
import { createDockerDesktopClient } from "@docker/extension-api-client";
import { Grid, Stack, TextField, Typography } from "@mui/material";
import { updatePach, runImageProcessing } from "./helper/pachinstaller";
import { openBrowser } from "./helper/utils";

// Note: This line relies on Docker Desktop's presence as a host application.
// If you're running this React app in a browser, it won't work properly.
const client = createDockerDesktopClient();

function useDockerDesktopClient() {
  return client;
}

export function App() {
  const [response, setResponse] = React.useState<string | undefined>();
  const ddClient = useDockerDesktopClient();

  return (
    <>
      <Typography variant="h3">Pachyderm Installer</Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mt: 2 }}>
        Docker desktop extension for Pachyderm
      </Typography>
      <Grid container spacing={4}>
        <Grid item>
          <Stack direction="row" alignItems="start" spacing={2} sx={{ mt: 4 }}>
            <Button
              variant="contained"
              onClick={async () => {
                setResponse("installing...");
                const pachResult = await updatePach(ddClient);
                setResponse(pachResult);
              }}
            >
              Install
            </Button>
            <Button
              variant="contained"
              onClick={async () => {
                await openBrowser(ddClient, "http://localhost");
              }}
            >
              Console
            </Button>
            <Button
              variant="contained"
              onClick={async () => {
                await openBrowser(ddClient, "http://localhost:8080");
              }}
            >
              Notebook
            </Button>
            <Button
              variant="contained"
              onClick={async () => {
                setResponse("Starting image processing...");
                await openBrowser(ddClient, "http://localhost/lineage/default");
		        const runResult = await runImageProcessing(ddClient);
		        setResponse(runResult);
              }}
            >
              Image Processing
            </Button>
          </Stack>
        </Grid>
        <Grid item>
          <TextField
            label="Output"
            sx={{ width: 480 }}
            disabled
            multiline
            variant="outlined"
            minRows={5}
            value={response ?? ""}
          />
        </Grid>
      </Grid>
    </>
  );
}
