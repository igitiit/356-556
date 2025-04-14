#!/bin/bash
set -e

# Create project directory
PROJECT_DIR="ubuntu-amd64-project"
echo "==> Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create Packer template
echo "==> Creating Packer template for Ubuntu AMD64"
cat > ubuntu-amd64.pkr.hcl << 'EOF'
packer {
  required_plugins {
    vagrant = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

# This is a special "null" builder that doesn't actually build a VM
# Instead, we'll use provisioners to set up our Vagrant environment
source "null" "ubuntu-amd64" {
  communicator = "none"
}

build {
  sources = ["source.null.ubuntu-amd64"]
  
  # Create Vagrantfile
  provisioner "shell-local" {
    inline = [
      "echo '==> Creating Vagrantfile'",
      "mkdir -p output",
      "cat > output/Vagrantfile << 'EOT'",
      "Vagrant.configure(\"2\") do |config|",
      "  config.vm.box = \"ubuntu/jammy64\"",
      "  config.vm.box_version = \"20250401.0.0\"",
      "",
      "  config.vm.provider \"virtualbox\" do |vb|",
      "    vb.memory = 2048",
      "    vb.cpus = 2",
      "    vb.customize [\"modifyvm\", :id, \"--clipboard-mode\", \"bidirectional\"]",
      "  end",
      "",
      "  # Forward a port for convenient web access if needed",
      "  config.vm.network \"forwarded_port\", guest: 80, host: 8080",
      "",
      "  # Display VM IP address when it boots",
      "  config.vm.provision \"shell\", run: \"always\", inline: <<-SHELL",
      "    echo \"\\033[0;32m\"",
      "    echo \"=============================================\"",
      "    echo \"VM is ready! Access information:\"",
      "    echo \"IP address: $(hostname -I | awk '{print $1}')\"",
      "    echo \"SSH: vagrant ssh\"",
      "    echo \"Username: vagrant\"",
      "    echo \"Password: vagrant\"",
      "    echo \"Web Server (if installed): http://localhost:8080\"",
      "    echo \"=============================================\"",
      "    echo \"\\033[0m\"",
      "  SHELL",
      "end",
      "EOT"
    ]
  }

  # Create setup script (Windows batch file)
  provisioner "shell-local" {
    inline = [
      "echo '==> Creating Windows setup script'",
      "cat > output/setup.bat << 'EOT'",
      "@echo off",
      "setlocal",
      "",
      "echo === Ubuntu AMD64 VM Setup ===",
      "",
      ":: Check for VirtualBox",
      "where VBoxManage >nul 2>&1",
      "if %ERRORLEVEL% neq 0 (",
      "  echo ERROR: VirtualBox not found. Please install VirtualBox and add it to your PATH.",
      "  goto :error",
      ")",
      "",
      ":: Check for Vagrant",
      "where vagrant >nul 2>&1",
      "if %ERRORLEVEL% neq 0 (",
      "  echo ERROR: Vagrant not found. Please install Vagrant and add it to your PATH.",
      "  goto :error",
      ")",
      "",
      ":: Add the box if not already added",
      "vagrant box list | findstr \"ubuntu/jammy64\" >nul",
      "if %ERRORLEVEL% neq 0 (",
      "  echo === Adding Ubuntu box ===",
      "  vagrant box add ubuntu/jammy64 --provider virtualbox",
      "  if %ERRORLEVEL% neq 0 goto :error",
      ")",
      "",
      ":: Start the VM",
      "echo === Starting Ubuntu VM ===",
      "vagrant up --provider=virtualbox",
      "if %ERRORLEVEL% neq 0 goto :error",
      "",
      "echo.",
      "echo === Success! ===",
      "echo Your Ubuntu VM is now running.",
      "echo To connect via SSH, type: vagrant ssh",
      "echo.",
      "goto :end",
      "",
      ":error",
      "echo.",
      "echo There was an error setting up the VM. Please check the error messages above.",
      "exit /b 1",
      "",
      ":end",
      "EOT"
    ]
  }

  # Create PowerShell version of setup script
  provisioner "shell-local" {
    inline = [
      "echo '==> Creating PowerShell setup script'",
      "cat > output/setup.ps1 << 'EOT'",
      "Write-Host \"=== Ubuntu AMD64 VM Setup ===\" -ForegroundColor Green",
      "",
      "# Check for VirtualBox",
      "if (-not (Get-Command \"VBoxManage\" -ErrorAction SilentlyContinue)) {",
      "    Write-Host \"ERROR: VirtualBox not found. Please install VirtualBox and add it to your PATH.\" -ForegroundColor Red",
      "    exit 1",
      "}",
      "",
      "# Check for Vagrant",
      "if (-not (Get-Command \"vagrant\" -ErrorAction SilentlyContinue)) {",
      "    Write-Host \"ERROR: Vagrant not found. Please install Vagrant and add it to your PATH.\" -ForegroundColor Red",
      "    exit 1",
      "}",
      "",
      "# Add the box if not already added",
      "$boxExists = vagrant box list | Select-String \"ubuntu/jammy64\"",
      "if (-not $boxExists) {",
      "    Write-Host \"=== Adding Ubuntu box ===\" -ForegroundColor Cyan",
      "    vagrant box add ubuntu/jammy64 --provider virtualbox",
      "    if ($LASTEXITCODE -ne 0) {",
      "        Write-Host \"Error adding Vagrant box\" -ForegroundColor Red",
      "        exit 1",
      "    }",
      "}",
      "",
      "# Start the VM",
      "Write-Host \"=== Starting Ubuntu VM ===\" -ForegroundColor Cyan",
      "vagrant up --provider=virtualbox",
      "if ($LASTEXITCODE -ne 0) {",
      "    Write-Host \"Error starting VM\" -ForegroundColor Red",
      "    exit 1",
      "}",
      "",
      "Write-Host \"`nSuccess! Your Ubuntu VM is now running.\" -ForegroundColor Green",
      "Write-Host \"To connect via SSH, type: vagrant ssh`n\"",
      "EOT"
    ]
  }

  # Create README file
  provisioner "shell-local" {
    inline = [
      "echo '==> Creating README'",
      "cat > output/README.md << 'EOT'",
      "# Ubuntu AMD64 Vagrant Project for Windows",
      "",
      "This project sets up an Ubuntu 22.04 AMD64 virtual machine using Vagrant and VirtualBox.",
      "",
      "## Requirements",
      "",
      "- Windows 10/11 with Intel/AMD processor",
      "- VirtualBox installed",
      "- Vagrant installed",
      "",
      "## Getting Started",
      "",
      "1. Run the setup script:",
      "   - Double-click `setup.bat`, or",
      "   - Right-click `setup.ps1` and select \"Run with PowerShell\"",
      "",
      "2. Connect to the VM:",
      "   ```",
      "   vagrant ssh",
      "   ```",
      "",
      "3. When finished, you can stop the VM with:",
      "   ```",
      "   vagrant halt",
      "   ```",
      "",
      "4. Or destroy it completely:",
      "   ```",
      "   vagrant destroy",
      "   ```",
      "",
      "## Note for Students",
      "",
      "This VM is pre-configured with:",
      "- Ubuntu 22.04 LTS (AMD64)",
      "- 2GB RAM",
      "- 2 CPU cores",
      "- Port 80 forwarded to host port 8080",
      "- Username: vagrant",
      "- Password: vagrant",
      "- SSH enabled",
      "EOT"
    ]
  }
}
EOF

# Initialize and run Packer
echo "==> Initializing Packer"
packer init ubuntu-amd64.pkr.hcl

echo "==> Building with Packer"
packer build ubuntu-amd64.pkr.hcl

# Move to the output directory
cd output

# Display completion message
echo ""
echo "=================================================================="
echo "Setup complete! Your Ubuntu AMD64 environment for Windows is ready."
echo ""
echo "To start the VM, run setup.bat or setup.ps1 from the output directory:"
echo "  cd $PROJECT_DIR/output"
echo "  ./setup.bat   # Command Prompt"
echo "  ./setup.ps1   # PowerShell"
echo ""
echo "This will:"
echo "  1. Check for VirtualBox and Vagrant"
echo "  2. Add the Ubuntu AMD64 box if not already added"
echo "  3. Start the VM with VirtualBox"
echo "  4. Display connection information"
echo ""
echo "Once the VM is running, you can connect with:"
echo "  vagrant ssh"
echo "=================================================================="