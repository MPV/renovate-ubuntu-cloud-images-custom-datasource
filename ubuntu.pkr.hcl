packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "qemu_accelerator" {
  type        = string
  default     = "kvm"
  description = "Qemu accelerator to use. On Linux use kvm and macOS use hvf."
}

variable "ubuntu_version" {
  type        = string
  default     = "jammy"
  description = "Ubuntu codename version (i.e. 20.04 is focal and 22.04 is jammy)"
}

variable "ubuntu_build_datever" {
  type        = string
  default     = "20241217"
  description = "Version of the released build, see: https://help.ubuntu.com/community/UEC/Images#Downloading_Daily_and_Released_Images"
}

source "qemu" "ubuntu" {
  accelerator      = var.qemu_accelerator
  cd_files         = ["./cloud-init/*"]
  cd_label         = "cidata"
  disk_compression = true
  disk_image       = true
  disk_size        = "10G"
  headless         = true
  iso_checksum     = "file:https://cloud-images.ubuntu.com/releases/${var.ubuntu_version}/release-${var.ubuntu_build_datever}/SHA256SUMS"
                   // i.e: https://cloud-images.ubuntu.com/releases/jammy/release-20241217/SHA256SUMS
  iso_url          = "https://cloud-images.ubuntu.com/releases/${var.ubuntu_version}/release-${var.ubuntu_build_datever}/ubuntu-${var.ubuntu_version}-server-cloudimg-amd64.img"
              // i.e: https://cloud-images.ubuntu.com/releases/jammy/release-20241217/ubuntu-22.04-server-cloudimg-amd64.img
  output_directory = "output-${var.ubuntu_version}"
  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  ssh_password     = "ubuntu"
  ssh_username     = "ubuntu"
  vm_name          = "ubuntu-${var.ubuntu_version}.img"
  qemuargs = [
    ["-m", "2048M"],
    ["-smp", "2"],
    ["-serial", "mon:stdio"],
  ]
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    // run scripts with sudo, as the default cloud image user is unprivileged
    execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    // NOTE: cleanup.sh should always be run last, as this performs post-install cleanup tasks
    scripts = [
      "scripts/install.sh",
      "scripts/cleanup.sh"
    ]
  }
}
