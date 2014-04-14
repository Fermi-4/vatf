require 'equipment_info'

EquipmentInfo.new("dm644x", 0) do
  driver_class_name = "LspTargetController"
  telnet_ip = '10.218.103.16'
  telnet_port = 7001
  telnet_login = ''
  login_prompt = /login/
  login = 'root'
  prompt = /#/
  boot_prompt = /#/
  power_port = 1
  usb_ip = '10.10.10.1'
end

EquipmentInfo.new("dm355", 0) do
  driver_class_name = "LspTargetController"
  telnet_ip = '192.168.1.2'
  telnet_port = 6001
  telnet_login = ''
  login_prompt = /login/
  login = 'root'
  prompt = /#/
  boot_prompt = />/
  power_port = 6
  usb_ip = '10.10.10.1'
end

EquipmentInfo.new("da8xx", 0) do
  driver_class_name = "LspTargetController"
  telnet_ip = '192.168.1.2'
  telnet_port = 6003
  telnet_login = ''
  login_prompt = /login/
  login = 'root'
  prompt = /#/
  boot_prompt = />/
  power_port = 4
  usb_ip = '10.10.10.1'
end

EquipmentInfo.new("dm357", 0) do
  driver_class_name = "LspTargetController"
  telnet_ip = '192.168.1.2'
  telnet_port = 6001
  telnet_login = ''
  login_prompt = /login/
  login = 'root'
  prompt = /#/
  boot_prompt = /#/
  power_port = 6
  usb_ip = '10.10.10.1'
end

EquipmentInfo.new("dm365", 0) do
  driver_class_name = "LspTargetController"
  telnet_ip = '10.218.103.16'
  telnet_port = 7004
  telnet_login = ''
  login_prompt = /login/
  login = 'root'
  prompt = /#/  # when nand as root fs, this is not going to work.
  boot_prompt = />/
  power_port = 3
  usb_ip = '10.10.10.1'
end

EquipmentInfo.new("dm6467", 0) do
  driver_class_name = "LspTargetController"
  telnet_ip = '192.168.1.2'
  telnet_port = 6002
  telnet_login = ''
  login_prompt = /login/
  login = 'root'
  prompt = /#/
  boot_prompt = /#/
  power_port = 3
  usb_ip = '10.10.10.1'
end

EquipmentInfo.new("raven2", 0) do
  driver_class_name = "LspTargetController"
  telnet_ip = '192.168.1.2'
  telnet_port = 6002
  telnet_login = ''
  login_prompt = /login/
  login = 'root'
  prompt = /#/
  executable_path = '/usr/local/bin'
  power_port = 7
end

EquipmentInfo.new("linux_server", 0) do
  driver_class_name = "LspTargetController"
  telnet_ip = '10.218.103.36'
  telnet_port = 23
  telnet_login = 'a0133059'
  telnet_passwd = 'mbpGH7Gn'
  prompt = /@/
  nfs_root_path = '/usr/workdir/filesys/mv_pro5'
  samba_root_path = "filesys\\mv_pro5"
  tftp_path = '/tftpboot'
end

EquipmentInfo.new("apc_power_controller", 0) do
  telnet_ip = '10.218.103.184'
  telnet_port = 23
  driver_class_name = "ApcPowerController"
  telnet_login  = 'apc'
  telnet_passwd = 'apc'
end

# for usb slave linux test
EquipmentInfo.new("host", 0) do
  driver_class_name = "HostController"
  telnet_ip = '10.218.103.12'
  telnet_port = 23
  telnet_login = 'a0133059'
  telnet_passwd = 'Yy4uuHT8'
  prompt = /\[a0133059@gtad8005 ~\]/
  nfs_root_path = '/usr/workdir/filesys/mv_pro5'
  samba_root_path = 'filesys\mv_pro5'
  tftp_path = '/tftpboot'
  executable_path = '/data'
end

EquipmentInfo.new("host", 1) do
  telnet_ip = "localhost"
  driver_class_name = "HostController"
  prompt = '>'
  executable_path = "C:\\VATF\\usbslave"
end
