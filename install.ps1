# PowerShell script for Windows installation
$ErrorActionPreference = "Stop"

# --- Configuration ---
$PackageName = "bikash-ai"
$GithubRepo = "your-username/bikash-ai" # CHANGE THIS!
$InstallDir = "$env:USERPROFILE\.local\bin"
$BinaryName = "bikash.exe"

# --- Helper Functions ---
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Print-Error { Write-ColorOutput Red "❌ Error: $args" }
function Print-Success { Write-ColorOutput Green "✅ $args" }
function Print-Info { Write-ColorOutput Blue "ℹ️  $args" }
function Print-Warning { Write-ColorOutput Yellow "⚠️  $args" }

# --- Main Installation ---
function Main {
    Write-Output ""
    Write-ColorOutput Blue "╔════════════════════════════════════════╗"
    Write-ColorOutput Blue "║  🚀 Installing Bikash-AI               ║"
    Write-ColorOutput Blue "╚════════════════════════════════════════╝"
    Write-Output ""
    
    # 1. Create the installation directory
    if (!(Test-Path -Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        Print-Info "Created directory: $InstallDir"
    }

    # 2. Fetch latest release from GitHub
    Print-Info "Fetching latest release info from GitHub..."
    $ReleaseUrl = "https://api.github.com/repos/$GithubRepo/releases/latest"
    try {
        $ReleaseInfo = Invoke-RestMethod -Uri $ReleaseUrl
        $LatestVersion = $ReleaseInfo.tag_name
    } catch {
        Print-Warning "Could not fetch release info. Using fallback version."
        $LatestVersion = "v1.0.0"
    }
    Print-Info "Latest version: $LatestVersion"

    # 3. Build download URL
    $BinaryNameFull = "$PackageName-windows-x64.zip"
    $DownloadUrl = "https://github.com/$GithubRepo/releases/download/$LatestVersion/$BinaryNameFull"
    Print-Info "Downloading $DownloadUrl ..."

    # 4. Download and extract
    $TempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    $ZipPath = Join-Path $TempDir $BinaryNameFull
    
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

    # 5. Move binary to install directory
    $ExtractedBinary = Get-ChildItem -Path $TempDir -Filter $BinaryName -Recurse | Select-Object -First 1
    if ($ExtractedBinary) {
        Move-Item -Path $ExtractedBinary.FullName -Destination (Join-Path $InstallDir $BinaryName) -Force
    } else {
        Print-Error "Could not find $BinaryName in the downloaded archive."
        exit 1
    }
    
    Remove-Item -Path $TempDir -Recurse -Force
    Print-Success "Installed to $InstallDir\$BinaryName"

    # 6. Add to PATH if needed
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        Print-Info "Adding $InstallDir to your PATH..."
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Print-Success "Added to PATH. You may need to restart your terminal."
    }

    # 7. Verify installation
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    if (Get-Command $BinaryName -ErrorAction SilentlyContinue) {
        Print-Success "Installation complete! Run 'bikash --help' to get started."
    } else {
        Print-Warning "Installation complete, but 'bikash' is not in your PATH yet. You can run it directly from $InstallDir\$BinaryName"
    }
}

Main
