#!/bin/bash
set -e

# Create project directory
PROJECT_DIR="ubuntu-arm64-project"
echo "==> Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create Packer template
echo "==> Creating Packer template for Ubuntu ARM64"
cat > ubuntu-arm64.pkr.hcl << 'EOF'
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
source "null" "ubuntu-arm64" {
  communicator = "none"
}

build {
  sources = ["source.null.ubuntu-arm64"]
  
  # Create Vagrantfile
  provisioner "shell-local" {
    inline = [
      "echo '==> Creating Vagrantfile'",
      "mkdir -p output",
      "cat > output/Vagrantfile << 'EOT'",
      "Vagrant.configure(\"2\") do |config|",
      "  config.vm.box = \"luminositylabsllc/bento-ubuntu-22.04-arm64\"",
      "  config.vm.box_version = \"20250301.01\"",
      "",
      "  config.vm.provider \"parallels\" do |prl|",
      "    prl.memory = 2048",
      "    prl.cpus = 2",
      "    prl.customize [\"set\", :id, \"--faster-vm\", \"on\"]",
      "  end",
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
      "    echo \"=============================================\"",
      "    echo \"\\033[0m\"",
      "  SHELL",
      "end",
      "EOT"
    ]
  }

  # Create setup script
  provisioner "shell-local" {
    inline = [
      "echo '==> Creating setup script'",
      "cat > output/setup.sh << 'EOT'",
      "#!/bin/bash",
      "set -e",
      "",
      "cd \"$(dirname \"$0\")\"",
      "",
      "# Check for vagrant-parallels plugin",
      "if ! vagrant plugin list | grep -q vagrant-parallels; then",
      "  echo \"==> Installing vagrant-parallels plugin\"",
      "  vagrant plugin install vagrant-parallels",
      "fi",
      "",
      "# Add the box if not already added",
      "if ! vagrant box list | grep -q luminositylabsllc/bento-ubuntu-22.04-arm64; then",
      "  echo \"==> Adding Ubuntu ARM64 box\"",
      "  vagrant box add luminositylabsllc/bento-ubuntu-22.04-arm64 --provider parallels",
      "fi",
      "",
      "# Start the VM",
      "echo \"==> Starting Ubuntu ARM64 VM\"",
      "vagrant up --provider=parallels",
      "",
      "# Display connection information",
      "echo \"==> VM is ready! You can connect with:\"",
      "echo \"    vagrant ssh\"",
      "EOT",
      "chmod +x output/setup.sh"
    ]
  }

  # Create README file
  provisioner "shell-local" {
    inline = [
      "echo '==> Creating README'",
      "cat > output/README.md << 'EOT'",
      "# Ubuntu ARM64 Vagrant Project",
      "",
      "This project sets up an Ubuntu 22.04 ARM64 virtual machine using Vagrant and Parallels.",
      "",
      "## Requirements",
      "",
      "- macOS with Apple Silicon (M1/M2/M3)",
      "- Parallels Desktop installed",
      "- Vagrant installed",
      "",
      "## Getting Started",
      "",
      "1. Run the setup script:",
      "   ```",
      "   ./setup.sh",
      "   ```",
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
      "- Ubuntu 22.04 LTS (ARM64)",
      "- 2GB RAM",
      "- 2 CPU cores",
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
packer init ubuntu-arm64.pkr.hcl

echo "==> Building with Packer"
packer build ubuntu-arm64.pkr.hcl

# Move to the output directory
cd output

# Display completion message
echo ""
echo "=================================================================="
echo "Setup complete! Your Ubuntu ARM64 environment is ready."
echo ""
echo "To start the VM, run:"
echo "  cd $PROJECT_DIR/output"
echo "  ./setup.sh"
echo ""
echo "This will:"
echo "  1. Install the vagrant-parallels plugin if needed"
echo "  2. Add the Ubuntu ARM64 box if not already added"
echo "  3. Start the VM with Parallels"
echo "  4. Display connection information"
echo ""
echo "Once the VM is running, you can connect with:"
echo "  vagrant ssh"
echo "=================================================================="