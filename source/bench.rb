#This is an example bench file. A bench file is a ruby file where the
#physical setup information of the equipment used to run tests with the VATF
#is stored. A VATF user must taylor the bench file to match his/her hardware setup  
#All entries in the bench file must belong to the EquipmentInfo class. This class has the following
#methods and properties:
# Methods:
#   new(name,capabilities)
#     Constructor of the class takes two parameter as input:
#   	  name: string to associate an equipment with a given name
#       capabilities: used to differentiate equipment with the same "name" attribute but with different capabilities. 
#                               Zero or more capabilities can be specified, capabalities are separated by underscore '_'
#                               For more information about acceptable values see http://automation.telogy.design.ti.com/wiki/index.php?title=Cheat_Sheet

# MUST-HAVE DUT Equipment Properties (sorted by importance):
#   driver_class_name: string containing the name of the driver used to control an equipment.
#     dut = EquipmentInfo("am335x-evm", "linux")
#     dut.driver_class_name = "LinuxEquipmentDriver"   
#   serial_port: String to identify how the host pc connects to the DUT
#     dut.serial_port = '/dev/ttyS0'
#   serial_params: Serial port parameters for serial_port
#     dut.serial_params = {"baud" => 115200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
#   login: string containing the username used to login to an equipment if it is not done via telnet
#     dut.login = "root"
#   login_prompt: Regexp (regular expression) containing the pattern of the prompt expected to login in to an equipment
#     dut.login_prompt = /login:/
#   prompt: Regexp (regular expression) containing the pattern of the prompt expected after login in to an equipment 
#      dut.prompt = /root.*#/
#   boot_prompt: Regexp (regular expression) containing the pattern of the prompt in bootloader
#     dut.boot_prompt = /:>/     
#   nfs_root_path: string containing the path in the nfs host used by the equipment to run via nfs
#     dut.nfs_root_path = '/usr/workdir/filesys'
#   boot_load_address: Memory address where bootloader will be loaded 
#     dut.boot_load_address = '0x81000000'

# Other equipment Properties:
#   power_port: Hash whose key identifies the power_controller equipment and the value identifies the port 
#     dut.power_port = {'<power controller equipment info name'=> <power port associated with this DUT>}
#   telnet_ip: string containing the ip address used to connect to an equipment. For example
#     dut.telnet_ip = "111.222.333.444"
#   telnet_port: integer defining the port used to connect to an equipment.
#     dut.telnet_port = 2024   
#   telnet_login: string containing the username that will be used to login to an equipment via telnet, if an equipment requires to login for access. For example
#     dut.telnet_login = "root"
#   telnet_passwd: string containing the password that will be used to login to an equipment via telnet, if an equipment requires a password for access. For example
#     dut.telnet_passwd = "admin"
#   tftp_path: string containing the tftp root path
#     dut.tftp_path = '/tftpboot'
#   board_id: Name associated with a platform. Currently only used by Android and WinCE for devuce identification
#     dut.board_id = 'MY-DM365-BOARD'
#	  audio_hardware_info: data structure used to specify the audio hardware attributes in the VATF host. 
#	    The attributes supported in this data structure are:
#		    analog_audio_inputs: a comma separated string containing the ids assign by the
#				                 VATF host to the analog audio inputs
#            analog_audio_outputs: a comma separated string containing the ids assign by the
#				                 VATF host to the analog audio outputs
#            digital_audio_inputs: a comma separated string containing the ids assign by the
#				                 VATF host to the analog audio inputs
#            digital_audio_outputs: a comma separated string containing the ids assign by the
#				                   VATF host to the digital audio outputs
#            midi_audio_inputs: a comma separated string containing the ids assign by the
#				               VATF host to the midi audio inputs
#            midi_audio_ouputs: a comma separated string containing the ids assign by the
#				               VATF host to the midi audio outputs
#        An example containing all this attributes is							   
#	               dut = EquipmentInfo("dm365", "linux")
#				   dut.audio_hardware_info.analog_audio_inputs = "0,1"
#				   dut.audio_hardware_info.analog_audio_outputs = "0,1"
#				   dut.audio_hardware_info.digital_audio_inputs = "2,3"
#				   dut.audio_hardware_info.digital_audio_outputs = "2,3"
#				   dut.audio_hardware_info.midi_audio_inputs = "4"
#				   dut.audio_hardware_info.midi_audio_outputs	= "4"  
#	                       
#
#	  video_io_info: data structure containing the ids of the video inputs and outputs used by an equipment when connecting to other equipment through
#	                   a programmable video switch. The attributes supported in this data structure are vga_inputs, vga_outputs, component_inputs, component_outputs, composite_inputs, composite_outputs, svideo_inputs, \
#				       svideo_outputs, hdmi_inputs, hdmi_outputs, sdi_inputs, sdi_outputs, dvi_inputs, dvi_outputs, scart_inputs, scart_outputs. To specify an attribute in this
#                      data structure must be done with a hash were the key is the id number of a media_switch equipment specified somewhere else in the bench and the value
#                      is an array of the ids of the inputs used in the switch. For example
#	                   dut = EquipmentInfo("dm365", "linux")
#				       dut.video_io_info.component_inputs = {1 => [3]}
#					   dut.video_io_info.component_outputs = {1 => [3]}
#					   dut.video_io_info.composite_inputs = {0 => [22]}
#					   dut.video_io_info.composite_outputs = {0 => [8]}
					
#	  audio_io_info: data structure containing the ids of the video inputs and outputs used by an equipment when connecting to other equipment through
#	                   a programmable audio switch. The attributes supported in this data structure are rca_inputs, rca_outputs, xlr_inputs, xlr_outputs, optical_inputs, optical_outputs, mini35mm_inputs, mini35mm_outputs, \
#				       mini25mm_inputs, mini25mm_outputs, phoneplug_inputs, phoneplug_outputs. To specify an attribute in this
#                      data structure must be done with a hash were the key is the id number of a media_switch equipment specified somewhere else in the bench and the value
#                      is an array of the ids of the inputs used in the switch. For example
#	                   dut = EquipmentInfo("dm365", "linux")
#				       dut.audio_io_info.mini35mm_inputs = {0 => [15,13]}
#					   dut.audio_io_info.mini35mm_outputs = {0 => [5]}
					  
#NOTE: TO SPECIFY AN EQUIPMENT IN A BENCH FILE IT IS NOT NECESSARY TO SPECIFY
#      ALL THE ATTRIBUTES LISTED BEFORE ONLY THE ATTRIBUTES RELEVANT TO THAT EQUIPMENT ARE REQUIRED
#      FOR SOME EXAMPLES SEE BELOW

#############################################################
################# Most Typicall entries #####################
#############################################################
dut = EquipmentInfo.new("am335x-evm", "linux_sd_sdhc_usbhostmsc_usbhosthid_power")
dut.driver_class_name='LinuxEquipmentDriver'
dut.prompt = /[\w\d]+@.+[@:#]+/
dut.boot_prompt = /U-Boot#/
dut.first_boot_prompt = /TI-MIN/
dut.boot_load_address = '0x81000000'
dut.login = 'root'
dut.telnet_login = 'root'
dut.login_prompt = /login:/
dut.board_id='20100720'
dut.nfs_root_path = '/home/a0850405/NFS_exports/linux/arago-test'
dut.serial_port = '/dev/ttyUSB0'
dut.serial_params = {"baud" => 115200}
dut.power_port = {'apc.158.218.103.33' => 6}
dut.params = {'usb_port' => {'1' => 1}, 'multimeter1' => minfo}

#pwr = EquipmentInfo.new("power_controller", 0)
pwr = EquipmentInfo.new("power_controller", "apc.158.218.103.33")
pwr.telnet_ip = '158.218.103.45'
pwr.telnet_port = 23
#pwr.driver_class_name = 'ApcPowerController'
pwr.driver_class_name = 'StafApcPowerController'
pwr.telnet_login = 'apc'
pwr.telnet_passwd = 'apc'
pwr.params = {'staf_ip' => 'local'}

# Devantech / robot-electronics.co.uk relay.  Uses default port and user/pass
# This device is used to trigger the reset signal on a board, and the board
# is powered by something else.
pwr = EquipmentInfo.new("power_controller", "rly16.IP.ADDR")
pwr.telnet_ip = 'IP.ADDR'
pwr.driver_class_name = 'DevantechRelayController'

svr = EquipmentInfo.new("linux_server")
svr.tftp_path = '/tftpboot'
svr.driver_class_name = 'LinuxLocalHostDriver'
svr.telnet_login = 'a0850405'
svr.telnet_passwd = '95yMy512'
svr.telnet_ip = '158.218.103.10'
svr.prompt = /@@/

#############################################################
################ Other Test Equipment Samples ###############
#############################################################
# Keithley Multimeter
minfo = EquipmentInfo.new("multimeter1")
minfo.serial_port = '/dev/ttyUSB5'
minfo.serial_params = {"baud" => 19200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
minfo.driver_class_name = 'KeithleyMultiMeterDriver'
minfo.params = {'number_of_channels' => 40}

# MSP430-Based USB switch
usb = EquipmentInfo.new("usb_switch_controller", "1")
usb.serial_port = '/dev/ttyACM0'
usb.serial_params = {"baud" => 9600, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
usb.driver_class_name = 'TiUsbSwitch'

#Objective Speech Tester information
aud = EquipmentInfo.new("speech_tester")
aud.driver_class_name = "OperaForClr"
aud.telnet_ip = "10.218.111.209"

# Kvaser CAN Server
can_kvaser_host = EquipmentInfo.new("can","kvaser")
can_kvaser_host.telnet_bin_mode = false
can_kvaser_host.driver_class_name = "LinuxEquipmentDriver"
can_kvaser_host.telnet_ip = '10.218.103.117'
can_kvaser_host.telnet_port = 2424
can_kvaser_host.password_prompt = /password:.*/i
can_kvaser_host.prompt = /Documents/
can_kvaser_host.telnet_login = 'admintest'
can_kvaser_host.telnet_passwd = 'admin123Test'
can_kvaser_host.login_prompt = /login:/i

# DUT controlled via CCS/JTAG
dut = EquipmentInfo.new("am180x-evm", "ccs")
dut.driver_class_name='EquipmentDriver'
dut.prompt = /[\w\d]+@.+[@:#]+/
dut.telnet_ip='158.218.103.93'
dut.telnet_port=23
dut.boot_prompt = /U-Boot\s*>/m
dut.login = 'root'
dut.telnet_login = 'root'
dut.login_prompt = /login:/
dut.board_id='20100720'
dut.nfs_root_path = '/home/a0850405/NFS_exports/linux/4.01/am18x'
dut.power_port = {'apc.158.218.103.33' => 1}
dut.params = {'ccs_type'        => 'Ccsv5',
              'ccs_install_dir' => '/opt/ti/ccsv5',
              'ccs_workspace'   => '/home/a0850405/workspace_v5_1',
              'ccsConfig'       => '/home/a0850405/ti/CCSTargetConfigurations/c6748.ccxml',
              'gelFile'         => '/home/a0850405/ti/CCSTargetConfigurations/C6748.gel',
              'ccsPlatform'     => 'Spectrum Digital XDS510USB Emulator_0',
              'ccsCpu'          => 'C674X_0'}

#############################################################
########## Media connection equipment information ###########
#############################################################
#Composite switch Rack2
te = EquipmentInfo.new("media_switch",0)
te.telnet_ip = "10.0.0.200"
te.telnet_port = 23
te.driver_class_name = "VideoSwitch"

#Component switch Rack 3
te = EquipmentInfo.new("media_switch",1)
te.telnet_ip = "10.0.0.101"
te.telnet_port = 23
te.driver_class_name = "VideoSwitch"

#SDI switch Rack3
te = EquipmentInfo.new("media_switch",2)
te.telnet_ip = "10.0.0.102"
te.telnet_port = 23
te.driver_class_name = "VideoSwitch"

#TVs information
tv = EquipmentInfo.new("tv") #left tv
tv.video_io_info.composite_inputs = {0 => [25]}
tv.video_io_info.svideo_inputs = {0 => [25]}
tv.audio_io_info.mini35mm_inputs = {0 => [23]}
tv.video_io_info.component_inputs = {1 => [11]}

tv = EquipmentInfo.new("tv")  #right tv
tv.video_io_info.composite_inputs = {0 => [27]}
tv.video_io_info.svideo_inputs = {0 => [27]}
tv.audio_io_info.mini35mm_inputs = {0 => [23]}
tv.video_io_info.component_inputs = {1 => [12]}

# Camera Info
tv = EquipmentInfo.new("camera")
tv.video_io_info.composite_outputs = {0 => [28]}
tv.video_io_info.svideo_outputs = {0 => [28]}
tv.audio_io_info.mini35mm_outputs = {0 => [27]}  

# DVD players info
dvd = EquipmentInfo.new("dvd","pal")
dvd.video_io_info.composite_outputs = {0 => ["26"]}
dvd.video_io_info.svideo_outputs = {0 => ["26"]}
dvd.audio_io_info.mini35mm_outputs = {0 => ["26"]}

dvd = EquipmentInfo.new("dvd", "hd") # blue-ray
dvd.video_io_info.composite_outputs = {0 => ["26"]}
dvd.video_io_info.svideo_outputs = {0 => ["26"]}
dvd.video_io_info.component_outputs = {1 => ["15"]}
dvd.audio_io_info.mini35mm_outputs = {0 => ["7"]}

#Video clarity on Rack3
video_tester = EquipmentInfo.new("video_tester")
video_tester.telnet_ip = "10.0.0.57"
video_tester.driver_class_name = "VideoClarity"
video_tester.video_io_info.sdi_inputs = {2 => [16]}
video_tester.video_io_info.sdi_outputs = {2 => [16]}

#video clarity converters
conv = EquipmentInfo.new("component_converter","0")
conv.video_io_info.sdi_inputs = {2 => [15]}
conv.video_io_info.sdi_outputs = {2 => [15]}
conv.video_io_info.component_inputs = {1 => [16]}
conv.video_io_info.component_outputs = {1 => [16]}

conv = EquipmentInfo.new("composite_converter","0")
conv.video_io_info.sdi_inputs = {2 => [1]}
conv.video_io_info.sdi_outputs = {2 => [1]}
conv.video_io_info.composite_inputs = {0 => [26]}
conv.video_io_info.composite_outputs = {0 => [27]}
conv.video_io_info.svideo_inputs = {0 => [26]}
conv.video_io_info.svideo_outputs = {0 => [27]}

conv = EquipmentInfo.new("svideo_converter","0")
conv.video_io_info.sdi_inputs = {2 => [1]}
conv.video_io_info.sdi_outputs = {2 => [1]}
conv.video_io_info.svideo_inputs = {0 => [26]}
conv.video_io_info.svideo_outputs = {0 => [27]}
conv.video_io_info.composite_inputs = {0 => [26]}
conv.video_io_info.composite_outputs = {0 => [27]}
