# Obsidian Project Deployment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful bash script to automate the deployment and configuration of Obsidian vaults in your project repositories. This tool simplifies setting up Obsidian for project documentation by automatically configuring plugins, templates, and directory structures.

## Overview

This deployment script streamlines the process of creating or updating an Obsidian vault within any project directory. It handles everything from initial vault creation to plugin installation, making it easy to maintain consistent documentation practices across multiple projects.

### Key Features

- ** Automated Setup**: Creates complete Obsidian vault structure with one command
- ** Plugin Management**: Automatically downloads and configures community plugins
- ** Template Integration**: Deploys project templates for consistent documentation
- ** Dual Mode Support**: Handles both new vault creation and existing vault updates
- ** Smart Configuration**: Sets up core plugins, community plugins, and basic Obsidian settings
- ** Git Integration**: Automatically configures `.gitignore` for Obsidian files
- ** Customizable**: Flexible command-line options for different use cases

## Prerequisites

- **Git**: Required for downloading plugins and templates
- **Bash**: Shell environment (sh/bash)
- **Internet Connection**: Needed for repository downloads
- **Optional**: `jq` for advanced JSON manipulation (script works without it)

## Quick Start

### Basic Installation

```bash
# Clone this repository
git clone https://github.com/GreyHatDoc/obsidian-project-deployment.git

# Navigate to your project directory
cd /path/to/your/project

# Run the deployment script
/path/to/obsidian-project-deployment/deploy_obsidian.sh
```

### Direct Download & Run

```bash
# Download and execute in one go
curl -O https://raw.githubusercontent.com/GreyHatDoc/obsidian-project-deployment/main/deploy_obsidian.sh
chmod +x deploy_obsidian.sh
./deploy_obsidian.sh
```

## Usage

### Command Syntax

```bash
./deploy_obsidian.sh [OPTIONS]
```

### Available Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Display help message and usage information |
| `-f, --force` | Force new installation even if `.obsidian` folder exists |
| `-t, --templates` | Install or update templates only |
| `-p, --plugins` | Install or update plugins only |
| `--no-git` | Skip downloading git repositories (use local/existing) |
| `--no-cleanup` | Don't delete temporary files after installation |

### Usage Examples

#### New Vault Setup
```bash
# Create a new Obsidian vault in the current directory
./deploy_obsidian.sh
```

#### Update Existing Vault
```bash
# Update plugins and templates in existing vault
./deploy_obsidian.sh
```

#### Install Only Templates
```bash
# Add or update templates without touching plugins
./deploy_obsidian.sh --templates
```

#### Install Only Plugins
```bash
# Add or update plugins without templates
./deploy_obsidian.sh --plugins
```

#### Force Clean Installation
```bash
# Recreate vault structure even if one exists
./deploy_obsidian.sh --force
```

#### Offline Mode
```bash
# Use pre-downloaded repositories (skip git clone)
./deploy_obsidian.sh --no-git
```

## 🏗️ What Gets Installed

### Directory Structure

```
your-project/
├── .obsidian/
│   ├── plugins/
│   │   ├── snippet-expander/
│   │   └── hotkey-tag-navigator/
│   ├── app.json
│   ├── appearance.json
│   ├── core-plugins.json
│   └── community-plugins.json
├── Templates/
│   └── (project templates)
└── .gitignore (updated)
```

### Core Plugins Enabled

- **Templates**: For using note templates
- **File Explorer**: Navigate your vault files
- **Search**: Find content across notes
- **Quick Switcher**: Fast file navigation
- **Command Palette**: Access all commands

### Community Plugins Installed

- **Snippet Expander**: Quick text expansion and snippets
- **Hotkey Tag Navigator**: Efficient tag-based navigation

### Configuration Files

- **app.json**: Basic Obsidian settings (live preview, link format, etc.)
- **appearance.json**: Theme and appearance settings
- **core-plugins.json**: Enabled core plugins list
- **community-plugins.json**: Enabled community plugins list

## How It Works

### New Installation Flow

1. **Detection**: Checks if `.obsidian` folder exists
2. **Structure Creation**: Creates `.obsidian` and necessary subdirectories
3. **Repository Download**: Clones plugin and template repositories
4. **Plugin Installation**: Copies plugins to `.obsidian/plugins/`
5. **Configuration**: Sets up core and community plugin configs
6. **Template Deployment**: Installs project templates
7. **Git Configuration**: Updates `.gitignore` for Obsidian files
8. **Cleanup**: Removes temporary download directories

### Existing Installation Flow

1. **Detection**: Identifies existing `.obsidian` folder
2. **Repository Download**: Fetches latest plugins and templates
3. **Plugin Update**: Adds new plugins while preserving existing ones
4. **Configuration Update**: Merges new plugins into community-plugins.json
5. **Template Update**: Adds or updates templates
6. **Git Update**: Ensures `.gitignore` includes Obsidian patterns
7. **Cleanup**: Removes temporary files

## 📦 Plugin & Template Repositories

The script downloads from these repositories:

- **Plugins**: [https://github.com/GreyHatDoc/obsidian_plugins](https://github.com/GreyHatDoc/obsidian_plugins)
- **Templates**: [https://github.com/GreyHatDoc/obsidian_templates](https://github.com/GreyHatDoc/obsidian_templates)

You can modify the script to point to your own repositories by editing:

```bash
PLUGINS_REPO="https://github.com/YOUR_USERNAME/your-plugins.git"
TEMPLATES_REPO="https://github.com/YOUR_USERNAME/your-templates.git"
```

## Customization

### Adding Custom Plugins

Edit the `REQUIRED_PLUGINS` array in the script:

```bash
REQUIRED_PLUGINS=("snippet-expander" "hotkey-tag-navigator" "your-plugin-name")
```

### Modifying Core Plugins

Edit the `CORE_PLUGINS` array:

```bash
CORE_PLUGINS=("templates" "file-explorer" "search" "quick-switcher" "command-palette" "daily-notes")
```

### Custom Configuration

The script creates basic configurations. To customize, edit the JSON templates in the `create_basic_config()` function.

## Troubleshooting

### Common Issues

**Problem**: "Git is required but not installed"
```bash
# Install git first
# Ubuntu/Debian: sudo apt-get install git
# macOS: brew install git
# Check: git --version
```

**Problem**: "Failed to download repositories"
```bash
# Check internet connection
ping github.com

# Try manual clone
git clone https://github.com/GreyHatDoc/obsidian_plugins.git

# Use --no-git flag if repositories are pre-downloaded
./deploy_obsidian.sh --no-git
```

**Problem**: Plugins not appearing in Obsidian
```bash
# Force reinstall
./deploy_obsidian.sh --force --plugins

# Check community-plugins.json exists
cat .obsidian/community-plugins.json

# Restart Obsidian after deployment
```

**Problem**: Templates not visible
```bash
# Reinstall templates
./deploy_obsidian.sh --templates

# Check Templates directory
ls -la Templates/

# Verify Obsidian template settings
# Settings → Core Plugins → Templates → Template folder location
```

### Debug Mode

To see detailed execution:

```bash
# Run with bash debugging
bash -x ./deploy_obsidian.sh
```

## Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Ideas for Contributions

- PowerShell version of the script
- Windows batch file support
- Additional plugin configurations
- Theme installation support
- Automated testing framework
- Interactive mode with prompts
- Rollback functionality

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for the [Obsidian](https://obsidian.md/) community
- Inspired by the need for consistent project documentation
- Thanks to all plugin developers in the Obsidian ecosystem

## Additional Resources

- [Obsidian Official Documentation](https://help.obsidian.md/)
- [Obsidian Community Plugins](https://obsidian.md/plugins)
- [Obsidian Forum](https://forum.obsidian.md/)

### For Developers
- Standardize documentation across multiple projects
- Quick setup for new repositories
- Maintain consistent note-taking practices
- Integrate with CI/CD for documentation deployment

### For Teams
- Onboard new team members with pre-configured vaults
- Share common templates and plugins
- Ensure consistent documentation structure
- Version control documentation configuration

### For Researchers
- Set up research project vaults quickly
- Deploy specialized templates for papers/notes
- Maintain bibliography and citation workflows
- Organize multiple research projects

## Future Plans

- [ ] PowerShell version for Windows
- [ ] Support for custom theme installation
- [ ] Vault migration tools
- [ ] Backup and restore functionality
- [ ] Plugin version management
- [ ] Interactive configuration wizard
- [ ] Docker container support
- [ ] Cross-platform installer

## Support

For issues, questions, or suggestions:

- **Issues**: [GitHub Issues](https://github.com/GreyHatDoc/obsidian-project-deployment/issues)
- **Discussions**: [GitHub Discussions](https://github.com/GreyHatDoc/obsidian-project-deployment/discussions)

---

**Made with ❤️ for the Obsidian community**