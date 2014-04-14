require 'equipment_info'

dut = EquipmentInfo.new("dm644x",0)
dut.driver_class_name = "LspTargetController"
dut.telnet_ip = '10.218.103.16'
dut.telnet_port = 7001
dut.telnet_login = ''
dut.login_prompt = /login/
dut.login = 'root'
dut.prompt = /#/
dut.boot_prompt = /#/
dut.power_port = 1
dut.usb_ip = '10.10.10.1' 

dut = EquipmentInfo.new("dm355",0)
dut.driver_class_name = "LspTargetController"
dut.telnet_ip = '192.168.1.2'
dut.telnet_port = 6001
dut.telnet_login = ''
dut.login_prompt = /login/
dut.login = 'root'
dut.prompt = /#/
dut.boot_prompt = />/
dut.power_port = 6
dut.usb_ip = '10.10.10.1' 

dut = EquipmentInfo.new("da8xx",0)
dut.driver_class_name = "LspTargetController"
dut.telnet_ip = '192.168.1.2'
dut.telnet_port = 6003
dut.telnet_login = ''
dut.login_prompt = /login/
dut.login = 'root'
dut.prompt = /#/
dut.boot_prompt = />/
dut.power_port = 4
dut.usb_ip = '10.10.10.1' 

dut = EquipmentInfo.new("dm357",0)
dut.driver_class_name = "LspTargetController"
dut.telnet_ip = '192.168.1.2'
dut.telnet_port = 6001
dut.telnet_login = ''
dut.login_prompt = /login/
dut.login = 'root'
dut.prompt = /#/
dut.boot_prompt = /#/
dut.power_port = 6
dut.usb_ip = '10.10.10.1' 

dut = EquipmentInfo.new("dm365",0)
dut.driver_class_name = "LspTargetController"
dut.telnet_ip = '10.218.103.16'
dut.telnet_port = 7004
dut.telnet_login = ''
dut.login_prompt = /login/
dut.login = 'root'
dut.prompt = /#/  # when nand as root fs, this is not going to work.
dut.boot_prompt = />/
dut.power_port = 3
dut.usb_ip = '10.10.10.1' 

dut = EquipmentInfo.new("dm6467",0)
dut.driver_class_name = "LspTargetController"
dut.telnet_ip = '192.168.1.2'
dut.telnet_port = 6002
dut.telnet_login = ''
dut.login_prompt = /login/
dut.login = 'root'
dut.prompt = /#/
dut.boot_prompt = /#/
dut.power_port = 3
dut.usb_ip = '10.10.10.1' 


dut = EquipmentInfo.new("raven2",0)
dut.driver_class_name = "LspTargetController"
dut.telnet_ip = '192.168.1.2'
dut.telnet_port = 6002
dut.telnet_login = ''
dut.login_prompt = /login/
dut.login = 'root'
dut.prompt = /#/
dut.executable_path = '/usr/local/bin'
dut.power_port = 7

linux_server = EquipmentInfo.new("linux_server", 0) 
linux_server.driver_class_name = "LspTargetController"
linux_server.telnet_ip = '10.218.103.36'
linux_server.telnet_port = 23
linux_server.telnet_login = 'a0133059'
linux_server.telnet_passwd = 'mbpGH7Gn'
linux_server.prompt = /@/
linux_server.nfs_root_path = '/usr/workdir/filesys/mv_pro5'
linux_server.samba_root_path = "filesys\\mv_pro5"
linux_server.tftp_path = '/tftpboot'

te = EquipmentInfo.new("apc_power_controller", 0) 
te.telnet_ip = '10.218.103.184'
te.telnet_port = 23
te.driver_class_name = "ApcPowerController"
te.telnet_login  = 'apc'
te.telnet_passwd = 'apc'

# for usb slave linux test
linux_server = EquipmentInfo.new("host", 0)
linux_server.driver_class_name = "HostController"
linux_server.telnet_ip = '10.218.103.12'
linux_server.telnet_port = 23
linux_server.telnet_login = 'a0133059'
linux_server.telnet_passwd = 'Yy4uuHT8'
linux_server.prompt = /\[a0133059@gtad8005 ~\]/
linux_server.nfs_root_path = '/usr/workdir/filesys/mv_pro5'
linux_server.samba_root_path = 'filesys\mv_pro5'
linux_server.tftp_path = '/tftpboot'
linux_server.executable_path = '/data'

hst = EquipmentInfo.new("host",1)
hst.telnet_ip = "localhost"
hst.driver_class_name = "HostController"
hst.prompt = '>'
hst.executable_path = "C:\\VATF\\usbslave"
