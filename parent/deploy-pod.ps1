[CmdletBinding()]
param(
    [ValidateSet('Apply', 'Delete')]
    [string]$Action = 'Apply',

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$ClusterName,

    [Parameter(Mandatory)]
    [string]$PodName,

    [Parameter(Mandatory)]
    [string]$PodNamespace,

    [string]$ContainerName,
    [string]$Image,
    [string]$AdoUrl,
    [string]$AdoPool,
    [string]$AdoAgent,
    [string]$LabelsJson,
    [string]$CpuRequest,
    [string]$MemoryRequest,
    [string]$CpuLimit,
    [string]$MemoryLimit
)

$ErrorActionPreference = 'Stop'

foreach ($commandName in @('az', 'kubectl')) {
    if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
        throw "Required command '$commandName' was not found in PATH."
    }
}

$previousKubeConfig = $env:KUBECONFIG
$kubeConfigPath = Join-Path ([IO.Path]::GetTempPath()) "terraform-aks-$([guid]::NewGuid()).kubeconfig"
$secretName = "$PodName-ado-auth"

try {
    $env:KUBECONFIG = $kubeConfigPath
    & az aks get-credentials --resource-group $ResourceGroupName --name $ClusterName --file $kubeConfigPath --overwrite-existing --only-show-errors
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get credentials for AKS cluster '$ClusterName'."
    }

    if ($Action -eq 'Delete') {
        & kubectl delete pod $PodName --namespace $PodNamespace --ignore-not-found=true
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete pod '$PodName'."
        }

        & kubectl delete secret $secretName --namespace $PodNamespace --ignore-not-found=true
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete secret '$secretName'."
        }

        return
    }

    if ([string]::IsNullOrWhiteSpace($AdoUrl)) {
        throw 'Set ado_url in terraform.tfvars before creating the agent pod.'
    }
    if ([string]::IsNullOrWhiteSpace($AdoPool)) {
        throw 'Set ado_pool in terraform.tfvars before creating the agent pod.'
    }
    if ([string]::IsNullOrWhiteSpace($AdoAgent)) {
        throw 'Set ado_agent in terraform.tfvars before creating the agent pod.'
    }
    if ([string]::IsNullOrWhiteSpace($env:ADO_PAT)) {
        throw 'Set the sensitive ado_pat Terraform input before creating the agent pod.'
    }

    $labels = ConvertFrom-Json -InputObject $LabelsJson
    $secretManifest = @{
        apiVersion = 'v1'
        kind       = 'Secret'
        metadata   = @{
            name      = $secretName
            namespace = $PodNamespace
        }
        type       = 'Opaque'
        stringData = @{
            AZDO_PAT = $env:ADO_PAT
        }
    } | ConvertTo-Json -Depth 10 -Compress

    $secretManifest | & kubectl apply -f -
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create Kubernetes secret '$secretName'."
    }

    $podManifest = @{
        apiVersion = 'v1'
        kind       = 'Pod'
        metadata   = @{
            name      = $PodName
            namespace = $PodNamespace
            labels    = $labels
        }
        spec       = @{
            containers = @(
                @{
                    name            = $ContainerName
                    image           = $Image
                    imagePullPolicy = 'Always'
                    env             = @(
                        @{
                            name  = 'AZDO_URL'
                            value = $AdoUrl
                        },
                        @{
                            name  = 'AZDO_POOL'
                            value = $AdoPool
                        },
                        @{
                            name  = 'AZDO_AGENT'
                            value = $AdoAgent
                        },
                        @{
                            name      = 'AZDO_PAT'
                            valueFrom = @{
                                secretKeyRef = @{
                                    name = $secretName
                                    key  = 'AZDO_PAT'
                                }
                            }
                        }
                    )
                    resources       = @{
                        requests = @{
                            cpu    = $CpuRequest
                            memory = $MemoryRequest
                        }
                        limits   = @{
                            cpu    = $CpuLimit
                            memory = $MemoryLimit
                        }
                    }
                }
            )
        }
    } | ConvertTo-Json -Depth 20 -Compress

    $podManifest | & kubectl apply -f -
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create pod '$PodName'."
    }

    & kubectl wait --for=condition=Ready "pod/$PodName" --namespace $PodNamespace --timeout=300s
    if ($LASTEXITCODE -ne 0) {
        throw "Pod '$PodName' did not become Ready within 300 seconds."
    }
}
catch {
    if ($Action -eq 'Apply' -and (Test-Path -Path $kubeConfigPath -PathType Leaf)) {
        & kubectl delete pod $PodName --namespace $PodNamespace --ignore-not-found=true 2>$null
        & kubectl delete secret $secretName --namespace $PodNamespace --ignore-not-found=true 2>$null
    }
    throw
}
finally {
    if ($null -eq $previousKubeConfig) {
        Remove-Item Env:KUBECONFIG -ErrorAction SilentlyContinue
    }
    else {
        $env:KUBECONFIG = $previousKubeConfig
    }
    Remove-Item -Path $kubeConfigPath -Force -ErrorAction SilentlyContinue
}
