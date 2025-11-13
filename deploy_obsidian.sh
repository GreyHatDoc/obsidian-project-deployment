#!/bin/bash

# Script configuration
FOLDER_PATH=$(dirname "$0")
ROOT_PATH=$(realpath "$FOLDER_PATH/..")
NEW_INSTALLATION=0
TEMP_DIR="$ROOT_PATH/temp_obsidian_setup"
OBSIDIAN_DIR="$ROOT_PATH/.obsidian"
PLUGINS_DIR="$OBSIDIAN_DIR/plugins"
TEMPLATES_DIR="$ROOT_PATH/Templates"

# Plugin repositories and configuration
PLUGINS_REPO="https://github.com/GreyHatDoc/obsidian_plugins.git"
TEMPLATES_REPO="https://github.com/GreyHatDoc/obsidian_templates.git"
REQUIRED_PLUGINS=("snippet-expander" "hotkey-tag-navigator")
CORE_PLUGINS=("templates" "file-explorer" "search" "quick-switcher" "command-palette")

# Color output functions
print_info() { echo -e "\033[34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_info "Cleaning up temporary directory..."
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap for cleanup on exit
trap cleanup EXIT

create_temp_dir() {
    if [ ! -d "$TEMP_DIR" ]; then
        mkdir -p "$TEMP_DIR"
        print_info "Created temporary directory: $TEMP_DIR"
    fi
}

check_installation() {
    print_info "Checking installation type..."
    if [ ! -d "$OBSIDIAN_DIR" ]; then
        print_info "No .obsidian folder found. This is a new installation."
        NEW_INSTALLATION=1
    else
        print_info ".obsidian folder found. This is an existing installation."
        NEW_INSTALLATION=0
    fi
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        print_error "Git is required but not installed."
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        print_warning "No internet connection detected. Some features may not work."
    fi
}

download_git_repos() {
    print_info "Downloading required repositories..."
    
    # Download plugins
    if [ -n "$PLUGINS_REPO" ]; then
        print_info "Cloning plugins repository..."
        if git clone "$PLUGINS_REPO" "$TEMP_DIR/obsidian-plugins" 2>/dev/null; then
            print_success "Plugins repository downloaded successfully"
        else
            print_error "Failed to download plugins repository"
            return 1
        fi
    fi
    
    # Download templates
    if [ -n "$TEMPLATES_REPO" ]; then
        print_info "Cloning templates repository..."
        if git clone "$TEMPLATES_REPO" "$TEMP_DIR/obsidian-templates" 2>/dev/null; then
            print_success "Templates repository downloaded successfully"
        else
            print_error "Failed to download templates repository"
            return 1
        fi
    fi
}

create_obsidian_structure() {
    print_info "Creating .obsidian directory structure..."
    
    # Create main .obsidian directory
    mkdir -p "$OBSIDIAN_DIR"
    mkdir -p "$PLUGINS_DIR"   
    
    print_success "Obsidian directory structure created"
}

setup_core_plugins() {
    print_info "Setting up core plugins configuration..."
    
    local core_plugins_file="$OBSIDIAN_DIR/core-plugins.json"
    local core_plugins_json="["
    
    for i in "${!CORE_PLUGINS[@]}"; do
        if [ $i -gt 0 ]; then
            core_plugins_json+=", "
        fi
        core_plugins_json+="\"${CORE_PLUGINS[$i]}\""
    done
    core_plugins_json+="]"
    
    echo "$core_plugins_json" > "$core_plugins_file"
    print_success "Core plugins configuration created"
}

setup_community_plugins() {
    print_info "Setting up community plugins configuration..."
    
    local community_plugins_file="$OBSIDIAN_DIR/community-plugins.json"
    
    if [ ! -f "$community_plugins_file" ]; then
        # Create new community-plugins.json
        local plugins_json="["
        for i in "${!REQUIRED_PLUGINS[@]}"; do
            if [ $i -gt 0 ]; then
                plugins_json+=", "
            fi
            plugins_json+="\"${REQUIRED_PLUGINS[$i]}\""
        done
        plugins_json+="]"
        
        echo "$plugins_json" > "$community_plugins_file"
        print_success "Community plugins configuration created"
    else
        # Update existing community-plugins.json
        print_info "Updating existing community plugins configuration..."
        for plugin in "${REQUIRED_PLUGINS[@]}"; do
            if ! grep -q "\"$plugin\"" "$community_plugins_file"; then
                print_info "Adding $plugin to community-plugins.json"
                # Use a more robust method to add plugins
                local temp_file=$(mktemp)
                jq --arg plugin "$plugin" '. += [$plugin] | unique' "$community_plugins_file" > "$temp_file" 2>/dev/null || {
                    # Fallback if jq is not available
                    sed -i.bak '$ s/]/, "'"$plugin"'"]/' "$community_plugins_file"
                }
                if [ -f "$temp_file" ] && [ -s "$temp_file" ]; then
                    mv "$temp_file" "$community_plugins_file"
                fi
            fi
        done
        print_success "Community plugins configuration updated"
    fi
}

install_plugins() {
    print_info "Installing plugins..."
    
    if [ -d "$TEMP_DIR/obsidian-plugins" ]; then
        # Copy all plugin directories
        for plugin_dir in "$TEMP_DIR/obsidian-plugins"/*; do
            if [ -d "$plugin_dir" ]; then
                local plugin_name=$(basename "$plugin_dir")
                print_info "Installing plugin: $plugin_name"
                cp -r "$plugin_dir" "$PLUGINS_DIR/"
            fi
        done
        print_success "Plugins installed successfully"
    else
        print_warning "No plugins directory found in downloaded repositories"
    fi
}

install_templates() {
    print_info "Installing templates..."
    
    # Check if we have a local template installer
    local template_installer="$ROOT_PATH/obsidian_templates/install_templates.sh"
    
    if [ -f "$template_installer" ]; then
        print_info "Using local template installer"
        chmod +x "$template_installer"
        "$template_installer" --folder "Project" --path "$ROOT_PATH"
    elif [ -d "$TEMP_DIR/obsidian-templates" ]; then
        print_info "Installing templates from downloaded repository"
        # Move templates to root directory
        cp -r "$TEMP_DIR/obsidian-templates" "$ROOT_PATH/"
        
        # Try to run installer if it exists
        local downloaded_installer="$ROOT_PATH/obsidian-templates/install_templates.sh"
        if [ -f "$downloaded_installer" ]; then
            chmod +x "$downloaded_installer"
            "$downloaded_installer" --folder "Project"
        else
            # Manual template installation
            mkdir -p "$TEMPLATES_DIR"
            if [ -d "$ROOT_PATH/obsidian-templates/Templates" ]; then
                cp -r "$ROOT_PATH/obsidian-templates/Templates"/* "$TEMPLATES_DIR/"
                print_success "Templates installed manually"
            fi
        fi
    else
        print_warning "No templates found to install"
    fi
}

create_gitignore() {
    print_info "Setting up .gitignore..."
    
    local gitignore_file="$ROOT_PATH/.gitignore"
    local obsidian_ignore_patterns=(
        ".obsidian/
    )
    
    # Create or update .gitignore
    if [ ! -f "$gitignore_file" ]; then
        print_info "Creating new .gitignore file"
        {
            echo "# Obsidian"
            echo "# Ignore workspace files but keep configuration"
            for pattern in "${obsidian_ignore_patterns[@]}"; do
                echo "$pattern"
            done
        } > "$gitignore_file"
    else
        print_info "Updating existing .gitignore file"
        for pattern in "${obsidian_ignore_patterns[@]}"; do
            if ! grep -q "^$pattern$" "$gitignore_file"; then
                echo "$pattern" >> "$gitignore_file"
            fi
        done
    fi
    
    print_success ".gitignore configured for Obsidian"
}

create_basic_config() {
    print_info "Creating basic Obsidian configuration..."
    
    # Create app.json with basic settings
    cat > "$OBSIDIAN_DIR/app.json" << EOF
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
EOF

    # Create appearance.json
    cat > "$OBSIDIAN_DIR/appearance.json" << EOF
{
  "accentColor": "",
  "theme": "obsidian",
  "cssTheme": ""
}
EOF

    print_success "Basic configuration files created"
}

new_installation() {
    print_success "Setting up new Obsidian vault installation..."
    
    create_obsidian_structure
    create_basic_config
    setup_core_plugins
    setup_community_plugins
    
    # Copy pre-existing .obsidian folder if it exists in the deployment directory
    if [ -d "$FOLDER_PATH/.obsidian" ]; then
        print_info "Found pre-configured .obsidian folder, using as template..."
        cp -r "$FOLDER_PATH/.obsidian"/* "$OBSIDIAN_DIR/"
    fi
    
    install_plugins
    install_templates
    create_gitignore
    
    print_success "New installation setup complete!"
}

existing_installation() {
    print_success "Updating existing Obsidian vault..."
    
    # Ensure plugins directory exists
    mkdir -p "$PLUGINS_DIR"
    
    setup_community_plugins
    install_plugins
    install_templates
    create_gitignore
    
    print_success "Existing installation update complete!"
}

show_help() {
    cat << EOF
Obsidian Deployment Script

Usage: $0 [OPTIONS]

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
EOF
}

main() {
    local force_new=0
    local templates_only=0
    local plugins_only=0
    local no_git=0
    local no_cleanup=0
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                force_new=1
                shift
                ;;
            -t|--templates)
                templates_only=1
                shift
                ;;
            -p|--plugins)
                plugins_only=1
                shift
                ;;
            --no-git)
                no_git=1
                shift
                ;;
            --no-cleanup)
                no_cleanup=1
                shift
                ;;
            *)
                print_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # Override cleanup if requested
    if [ $no_cleanup -eq 1 ]; then
        trap - EXIT
    fi
    
    print_info "Starting Obsidian deployment..."
    
    create_temp_dir
    check_dependencies
    
    # Force new installation if requested
    if [ $force_new -eq 1 ]; then
        NEW_INSTALLATION=1
        print_info "Forcing new installation mode"
    else
        check_installation
    fi
    
    # Download repositories unless skipped
    if [ $no_git -eq 0 ] && [ $templates_only -eq 0 ] && [ $plugins_only -eq 0 ]; then
        download_git_repos || {
            print_error "Failed to download repositories"
            exit 1
        }
    elif [ $no_git -eq 0 ] && [ $plugins_only -eq 1 ]; then
        # Download only plugins repo
        if [ -n "$PLUGINS_REPO" ]; then
            git clone "$PLUGINS_REPO" "$TEMP_DIR/obsidian-plugins" 2>/dev/null
        fi
    elif [ $no_git -eq 0 ] && [ $templates_only -eq 1 ]; then
        # Download only templates repo
        if [ -n "$TEMPLATES_REPO" ]; then
            git clone "$TEMPLATES_REPO" "$TEMP_DIR/obsidian-templates" 2>/dev/null
        fi
    fi
    
    # Handle specific installation modes
    if [ $templates_only -eq 1 ]; then
        install_templates
    elif [ $plugins_only -eq 1 ]; then
        mkdir -p "$PLUGINS_DIR"
        setup_community_plugins
        install_plugins
    elif [ $NEW_INSTALLATION -eq 1 ]; then
        new_installation
    else
        existing_installation
    fi
    
    print_success "Obsidian deployment completed successfully!"
    print_info "You can now open this directory as an Obsidian vault."
}

# Run main function with all arguments
main "$@"