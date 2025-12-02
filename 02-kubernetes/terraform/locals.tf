locals {
  ssh_public_key = file("~/.ssh/aglubuchik.pub")
  
  instance_metadata = {
    serial-port-enable = 1
    ssh-keys           = "ubuntu:${local.ssh_public_key}"
    user-data          = data.template_file.cloudinit.rendered
  }
}
