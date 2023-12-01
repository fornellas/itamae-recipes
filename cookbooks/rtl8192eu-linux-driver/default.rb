package "dkms"

git "/var/lib/rtl8192eu-linux-driver" do
  user "root"
  revision "realtek-4.4.x"
  repository "https://github.com/Mange/rtl8192eu-linux-driver"
end

file "/var/lib/rtl8192eu-linux-driver/Makefile" do
  action :edit
  block do |content|
    i386_pc_from = "CONFIG_PLATFORM_I386_PC = y"
    i386_pc_to = "CONFIG_PLATFORM_I386_PC = n"
    arm_aarch64_from = "CONFIG_PLATFORM_ARM_AARCH64 = n"
    arm_aarch64_to = "CONFIG_PLATFORM_ARM_AARCH64 = y"
    lines = []
    content.split("\n").each do |line|
        case line
        when i386_pc_from
            lines.append(i386_pc_to)
        when arm_aarch64_from
            lines.append(arm_aarch64_to)
        else
            lines.append(line)
        end
    end
    content.replace(lines.join("\n"))
  end
end

execute "dkms add ." do
  user "root"
  cwd "/var/lib/rtl8192eu-linux-driver/"
  not_if "dkms status | grep -E '^rtl8192eu/1.0.*'"
end

execute "dkms install rtl8192eu/1.0" do
  user "root"
  cwd "/var/lib/rtl8192eu-linux-driver/"
  not_if "dkms status | grep -E '^rtl8192eu/1.0.*: installed'"
end

file "/etc/modprobe.d/rtl8xxxu.conf" do
    mode "640"
    owner "root"
    group "root"
    content "blacklist rtl8xxxu"
end

execute "rmmod rtl8xxxu" do
  user "root"
  only_if "lsmod |grep ^rtl8xxxu "
end

