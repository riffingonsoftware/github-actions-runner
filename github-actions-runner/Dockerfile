FROM ubuntu:24.04

ARG RUNNER_VERSION=2.335.1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      docker.io \
      git \
      jq \
      libicu74 \
      libssl-dev \
      openssh-client \
      pkg-config \
      protobuf-compiler \
      python3 \
      python3-venv \
      tar \
      tzdata \
      unzip \
      zip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/actions-runner.dist \
    && cd /opt/actions-runner.dist \
    && curl -fsSL -o actions-runner.tar.gz \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && ./bin/installdependencies.sh

COPY entrypoint.sh /usr/local/bin/github-actions-runner-entrypoint
RUN chmod 0755 /usr/local/bin/github-actions-runner-entrypoint

ENTRYPOINT ["/usr/local/bin/github-actions-runner-entrypoint"]
