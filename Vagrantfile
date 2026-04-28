Vagrant.configure("2") do |config|
  host_uid = Process.uid
  host_gid = Process.gid

  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "opencode-sandbox"
  config.vm.boot_timeout = 600

  # Disable default mapping of current folder to /vagrant.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.name = "opencode-sandbox"
    vb.cpus = ENV.fetch("VM_CPUS", "2")
    vb.memory = ENV.fetch("VM_MEMORY", "4096")
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.synced_folder "shared", "/workspace",
                          type: "virtualbox",
                          create: true,
                          mount_options: ["uid=#{host_uid}", "gid=#{host_gid}", "dmode=775", "fmode=664"]

  config.vm.provision "shell", path: "provision/bootstrap.sh", privileged: true
  config.vm.provision "shell", path: "provision/hardening.sh", privileged: true
  config.vm.provision "shell",
                      path: "provision/user_mapping.sh",
                      privileged: true,
                      reboot: true,
                      env: {
                        "HOST_UID" => host_uid.to_s,
                        "HOST_GID" => host_gid.to_s
                      }
end
