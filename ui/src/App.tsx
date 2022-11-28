import React from "react";
import Button from "@mui/material/Button";
import { createDockerDesktopClient } from "@docker/extension-api-client";
import { Grid, Stack, TextField, Typography } from "@mui/material";
import { updatePach } from "./helper/kubernetes";

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
      <Grid container spacing={2}>
        <Grid item>
          <Stack direction="row" alignItems="start" spacing={2} sx={{ mt: 4 }}>
            <Button
              variant="contained"
              onClick={async () => {
                setResponse("");
                const pachResult = await updatePach(ddClient);
                setResponse(pachResult);
              }}
            >
              Install Pachyderm
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
