# MIRA GitHub Actions runner image

Custom Docker image for MIRA-owned local/self-hosted GitHub Actions runner containers.

It packages:

- GitHub Actions runner `2.335.1`
- Docker CLI/daemon client tooling for jobs that use the host Docker socket
- Rust/native build prerequisites used by current private CI workloads: `build-essential`, `pkg-config`, `libssl-dev`, `cmake`, `protobuf-compiler`, Python venv support, and common archive/network tools
- A small entrypoint that keeps runner state in a mounted persistent directory and waits for a short-lived GitHub registration token file when not yet configured

Published image:

```text
ghcr.io/mira-hashedreality/mira-github-actions-runner:latest
ghcr.io/mira-hashedreality/mira-github-actions-runner:2.335.1
```

## Local build

```bash
docker build \
  --build-arg RUNNER_VERSION=2.335.1 \
  -t ghcr.io/mira-hashedreality/mira-github-actions-runner:2.335.1 \
  ./github-actions-runner
```

## Compose usage

Use one image for multiple repo-scoped runners; keep separate runner state/work/secrets directories per service.

```yaml
services:
  github-actions-runner:
    image: ghcr.io/mira-hashedreality/mira-github-actions-runner:latest
```

The container intentionally does **not** bake in runner registration credentials. Registration uses a short-lived `registration.env` bind mount consumed and deleted by the entrypoint.
