# PowerShell Deployment Script for Obsidian Project

# Script configuration
$FOLDER_PATH = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_PATH = Split-Path -Parent $FOLDER_PATH
$NEW_INSTALLATION = $false
$TEMP_DIR = Join-Path $ROOT_PATH "temp_obsidian_setup"
$OBSIDIAN_DIR = Join-Path $ROOT_PATH ".obsidian"
$PLUGINS_DIR = Join-Path $OBSIDIAN_DIR "plugins"
$TEMPLATES_DIR = Join-Path $ROOT_PATH "Templates"

# Plugin repositories and configuration
$PLUGINS_REPO = "https://github.com/GreyHatDoc/obsidian_plugins.git"
$TEMPLATES_REPO = "https://github.com/GreyHatDoc/obsidian_templates.git"
$REQUIRED_PLUGINS = @("snippet-expander", "hotkey-tag-navigator")
$CORE_PLUGINS = @("templates", "file-explorer", "search", "quick-switcher", "command-palette")

# Color output functions
function Print-Info {
    param([string]$Message)
    # Colored host output for interactive sessions
    Write-Host "[INFO] $Message" -ForegroundColor Blue
    # Also emit to STDOUT so output can be redirected/captured
    Write-Output "[INFO] $Message"
}
function Print-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Write-Output "[SUCCESS] $Message"
}
function Print-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
    Write-Output "[WARNING] $Message"
}
function Print-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Output "[ERROR] $Message"
}

# Cleanup function
function Cleanup {
    if (Test-Path $TEMP_DIR) {
        Print-Info "Cleaning up temporary directory..."
        Remove-Item -Recurse -Force $TEMP_DIR
    }
}

# Set trap for cleanup on exit
trap { Cleanup }

function Create-Temp-Dir {
    if (-not (Test-Path $TEMP_DIR)) {
        New-Item -ItemType Directory -Path $TEMP_DIR | Out-Null
        Print-Info "Created temporary directory: $TEMP_DIR"
    }
}

function Check-Installation {
    Print-Info "Checking installation type..."
    if (-not (Test-Path $OBSIDIAN_DIR)) {
        Print-Info "No .obsidian folder found. This is a new installation."
        $NEW_INSTALLATION = $true
    } else {
        Print-Info ".obsidian folder found. This is an existing installation."
        $NEW_INSTALLATION = $false
    }
}

function Check-Dependencies {
    Print-Info "Checking dependencies..."
    
    # Check for git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Print-Error "Git is required but not installed."
        exit 1
    }
    
    # Check internet connectivity
    try {
        Test-Connection -ComputerName "github.com" -Count 1 -ErrorAction Stop | Out-Null
    } catch {
        Print-Warning "No internet connection detected. Some features may not work."
    }
}

function Download-Git-Repos {
    Print-Info "Downloading required repositories..."
    
    # Download plugins
    if ($PLUGINS_REPO) {
        Print-Info "Cloning plugins repository..."
        git clone $PLUGINS_REPO (Join-Path $TEMP_DIR "obsidian-plugins") 2>$null
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Plugins repository downloaded successfully"
        } else {
            Print-Error "Failed to download plugins repository"
            return $false
        }
    }
    
    # Download templates
    if ($TEMPLATES_REPO) {
        Print-Info "Cloning templates repository..."
        git clone $TEMPLATES_REPO (Join-Path $TEMP_DIR "obsidian-templates") 2>$null
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Templates repository downloaded successfully"
        } else {
            Print-Error "Failed to download templates repository"
            return $false
        }
    }
}

function Create-Obsidian-Structure {
    Print-Info "Creating .obsidian directory structure..."
    
    # Create main .obsidian directory
    New-Item -ItemType Directory -Path $OBSIDIAN_DIR -Force | Out-Null
    New-Item -ItemType Directory -Path $PLUGINS_DIR -Force | Out-Null
    
    Print-Success "Obsidian directory structure created"
}

function Setup-Core-Plugins {
    Print-Info "Setting up core plugins configuration..."
    
    $corePluginsFile = Join-Path $OBSIDIAN_DIR "core-plugins.json"
    $corePluginsJson = @()
    
    foreach ($plugin in $CORE_PLUGINS) {
        $corePluginsJson += $plugin
    }
    
    $corePluginsJson | ConvertTo-Json | Set-Content -Path $corePluginsFile
    Print-Success "Core plugins configuration created"
}

function Setup-Community-Plugins {
    Print-Info "Setting up community plugins configuration..."
    
    $communityPluginsFile = Join-Path $OBSIDIAN_DIR "community-plugins.json"
    
    if (-not (Test-Path $communityPluginsFile)) {
        # Create new community-plugins.json
        $pluginsJson = @()
        foreach ($plugin in $REQUIRED_PLUGINS) {
            $pluginsJson += $plugin
        }
        
        $pluginsJson | ConvertTo-Json | Set-Content -Path $communityPluginsFile
        Print-Success "Community plugins configuration created"
    } else {
        # Update existing community-plugins.json
        Print-Info "Updating existing community plugins configuration..."
        foreach ($plugin in $REQUIRED_PLUGINS) {
            if (-not (Select-String -Path $communityPluginsFile -Pattern "`"$plugin`"" -SimpleMatch)) {
                Print-Info "Adding $plugin to community-plugins.json"
                $tempFile = [System.IO.Path]::GetTempFileName()
                (Get-Content $communityPluginsFile) | ForEach-Object { $_ -replace ']', ", `"$plugin`"]" } | Set-Content -Path $tempFile
                Move-Item -Path $tempFile -Destination $communityPluginsFile -Force
            }
        }
        Print-Success "Community plugins configuration updated"
    }
}

function Install-Plugins {
    Print-Info "Installing plugins..."
    
    if (Test-Path (Join-Path $TEMP_DIR "obsidian-plugins")) {
        # Copy all plugin directories
        Get-ChildItem -Path (Join-Path $TEMP_DIR "obsidian-plugins") | ForEach-Object {
            if ($_.PSIsContainer) {
                $pluginName = $_.Name
                Print-Info "Installing plugin: $pluginName"
                Copy-Item -Path $_.FullName -Destination $PLUGINS_DIR -Recurse -Force
            }
        }
        Print-Success "Plugins installed successfully"
    } else {
        Print-Warning "No plugins directory found in downloaded repositories"
    }
}

function Install-Templates {
    Print-Info "Installing templates..."
    
    # Check if we have a local template installer
    $templateInstaller = Join-Path $ROOT_PATH "install_templates.ps1"
    
    if (Test-Path $templateInstaller) {
        Print-Info "Using local template installer"
        try {
            & $templateInstaller -Folder "Project" -Path $ROOT_PATH 2>$null
        } catch {
            Print-Warning "Local template installer encountered an error: $_"
        }
    } elseif (Test-Path (Join-Path $TEMP_DIR "obsidian-templates")) {
        Print-Info "Installing templates from downloaded repository"
        # Move templates to root directory
        Copy-Item -Path (Join-Path $TEMP_DIR "obsidian-templates") -Destination $ROOT_PATH -Recurse -Force
        
        # Try to run installer if it exists
        $downloadedInstaller = Join-Path (Join-Path $ROOT_PATH "obsidian-templates") "install_templates.ps1"
        if (Test-Path $downloadedInstaller) {
            Print-Info "Running downloaded template installer..."
            try {
                & $downloadedInstaller -Folder "Project" 2>$null
            } catch {
                Print-Warning "Template installer had issues, falling back to manual installation"
                # Manual template installation as fallback
                New-Item -ItemType Directory -Path $TEMPLATES_DIR -Force | Out-Null
                if (Test-Path (Join-Path (Join-Path $ROOT_PATH "obsidian-templates") "Templates")) {
                    Copy-Item -Path (Join-Path (Join-Path $ROOT_PATH "obsidian-templates") "Templates\*") -Destination $TEMPLATES_DIR -Force
                    Print-Success "Templates installed manually (fallback)"
                }
            }
        } else {
            # Manual template installation
            New-Item -ItemType Directory -Path $TEMPLATES_DIR -Force | Out-Null
            if (Test-Path (Join-Path (Join-Path $ROOT_PATH "obsidian-templates") "Templates")) {
                Copy-Item -Path (Join-Path (Join-Path $ROOT_PATH "obsidian-templates") "Templates\*") -Destination $TEMPLATES_DIR -Force
                Print-Success "Templates installed manually"
            }
        }
    } else {
        Print-Warning "No templates found to install"
    }
}

function Create-GitIgnore {
    Print-Info "Setting up .gitignore..."
    
    $gitignoreFile = Join-Path $ROOT_PATH ".gitignore"
    $obsidianIgnorePatterns = @(".obsidian/")
    
    # Create or update .gitignore
    if (-not (Test-Path $gitignoreFile)) {
        Print-Info "Creating new .gitignore file"
        $obsidianIgnorePatterns | ForEach-Object { Add-Content -Path $gitignoreFile -Value $_ }
    } else {
        Print-Info "Updating existing .gitignore file"
        foreach ($pattern in $obsidianIgnorePatterns) {
            if (-not (Select-String -Path $gitignoreFile -Pattern $pattern -SimpleMatch)) {
                Add-Content -Path $gitignoreFile -Value $pattern
            }
        }
    }
    
    Print-Success ".gitignore configured for Obsidian"
}

function Create-Basic-Config {
    Print-Info "Creating basic Obsidian configuration..."
    
    # Create app.json with basic settings
    $appJson = @"
{
  "legacyEditor": false,
  "livePreview": true,
  "defaultViewMode": "preview",
  "attachmentFolderPath": "attachments",
  "newLinkFormat": "shortest",
  "useMarkdownLinks": true,
  "newFileLocation": "current",
  "promptDelete": true
}
"@
    Set-Content -Path (Join-Path $OBSIDIAN_DIR "app.json") -Value $appJson

    # Create appearance.json
    $appearanceJson = @"
{
  "accentColor": "",
  "theme": "obsidian",
  "cssTheme": ""
}
"@
    Set-Content -Path (Join-Path $OBSIDIAN_DIR "appearance.json") -Value $appearanceJson

    Print-Success "Basic configuration files created"
}

function New-Installation {
    Print-Success "Setting up new Obsidian vault installation..."
    
    Create-Obsidian-Structure
    Create-Basic-Config
    Setup-Core-Plugins
    Setup-Community-Plugins
    
    # Copy pre-existing .obsidian folder if it exists in the deployment directory
    if (Test-Path (Join-Path $FOLDER_PATH ".obsidian")) {
        Print-Info "Found pre-configured .obsidian folder, using as template..."
        Copy-Item -Path (Join-Path $FOLDER_PATH ".obsidian\*") -Destination $OBSIDIAN_DIR -Recurse -Force
    }
    
    Install-Plugins
    Install-Templates
    Create-GitIgnore
    
    Print-Success "New installation setup complete!"
}

function Existing-Installation {
    Print-Success "Updating existing Obsidian vault..."
    
    # Ensure plugins directory exists
    New-Item -ItemType Directory -Path $PLUGINS_DIR -Force | Out-Null
    
    Setup-Community-Plugins
    Install-Plugins
    Install-Templates
    Create-GitIgnore
    
    Print-Success "Existing installation update complete!"
}

function Show-Help {
    @"
Obsidian Deployment Script

Usage: .\deploy_obsidian.ps1 [OPTIONS]

Options:
    -h, --help          Show this help message
    -f, --force         Force new installation even if .obsidian exists
    -t, --templates     Install templates only
    -p, --plugins       Install plugins only
    --no-git            Skip git repository downloads
    --no-cleanup        Don't cleanup temporary files

This script will:
    - Detect if this is a new or existing Obsidian vault
    - Download and install required plugins
    - Configure community and core plugins
    - Install project templates
    - Set up appropriate .gitignore rules
"@
}

function Main {
    param (
        [Alias("h")]
        [switch]$Help,
        [Alias("f")]
        [switch]$ForceNew,
        [Alias("t")]
        [switch]$TemplatesOnly,
        [Alias("p")]
        [switch]$PluginsOnly,
        [switch]$NoGit,
        [switch]$NoCleanup
    )
    
    # Show help if requested
    if ($Help) {
        Show-Help
        return
    }
    
    # Override cleanup if requested
    if ($NoCleanup) {
        trap { }
    }
    
    Print-Info "Starting Obsidian deployment..."
    
    Create-Temp-Dir
    Check-Dependencies
    
    # Force new installation if requested
    if ($ForceNew) {
        $NEW_INSTALLATION = $true
        Print-Info "Forcing new installation mode"
    } else {
        Check-Installation
    }
    
    # Download repositories unless skipped
    if (-not $NoGit -and -not $TemplatesOnly -and -not $PluginsOnly) {
        if (-not (Download-Git-Repos)) {
            Print-Error "Failed to download repositories"
            exit 1
        }
    } elseif (-not $NoGit -and $PluginsOnly) {
        # Download only plugins repo
        if ($PLUGINS_REPO) {
            git clone $PLUGINS_REPO (Join-Path $TEMP_DIR "obsidian-plugins") 2>$null
        }
    } elseif (-not $NoGit -and $TemplatesOnly) {
        # Download only templates repo
        if ($TEMPLATES_REPO) {
            git clone $TEMPLATES_REPO (Join-Path $TEMP_DIR "obsidian-templates") 2>$null
        }
    }
    
    # Handle specific installation modes
    if ($TemplatesOnly) {
        Install-Templates
    } elseif ($PluginsOnly) {
        New-Item -ItemType Directory -Path $PLUGINS_DIR -Force | Out-Null
        Setup-Community-Plugins
        Install-Plugins
    } elseif ($NEW_INSTALLATION) {
        New-Installation
    } else {
        Existing-Installation
    }
    
    Print-Success "Obsidian deployment completed successfully!"
    Print-Info "You can now open this directory as an Obsidian vault."
}

# Run main function with all arguments
Main @args