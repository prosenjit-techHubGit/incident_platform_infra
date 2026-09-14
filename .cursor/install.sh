#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for the incident_platform_infra Terraform repo.
# Installs pinned Terraform, tflint, and AWS CLI v2, then downloads the Terraform
# providers pinned in .terraform.lock.hcl. Safe to run repeatedly.
set -euo pipefail

TERRAFORM_VERSION="1.16.2"
TFLINT_VERSION="0.64.0"

ARCH="$(dpkg --print-architecture)" # amd64 / arm64
BIN_DIR="/usr/local/bin"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Installing base packages"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends ca-certificates curl unzip git

install_terraform() {
  if command -v terraform >/dev/null 2>&1 && \
     terraform version | head -n1 | grep -q "v${TERRAFORM_VERSION}"; then
    echo "==> Terraform ${TERRAFORM_VERSION} already installed"
    return
  fi
  echo "==> Installing Terraform ${TERRAFORM_VERSION}"
  curl -fsSL -o "${TMP_DIR}/terraform.zip" \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"
  unzip -o "${TMP_DIR}/terraform.zip" -d "${TMP_DIR}" >/dev/null
  sudo install -m 0755 "${TMP_DIR}/terraform" "${BIN_DIR}/terraform"
}

install_tflint() {
  if command -v tflint >/dev/null 2>&1 && \
     tflint --version | grep -q "${TFLINT_VERSION}"; then
    echo "==> tflint ${TFLINT_VERSION} already installed"
    return
  fi
  echo "==> Installing tflint ${TFLINT_VERSION}"
  curl -fsSL -o "${TMP_DIR}/tflint.zip" \
    "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip"
  unzip -o "${TMP_DIR}/tflint.zip" -d "${TMP_DIR}" >/dev/null
  sudo install -m 0755 "${TMP_DIR}/tflint" "${BIN_DIR}/tflint"
}

install_awscli() {
  if command -v aws >/dev/null 2>&1; then
    echo "==> AWS CLI already installed: $(aws --version 2>&1)"
    return
  fi
  echo "==> Installing AWS CLI v2"
  case "$ARCH" in
    amd64) AWS_ARCH="x86_64" ;;
    arm64) AWS_ARCH="aarch64" ;;
    *)     AWS_ARCH="x86_64" ;;
  esac
  curl -fsSL -o "${TMP_DIR}/awscliv2.zip" \
    "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip"
  unzip -o "${TMP_DIR}/awscliv2.zip" -d "${TMP_DIR}" >/dev/null
  sudo "${TMP_DIR}/aws/install" --update
}

install_terraform
install_tflint
install_awscli

echo "==> Initializing Terraform providers (no backend, no AWS calls)"
cd "$(dirname "$0")/.."
terraform init -backend=false -input=false
tflint --init || true

echo "==> Tool versions"
terraform version
tflint --version
aws --version

echo "==> Bootstrap complete"
