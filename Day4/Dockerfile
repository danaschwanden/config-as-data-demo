FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

ENV DEBIAN_FRONTEND=noninteractive

COPY apply-replacements.yaml /demo/
COPY apply-replacements-config.yaml /demo/
COPY apply-replacements-mutator.yaml /demo/
COPY cluster-root-sync.yaml /demo/
COPY demo-root-sync.yaml /demo/
COPY cluster-role-binding.yaml /demo/
COPY config-management.yaml /demo/
COPY sa.yaml /demo/
COPY set-image-config.yaml /demo/
COPY set-image-mutator.yaml /demo/
COPY kind-cluster-with-extramounts.yaml /demo/
COPY 200_install-demo.sh /etc/workstation-startup.d/
