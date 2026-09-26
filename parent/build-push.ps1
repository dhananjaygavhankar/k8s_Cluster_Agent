[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9]{5,50}$')]
    [string]$RegistryName,

    [Parameter(Mandatory)]
    [string]$RegistryLoginServer,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9]+(?:[._/-][a-z0-9]+)*(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127})?$')]
    [string]$ImageName,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$DockerContextPath
)

$ErrorActionPreference = 'Stop'

foreach ($commandName in @('az', 'docker')) {
    if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
        throw "Required command '$commandName' was not found in PATH."
    }
}

function Test-LinuxDockerEngine {
    $engineOs = & docker info --format '{{.OSType}}' 2>$null
    return ($LASTEXITCODE -eq 0 -and $engineOs.Trim() -eq 'linux')
}

if (-not (Test-LinuxDockerEngine)) {
    $dockerDesktopPaths = @(
        (Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Docker\Docker Desktop.exe'),
        (Join-Path $env:LOCALAPPDATA 'Docker\Docker Desktop.exe')
    )
    $dockerDesktopPath = $dockerDesktopPaths | Where-Object { Test-Path -Path $_ -PathType Leaf } | Select-Object -First 1

    if (-not $dockerDesktopPath) {
        throw 'Docker Desktop was not found. Install it, then rerun terraform apply.'
    }

    Write-Host 'Docker Linux engine is not ready; starting Docker Desktop.'
    Start-Process -FilePath $dockerDesktopPath -ErrorAction Stop

    $dockerStartupDeadline = [DateTime]::UtcNow.AddSeconds(180)
    while ([DateTime]::UtcNow -lt $dockerStartupDeadline) {
        if (Test-LinuxDockerEngine) {
            Write-Host 'Docker Desktop Linux engine is ready.'
            break
        }

        Start-Sleep -Seconds 5
    }

    if (-not (Test-LinuxDockerEngine)) {
        throw 'Docker Desktop did not start its Linux container engine within 180 seconds. Start or switch Docker Desktop to Linux containers, then rerun terraform apply.'
    }
}

$dockerfilePath = Join-Path $DockerContextPath 'Dockerfile'
if (-not (Test-Path -Path $dockerfilePath -PathType Leaf)) {
    throw "Dockerfile was not found in '$DockerContextPath'."
}

$agentVersion = '4.260.0'
$agentArchiveName = "vsts-agent-linux-x64-$agentVersion.tar.gz"
$agentArchivePath = Join-Path $DockerContextPath $agentArchiveName
$agentArchiveUrl = "https://download.agent.dev.azure.com/agent/$agentVersion/$agentArchiveName"
$expectedAgentArchiveSha256 = '4C3AF1450788BC19B847253B02CB82036DBA55B4B563CD2563FAD9B46DE8B9C8'

function Get-Sha256Hash {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        return [BitConverter]::ToString($sha256.ComputeHash($stream)).Replace('-', '')
    }
    finally {
        $stream.Dispose()
        $sha256.Dispose()
    }
}

if (Test-Path -Path $agentArchivePath -PathType Leaf) {
    $actualAgentArchiveSha256 = Get-Sha256Hash -Path $agentArchivePath
    if ($actualAgentArchiveSha256 -ne $expectedAgentArchiveSha256) {
        Remove-Item -Path $agentArchivePath -Force
    }
}

if (-not (Test-Path -Path $agentArchivePath -PathType Leaf)) {
    $temporaryArchivePath = "$agentArchivePath.$([guid]::NewGuid()).download"
    try {
        Invoke-WebRequest -Uri $agentArchiveUrl -OutFile $temporaryArchivePath -ErrorAction Stop
        $actualAgentArchiveSha256 = Get-Sha256Hash -Path $temporaryArchivePath
        if ($actualAgentArchiveSha256 -ne $expectedAgentArchiveSha256) {
            throw "Downloaded Azure Pipelines agent archive failed SHA-256 verification."
        }

        Move-Item -Path $temporaryArchivePath -Destination $agentArchivePath
    }
    finally {
        Remove-Item -Path $temporaryArchivePath -Force -ErrorAction SilentlyContinue
    }
}

$imageReference = "$RegistryLoginServer/$ImageName"

& az acr login --name $RegistryName --only-show-errors
if ($LASTEXITCODE -ne 0) {
    throw "Azure Container Registry login failed with exit code $LASTEXITCODE."
}

& docker build --pull --file $dockerfilePath --tag $imageReference $DockerContextPath
if ($LASTEXITCODE -ne 0) {
    throw "Docker image build failed with exit code $LASTEXITCODE."
}

$maxPushAttempts = 5
for ($attempt = 1; $attempt -le $maxPushAttempts; $attempt++) {
    & docker push $imageReference
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Pushed $imageReference"
        return
    }

    if ($attempt -lt $maxPushAttempts) {
        $delaySeconds = [Math]::Min(30, [int](5 * [Math]::Pow(2, $attempt - 1)))
        Write-Warning "Image push failed; retrying in $delaySeconds seconds ($attempt/$maxPushAttempts)."
        Start-Sleep -Seconds $delaySeconds
    }
}

throw "Docker image push failed after $maxPushAttempts attempts."