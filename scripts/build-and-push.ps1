$ErrorActionPreference = "Stop"

$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
$Tag = if ($env:IMAGE_TAG) { $env:IMAGE_TAG } else { "latest" }

$InfraRoot = Split-Path -Parent $PSScriptRoot
$TriageRoot = Join-Path (Split-Path -Parent $InfraRoot) "incident_triage_workflow"

if (-not (Test-Path (Join-Path $TriageRoot "frontend\Dockerfile"))) {
    throw "Expected sibling repo at $TriageRoot"
}

$FrontendUri = $null
$BackendUri = $null
$Cluster = "incident-platform"

Push-Location $InfraRoot
try {
    $FrontendUri = terraform output -raw ecr_frontend_url 2>$null
    $BackendUri = terraform output -raw ecr_backend_url 2>$null
    $ClusterOut = terraform output -raw ecs_cluster_name 2>$null
    if ($ClusterOut) { $Cluster = $ClusterOut }
}
finally {
    Pop-Location
}

if (-not $FrontendUri -or -not $BackendUri) {
    $Account = aws sts get-caller-identity --query Account --output text --region $Region
    if (-not $Account) { throw "AWS CLI is not logged in (aws sts get-caller-identity failed)." }
    $FrontendUri = "$Account.dkr.ecr.$Region.amazonaws.com/incident-triage-frontend"
    $BackendUri = "$Account.dkr.ecr.$Region.amazonaws.com/incident-triage-backend"
}

$Registry = $FrontendUri.Split("/")[0]
aws ecr get-login-password --region $Region |
    docker login --username AWS --password-stdin $Registry

docker build -t "${FrontendUri}:${Tag}" (Join-Path $TriageRoot "frontend")
docker build -t "${BackendUri}:${Tag}" -f (Join-Path $TriageRoot "backend\Dockerfile") $TriageRoot

docker push "${FrontendUri}:${Tag}"
docker push "${BackendUri}:${Tag}"

aws ecs update-service --cluster $Cluster --service triage-frontend --force-new-deployment --region $Region | Out-Null
aws ecs update-service --cluster $Cluster --service triage-backend --force-new-deployment --region $Region | Out-Null

Write-Host "Pushed ${FrontendUri}:${Tag} and ${BackendUri}:${Tag}; forced new ECS deployments."
