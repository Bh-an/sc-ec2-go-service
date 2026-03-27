#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR

SERVICE_IMAGE_NAME="${IMAGE_NAME:-ghcr.io/bh-an/ec2-go-service}"
readonly SERVICE_IMAGE_NAME

if [[ -t 2 ]]; then
  UI_RESET=$'\033[0m'
  UI_BOLD=$'\033[1m'
  UI_BLUE=$'\033[34m'
  UI_GREEN=$'\033[32m'
  UI_YELLOW=$'\033[33m'
  UI_RED=$'\033[31m'
  UI_CYAN=$'\033[36m'
else
  UI_RESET=""
  UI_BOLD=""
  UI_BLUE=""
  UI_GREEN=""
  UI_YELLOW=""
  UI_RED=""
  UI_CYAN=""
fi

log_line() {
  local level="$1"
  local color="$2"
  shift 2
  printf '%s[%s]%s %s\n' "${color}${UI_BOLD}" "$level" "$UI_RESET" "$*" >&2
}

section() {
  printf '\n%s%s%s\n' "${UI_BLUE}${UI_BOLD}" "== $* ==" "$UI_RESET" >&2
}

note() {
  log_line "info" "$UI_BLUE" "$*"
}

warn() {
  log_line "warn" "$UI_YELLOW" "$*"
}

success() {
  log_line "ok" "$UI_GREEN" "$*"
}

fail() {
  log_line "error" "$UI_RED" "$*"
  exit 1
}

summary_start() {
  printf '\n%s%s%s\n' "${UI_CYAN}${UI_BOLD}" "$1" "$UI_RESET" >&2
}

summary_line() {
  local key="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    value="—"
  fi
  printf '  %-18s %s\n' "${key}:" "$value" >&2
}

summary_next_step() {
  printf '  %-18s %s\n' "next:" "$1" >&2
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required tool: $1"
}

require_dir() {
  [[ -d "$1" ]] || fail "missing required directory: $1"
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

resolve_ghcr_token() {
  local token="${GHCR_TOKEN:-${GITHUB_TOKEN:-}}"
  if [[ -z "$token" ]] && command -v gh >/dev/null 2>&1; then
    token="$(gh auth token 2>/dev/null || true)"
  fi
  [[ -n "$token" ]] || fail "set GHCR_TOKEN or GITHUB_TOKEN, or authenticate gh locally"
  printf '%s' "$token"
}

resolve_github_user() {
  local user="${GHCR_USERNAME:-${GITHUB_USER:-}}"
  if [[ -z "$user" ]] && command -v gh >/dev/null 2>&1; then
    user="$(gh api user --jq .login 2>/dev/null || true)"
  fi
  [[ -n "$user" ]] || fail "set GHCR_USERNAME or GITHUB_USER, or authenticate gh locally"
  printf '%s' "$user"
}

configure_private_module_env() {
  return 0
}

check_preferred_node() {
  require_tool node
  local node_version node_major
  node_version="$(node --version | sed 's/^v//')"
  node_major="${node_version%%.*}"

  case "$node_major" in
    20|22|24)
      ;;
    *)
      fail "unsupported Node.js version: v${node_version} (supported: 20, 22, 24)"
      ;;
  esac

  if [[ "$node_major" != "22" ]]; then
    warn "Node.js 22 is the preferred local version; current version is v${node_version}"
  fi
}

current_region() {
  local region="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
  [[ -n "$region" ]] || fail "set AWS_REGION or AWS_DEFAULT_REGION"
  printf '%s' "$region"
}

require_aws_env() {
  local region
  region="$(current_region)"
  export AWS_REGION="$region"
  export AWS_DEFAULT_REGION="$region"
}

resolve_account_id() {
  require_tool aws
  require_aws_env
  aws sts get-caller-identity --query Account --output text
}

resolve_aws_arn() {
  require_tool aws
  require_aws_env
  aws sts get-caller-identity --query Arn --output text
}

require_cleanup_mode() {
  case "$1" in
    infra|full)
      ;;
    *)
      fail "cleanup mode must be one of: infra, full"
      ;;
  esac
}

resolve_backend_mode() {
  local mode="${TF_BACKEND:-${BACKEND:-s3}}"
  case "$mode" in
    s3|local)
      ;;
    *)
      fail "terraform backend must be one of: s3, local"
      ;;
  esac
  printf '%s' "$mode"
}

verify_enabled() {
  local verify_value="${VERIFY:-1}"
  case "$verify_value" in
    0|false|FALSE|no|NO)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

require_full_cleanup_confirmation() {
  local environment_name="$1"
  local confirmation="${CONFIRM:-}"
  [[ "$confirmation" == "$environment_name" ]] || fail "set CONFIRM=${environment_name} to allow full cleanup"
}

service_ami_parameter_name() {
  local environment_name="$1"
  printf '/sc/ec2-go-service/%s/ami-id' "$environment_name"
}

shared_tf_repo_dir() {
  local repo_dir="${TF_MODULE_REPO_DIR:-$ROOT_DIR/../sc-tf-service-host-module}"
  [[ -d "$repo_dir" ]] || fail "shared Terraform repo not found at ${repo_dir}; set TF_MODULE_REPO_DIR if it lives elsewhere"
  printf '%s' "$repo_dir"
}

shared_tf_packer_dir() {
  printf '%s/packer' "$(shared_tf_repo_dir)"
}

service_image_manifest_headers() {
  local image_ref="$1"
  local image_name ref manifest_path initial_headers status auth_line realm service scope token

  if [[ "$image_ref" == *"@"* ]]; then
    image_name="${image_ref%@*}"
    ref="${image_ref#*@}"
  elif [[ "$image_ref" == *":"* ]]; then
    image_name="${image_ref%:*}"
    ref="${image_ref##*:}"
  else
    fail "image reference must be a tag or digest: ${image_ref}"
  fi

  [[ "$image_name" == ghcr.io/* ]] || fail "automatic image verification only supports ghcr.io refs: ${image_ref}"
  manifest_path="${image_name#ghcr.io/}"

  initial_headers="$(
    curl -sSI \
      -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json' \
      "https://ghcr.io/v2/${manifest_path}/manifests/${ref}"
  )"
  status="$(printf '%s\n' "$initial_headers" | awk 'NR==1 {print $2}')"

  case "$status" in
    200)
      printf '%s\n' "$initial_headers"
      return 0
      ;;
    401)
      auth_line="$(printf '%s\n' "$initial_headers" | tr -d '\r' | awk 'tolower($1)=="www-authenticate:" {sub(/^[^ ]+ /, ""); print}')"
      [[ -n "$auth_line" ]] || fail "unable to negotiate GHCR auth challenge for ${image_ref}"

      realm="$(printf '%s\n' "$auth_line" | sed -n 's/.*realm="\([^"]*\)".*/\1/p')"
      service="$(printf '%s\n' "$auth_line" | sed -n 's/.*service="\([^"]*\)".*/\1/p')"
      scope="$(printf '%s\n' "$auth_line" | sed -n 's/.*scope="\([^"]*\)".*/\1/p')"
      [[ -n "$realm" && -n "$service" && -n "$scope" ]] || fail "unable to parse GHCR auth challenge for ${image_ref}"

      token="$(
        curl -fsSL "${realm}?service=${service}&scope=${scope}" |
          sed -n 's/.*"token":"\([^"]*\)".*/\1/p'
      )"
      [[ -n "$token" ]] || fail "unable to retrieve GHCR bearer token for ${image_ref}"

      curl -fsSI \
        -H "Authorization: Bearer ${token}" \
        -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json' \
        "https://ghcr.io/v2/${manifest_path}/manifests/${ref}"
      ;;
    404)
      fail "image manifest not found: ${image_ref}"
      ;;
    *)
      fail "unexpected GHCR response ${status} while resolving ${image_ref}"
      ;;
  esac
}

service_image_digest_from_ref() {
  local image_ref="$1"
  local digest
  digest="$(
    service_image_manifest_headers "$image_ref" |
      tr -d '\r' |
      awk 'tolower($1)=="docker-content-digest:" {print $2}'
  )"
  [[ -n "$digest" ]] || fail "unable to resolve digest for image: ${image_ref}"
  printf '%s' "$digest"
}

verify_service_image_ref() {
  local image_ref="$1"
  service_image_manifest_headers "$image_ref" >/dev/null
}

resolve_default_service_image() {
  local latest_ref="${SERVICE_IMAGE_NAME}:latest"
  local digest

  digest="$(service_image_digest_from_ref "$latest_ref")" || fail "unable to resolve default deploy image from ${latest_ref}; publish a latest tag or pass IMAGE explicitly"
  printf '%s@%s' "$SERVICE_IMAGE_NAME" "$digest"
}

verify_generic_image_ref() {
  local image_ref="$1"
  require_tool docker
  docker manifest inspect "$image_ref" >/dev/null 2>&1 || fail "image does not exist or is not readable: ${image_ref}"
}

resolve_deploy_image() {
  local requested_ref="${1:-}"
  local digest

  if [[ -z "$requested_ref" ]]; then
    local resolved_ref
    resolved_ref="$(resolve_default_service_image)"
    note "Using latest published service image: ${resolved_ref}"
    printf '%s' "$resolved_ref"
    return 0
  fi

  if [[ "$requested_ref" == "${SERVICE_IMAGE_NAME}"* ]]; then
    verify_service_image_ref "$requested_ref"
    if [[ "$requested_ref" == *"@"* ]]; then
      printf '%s' "$requested_ref"
      return 0
    fi

    digest="$(service_image_digest_from_ref "$requested_ref")"
    printf '%s@%s' "$SERVICE_IMAGE_NAME" "$digest"
    return 0
  fi

  verify_generic_image_ref "$requested_ref"
  printf '%s' "$requested_ref"
}

login_ghcr() {
  local user token
  require_tool docker
  user="$(resolve_github_user)"
  token="$(resolve_ghcr_token)"
  printf '%s' "$token" | docker login ghcr.io -u "$user" --password-stdin >/dev/null
}

resolve_tfstate_bucket_name() {
  local account_id region
  account_id="$(resolve_account_id)"
  region="$(current_region)"
  printf 'sc-ec2-go-service-tfstate-%s-%s' "$account_id" "$region"
}

resolve_tfstate_key() {
  local environment_name="$1"
  printf '%s/terraform.tfstate' "$environment_name"
}

ensure_tf_backend_bucket() {
  local bucket_name region
  bucket_name="$(resolve_tfstate_bucket_name)"
  region="$(current_region)"

  if aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
    note "Terraform state bucket already exists: ${bucket_name}"
  else
    note "Creating Terraform state bucket ${bucket_name}"
    if [[ "$region" == "us-east-1" ]]; then
      aws s3api create-bucket --bucket "$bucket_name" >/dev/null
    else
      aws s3api create-bucket \
        --bucket "$bucket_name" \
        --create-bucket-configuration "LocationConstraint=${region}" >/dev/null
    fi
  fi

  aws s3api put-public-access-block \
    --bucket "$bucket_name" \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
  aws s3api put-bucket-versioning \
    --bucket "$bucket_name" \
    --versioning-configuration Status=Enabled >/dev/null
  aws s3api put-bucket-encryption \
    --bucket "$bucket_name" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' >/dev/null
}

write_tf_backend_config() {
  local environment_name="$1"
  local backend_config_path="${TMPDIR:-/tmp}/sc-ec2-go-service-backend-${environment_name}.hcl"
  local bucket_name region key

  bucket_name="$(resolve_tfstate_bucket_name)"
  region="$(current_region)"
  key="$(resolve_tfstate_key "$environment_name")"

  cat >"$backend_config_path" <<EOF
bucket       = "${bucket_name}"
key          = "${key}"
region       = "${region}"
encrypt      = true
use_lockfile = true
EOF

  printf '%s' "$backend_config_path"
}

terraform_init_for_mode() {
  local environment_name="$1"
  local backend_mode="${2:-$(resolve_backend_mode)}"

  case "$backend_mode" in
    s3)
      local backend_config
      ensure_tf_backend_bucket
      backend_config="$(write_tf_backend_config "$environment_name")"
      run_in_repo infra/terraform terraform init -reconfigure -backend-config="$backend_config"
      ;;
    local)
      run_in_repo infra/terraform terraform init -backend=false
      ;;
  esac
}

validate_s3_backend_ready() {
  local bucket_name
  bucket_name="$(resolve_tfstate_bucket_name)"
  aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1 || fail "terraform state bucket is missing: ${bucket_name}; run bootstrap backend"
}

cdk_bootstrap_stack_name() {
  printf 'CDKToolkit'
}

cdk_bootstrap_missing() {
  local region stack_name
  region="$(current_region)"
  stack_name="$(cdk_bootstrap_stack_name)"
  ! aws cloudformation describe-stacks --region "$region" --stack-name "$stack_name" >/dev/null 2>&1
}

ensure_cdk_bootstrap() {
  local account_id region
  if ! cdk_bootstrap_missing; then
    note "CDK bootstrap stack is present"
    return 0
  fi

  require_tool npx
  account_id="$(resolve_account_id)"
  region="$(current_region)"
  note "Bootstrapping CDK toolkit in ${account_id}/${region}"
  run_in_repo infra/cdk npx -y aws-cdk@2 bootstrap "aws://${account_id}/${region}"
}

warn_if_cdk_bootstrap_missing() {
  if cdk_bootstrap_missing; then
    warn "CDKToolkit is not bootstrapped in $(resolve_account_id)/$(current_region); run bootstrap cdk before deploying"
  fi
}

comma_list_to_hcl_array() {
  local csv="$1"
  local result="" item
  IFS=',' read -ra parts <<<"$csv"
  for item in "${parts[@]}"; do
    item="$(printf '%s' "$item" | xargs)"
    [[ -n "$item" ]] || continue
    if [[ -n "$result" ]]; then
      result+=", "
    fi
    result+="\"${item}\""
  done
  printf '[%s]' "$result"
}

write_packer_var_file() {
  local environment_name="$1"
  local region="${2:-$(current_region)}"
  local ami_regions_csv="${AMI_REGIONS:-}"
  local ami_name_prefix="${AMI_NAME_PREFIX:-ec2-docker-host}"
  local parameter_name="${AMI_SSM_PARAMETER_NAME:-$(service_ami_parameter_name "$environment_name")}"
  local var_file_path="${TMPDIR:-/tmp}/sc-ec2-go-service-packer-${environment_name}.pkrvars.hcl"
  local ami_regions_hcl="[]"

  if [[ -n "$ami_regions_csv" ]]; then
    ami_regions_hcl="$(comma_list_to_hcl_array "$ami_regions_csv")"
  fi

  cat >"$var_file_path" <<EOF
region                 = "${region}"
ami_name_prefix        = "${ami_name_prefix}"
ami_regions            = ${ami_regions_hcl}
ami_ssm_parameter_name = "${parameter_name}"
EOF

  printf '%s' "$var_file_path"
}

delete_service_ami_parameter() {
  local environment_name="$1"
  local parameter_name="${AMI_SSM_PARAMETER_NAME:-$(service_ami_parameter_name "$environment_name")}"
  require_tool aws
  require_aws_env

  if aws ssm get-parameter --name "$parameter_name" >/dev/null 2>&1; then
    note "Deleting SSM parameter ${parameter_name}"
    aws ssm delete-parameter --name "$parameter_name" >/dev/null
  else
    warn "SSM parameter not found, skipping delete: ${parameter_name}"
  fi
}

run_in_repo() {
  local rel_dir="$1"
  shift
  (
    cd "$ROOT_DIR/$rel_dir"
    "$@"
  )
}

cdk_env_config_path() {
  local environment_name="$1"
  printf '%s/infra/cdk/environments/%s.json' "$ROOT_DIR" "$environment_name"
}

cdk_stack_name_for_env() {
  local environment_name="$1"
  local config_path stack_name
  config_path="$(cdk_env_config_path "$environment_name")"
  require_file "$config_path"
  stack_name="$(sed -n 's/.*"stackName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$config_path" | head -n1)"
  [[ -n "$stack_name" ]] || fail "unable to resolve CDK stack name from ${config_path}"
  printf '%s' "$stack_name"
}

cdk_service_endpoint_for_env() {
  local environment_name="$1"
  local stack_name
  stack_name="$(cdk_stack_name_for_env "$environment_name")"
  aws cloudformation describe-stacks \
    --region "$(current_region)" \
    --stack-name "$stack_name" \
    --query "Stacks[0].Outputs[?OutputKey=='ServiceEndpoint'].OutputValue" \
    --output text 2>/dev/null | tr -d '\r'
}

cdk_instance_id_for_env() {
  local environment_name="$1"
  local stack_name
  stack_name="$(cdk_stack_name_for_env "$environment_name")"
  aws ec2 describe-instances \
    --region "$(current_region)" \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=${stack_name}" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text 2>/dev/null | awk 'NF {print $1}'
}

terraform_output_json() {
  local name="$1"
  run_in_repo infra/terraform terraform output -json "$name" 2>/dev/null || true
}

terraform_output_text() {
  local name="$1"
  local raw
  raw="$(terraform_output_json "$name")"
  [[ -n "$raw" && "$raw" != "null" ]] || return 1

  if [[ "$raw" == \"*\" ]]; then
    raw="${raw#\"}"
    raw="${raw%\"}"
  fi
  printf '%s' "$raw"
}

terraform_public_endpoint() {
  terraform_output_text api_endpoint || true
}

terraform_public_ip() {
  terraform_output_text public_ip || true
}

terraform_instance_id() {
  terraform_output_text instance_id || true
}

terraform_exposure_kind() {
  terraform_output_text exposure_kind || true
}

terraform_has_public_endpoint() {
  terraform_output_text has_public_endpoint || true
}

terraform_ami_id() {
  terraform_output_text ami_id || true
}

normalize_endpoint_url() {
  local endpoint="$1"
  [[ -n "$endpoint" ]] || fail "endpoint is required"
  if [[ "$endpoint" == http://* || "$endpoint" == https://* ]]; then
    printf '%s' "${endpoint%/}"
  else
    printf 'http://%s' "${endpoint%/}"
  fi
}

resolve_smoke_endpoint() {
  local target="${1:-auto}"
  local environment_name="${2:-${DEPLOY_ENV:-dev}}"
  local explicit_endpoint="${3:-${ENDPOINT:-}}"
  local endpoint

  if [[ -n "$explicit_endpoint" ]]; then
    normalize_endpoint_url "$explicit_endpoint"
    return 0
  fi

  case "$target" in
    cdk)
      endpoint="$(cdk_service_endpoint_for_env "$environment_name")"
      ;;
    terraform|auto)
      endpoint="$(terraform_public_endpoint)"
      if [[ -z "$endpoint" ]]; then
        endpoint="$(terraform_public_ip)"
      fi
      ;;
    *)
      fail "smoke target must be one of: auto, cdk, terraform"
      ;;
  esac

  [[ -n "$endpoint" && "$endpoint" != "null" ]] || fail "unable to resolve a public endpoint for ${target}/${environment_name}; set ENDPOINT explicitly for private verification"
  normalize_endpoint_url "$endpoint"
}

http_status() {
  local url="$1"
  curl -sS -o /tmp/sc-ec2-go-service-http-body.$$ -w '%{http_code}' "$url"
}

read_last_http_body() {
  cat /tmp/sc-ec2-go-service-http-body.$$ 2>/dev/null || true
}

assert_http_contains() {
  local url="$1"
  local expected_status="$2"
  local expected_fragment="$3"
  local label="$4"
  local status body

  note "Checking ${label}: ${url}"
  status="$(http_status "$url")" || fail "${label} request failed: ${url}"
  body="$(read_last_http_body)"
  [[ "$status" == "$expected_status" ]] || fail "${label} returned HTTP ${status}, expected ${expected_status}"
  [[ "$body" == *"$expected_fragment"* ]] || fail "${label} response did not contain expected fragment: ${expected_fragment}"
}

assert_http_status() {
  local url="$1"
  local expected_status="$2"
  local label="$3"
  local status

  note "Checking ${label}: ${url}"
  status="$(http_status "$url")" || fail "${label} request failed: ${url}"
  [[ "$status" == "$expected_status" ]] || fail "${label} returned HTTP ${status}, expected ${expected_status}"
}

run_smoke_checks() {
  local endpoint_url="$1"
  assert_http_contains "${endpoint_url}/health" "200" '"status":"ok"' "health"
  assert_http_contains "${endpoint_url}/api/v1" "200" '"message":"' "api"
  assert_http_contains "${endpoint_url}/version" "200" '"version":"' "version"
  assert_http_status "${endpoint_url}/" "404" "root 404"
  success "Smoke checks passed for ${endpoint_url}"
}

print_next_steps() {
  summary_start "Next Steps"
  summary_next_step "./scripts/validate.sh all"
  summary_next_step "./scripts/resolve-image.sh"
  summary_next_step "./scripts/deploy-cdk.sh dev"
  summary_next_step "./scripts/build-ami.sh dev && ./scripts/deploy-terraform.sh dev"
  summary_next_step "./scripts/cleanup-cdk.sh dev infra or ./scripts/cleanup-terraform.sh dev infra"
}
