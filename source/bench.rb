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

# MUST-HAVE DUT EquipmentInfo Properties (sorted by importance):
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
EquipmentInfo.new("am335x-evm", "linux_sd_sdhc_usbhostmsc_usbhosthid_power") do
  driver_class_name='LinuxEquipmentDriver'
  prompt = /[\w\d]+@.+[@:#]+/
  boot_prompt = /U-Boot#/
  first_boot_prompt = /TI-MIN/
  boot_load_address = '0x81000000'
  login = 'root'
  telnet_login = 'root'
  login_prompt = /login:/
  board_id='20100720'
  nfs_root_path = '/home/a0850405/NFS_exports/linux/arago-test'
  serial_port = '/dev/ttyUSB0'
  serial_params = {"baud" => 115200}
  power_port = {'apc.158.218.103.33' => 6}
  # if using multiple power_ports - one to power cycle, another to power reset for example
  # use an array as given below
  #power_port = [{'apc.xxx.xxx.xxx.33' => 6},{'rly16.IP.ADDR' => 3}]
  params = {'usb_port' => {'1' => 1}, #to specify the usb switch connected to the board 
            'multimeter1' => minfo, #to specify the multimeter connected to the board
            'usbethaddr' => '11:22:33:44:55', #to specify (if the adapter does not have a mac address) the mac address of a usb to ethernet adapter connected to the board
            'rootfs_partuuid' => '00000000-02', # to specify partuuid for rootfs partition on mmc or other boot media. 
            'gpio_wakeup_port' => {'rly16.192.168.0.40' => 2}, # To define relay port connected to GPIO pin to wakeup DUT. Use same syntax as power_port.
            'AP_SSID' => 'TRENDnet666N', # to define AP SSID for wifi tests
            'sysboot_ctrl' => bootc,  # to define the sysboot controller
            }
end

bootc = EquipmentInfo.new("sysboot_controller", "rly16.192.168.0.60")
bootc.telnet_ip = '192.168.0.60'
bootc.driver_class_name = 'DevantechRelayController'

EquipmentInfo.new("power_controller", "apc.158.218.103.33") do
  telnet_ip = '158.218.103.45'
  telnet_port = 23
  #driver_class_name = 'ApcPowerController'
  driver_class_name = 'StafApcPowerController'
  telnet_login = 'apc'
  telnet_passwd = 'apc'
  params = {'staf_ip' => 'local'}
end

# Devantech / robot-electronics.co.uk relay.  Uses default port and user/pass
# This device is used to trigger the reset signal on a board, and the board
# is powered by something else.
EquipmentInfo.new("power_controller", "rly16.IP.ADDR") do
  telnet_ip = 'IP.ADDR'
  driver_class_name = 'DevantechRelayController'
end

EquipmentInfo.new("linux_server") do
  tftp_path = '/tftpboot'
  driver_class_name = 'LinuxLocalHostDriver'
  telnet_login = 'a0850405'
  telnet_passwd = '95yMy512'
  telnet_ip = '158.218.103.10'
  prompt = /@@/
end

#############################################################
################ Other Test EquipmentInfo Samples ###############
#############################################################
# Keithley Multimeter
minfo = EquipmentInfo.new("multimeter") do
  serial_port = '/dev/ttyUSB5'
  serial_params = {"baud" => 19200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
  driver_class_name = 'KeithleyMultiMeterDriver'
  params = {'number_of_channels' => 40, 'conn_type' => "<'tcp_ip' or 'serial'>", 'card_slot' => 1}
end

# FTDI USB-to-I2C power meter integrated in J5/J6 boards
minfo = EquipmentInfo.new("multimeter") do
  telnet_ip = '158.218.101.68'   # IP Address of Server connected to USB-to-I2C power meter board
  telnet_port = 2000             # TCP Port where Server is listening 
  driver_class_name = 'FtdiMultimeterDriver'
  params = {'number_of_channels' => 24, 
                  'executable_path' => 'C:\code\usb_power\test\ina_j5eco\Debug\ina_j5eco.exe'}  # Path to executable on Server
end

# Multimeter based on Powertool (https://github.com/nmenon/powertool) 
# Powertool runs on a linux box whose I2C bus is connected to I2C bus on DUT where INA226 are located
minfo = EquipmentInfo.new("multimeter") do
  serial_port = '/dev/vatf@bbb1'
  serial_params = {"baud" => 115200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
  prompt = /[\w\d]+@.+[@:#]+/
  driver_class_name = 'PtoolDriver'
  params = {'executable_path' => '/home/root'}  # Location where ptool and configs/ are located
end

# MSP430-Based USB switch
EquipmentInfo.new("usb_switch_controller", "1") do
  serial_port = '/dev/ttyACM0'
  serial_params = {"baud" => 9600, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
  driver_class_name = 'TiUsbSwitch'
end

# MSP432-Based test gadget. Currently used to switch micro sd cards between host and dut
ti_test_gadget = EquipmentInfo.new("msp432", "0") do
  serial_port = '/dev/vatf@k2e-evm-msp432'
  serial_params = {"baud" => 115200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
  driver_class_name = 'TiMultiPurposeTestGadget'
end
dut.params = {'microsd_switch' => {ti_test_gadget => 'r' }, {'microsd_host_node' => '/dev/vatf@k2e-evm-sd-1'}}
# value 'r' or 'l' indicates side connected to DUT

#Objective Speech Tester information
EquipmentInfo.new("speech_tester") do
  driver_class_name = "OperaForClr"
  telnet_ip = "10.218.111.209"
end

# Kvaser CAN Server
EquipmentInfo.new("can","kvaser") do
  telnet_bin_mode = false
  driver_class_name = "LinuxEquipmentDriver"
  telnet_ip = '10.218.103.117'
  telnet_port = 2424
  password_prompt = /password:.*/i
  prompt = /Documents/
  telnet_login = 'admintest'
  telnet_passwd = 'admin123Test'
  login_prompt = /login:/i
end

# DUT controlled via CCS/JTAG
EquipmentInfo.new("am180x-evm", "ccs") do
  driver_class_name='EquipmentInfoDriver'
  prompt = /[\w\d]+@.+[@:#]+/
  telnet_ip='158.218.103.93'
  telnet_port=23
  boot_prompt = /U-Boot\s*>/m
  login = 'root'
  telnet_login = 'root'
  login_prompt = /login:/
  board_id='20100720'
  nfs_root_path = '/home/a0850405/NFS_exports/linux/4.01/am18x'
  power_port = {'apc.158.218.103.33' => 1}
  params = {'ccs_type'        => 'Ccsv5',
                'ccs_install_dir' => '/opt/ti/ccsv5',
                'ccs_workspace'   => '/home/a0850405/workspace_v5_1',
                'ccsConfig'       => '/home/a0850405/ti/CCSTargetConfigurations/c6748.ccxml',
                'gelFile'         => '/home/a0850405/ti/CCSTargetConfigurations/C6748.gel',
                'ccsPlatform'     => 'Spectrum Digital XDS510USB Emulator_0',
                'ccsCpu'          => 'C674X_0'}
end

#############################################################
########## Media connection equipment information ###########
#############################################################
#Composite switch Rack2
EquipmentInfo.new("media_switch",0) do
  telnet_ip = "10.0.0.200"
  telnet_port = 23
  driver_class_name = "VideoSwitch"
end

#Component switch Rack 3
EquipmentInfo.new("media_switch",1) do
  telnet_ip = "10.0.0.101"
  telnet_port = 23
  driver_class_name = "VideoSwitch"
end

#SDI switch Rack3
EquipmentInfo.new("media_switch",2) do
  telnet_ip = "10.0.0.102"
  telnet_port = 23
  driver_class_name = "VideoSwitch"
end

#TVs information
EquipmentInfo.new("tv") do #left tv
  video_io_info.composite_inputs = {0 => [25]}
  video_io_info.svideo_inputs = {0 => [25]}
  audio_io_info.mini35mm_inputs = {0 => [23]}
  video_io_info.component_inputs = {1 => [11]}
end

EquipmentInfo.new("tv") do #right tv
  video_io_info.composite_inputs = {0 => [27]}
  video_io_info.svideo_inputs = {0 => [27]}
  audio_io_info.mini35mm_inputs = {0 => [23]}
  video_io_info.component_inputs = {1 => [12]}
end

# Camera Info
EquipmentInfo.new("camera") do
  video_io_info.composite_outputs = {0 => [28]}
  video_io_info.svideo_outputs = {0 => [28]}
  audio_io_info.mini35mm_outputs = {0 => [27]}
end

# DVD players info
EquipmentInfo.new("dvd","pal") do
  video_io_info.composite_outputs = {0 => ["26"]}
  video_io_info.svideo_outputs = {0 => ["26"]}
  audio_io_info.mini35mm_outputs = {0 => ["26"]}
end

EquipmentInfo.new("dvd", "hd") do # blue-ray
  video_io_info.composite_outputs = {0 => ["26"]}
  video_io_info.svideo_outputs = {0 => ["26"]}
  video_io_info.component_outputs = {1 => ["15"]}
  audio_io_info.mini35mm_outputs = {0 => ["7"]}
end

#Video clarity on Rack3
EquipmentInfo.new("video_tester") do
  telnet_ip = "10.0.0.57"
  driver_class_name = "VideoClarity"
  video_io_info.sdi_inputs = {2 => [16]}
  video_io_info.sdi_outputs = {2 => [16]}
end

#video clarity converters
EquipmentInfo.new("component_converter","0") do
  video_io_info.sdi_inputs = {2 => [15]}
  video_io_info.sdi_outputs = {2 => [15]}
  video_io_info.component_inputs = {1 => [16]}
  video_io_info.component_outputs = {1 => [16]}
end

EquipmentInfo.new("composite_converter","0") do
  video_io_info.sdi_inputs = {2 => [1]}
  video_io_info.sdi_outputs = {2 => [1]}
  video_io_info.composite_inputs = {0 => [26]}
  video_io_info.composite_outputs = {0 => [27]}
  video_io_info.svideo_inputs = {0 => [26]}
  video_io_info.svideo_outputs = {0 => [27]}

EquipmentInfo.new("svideo_converter","0") do
  video_io_info.sdi_inputs = {2 => [1]}
  video_io_info.sdi_outputs = {2 => [1]}
  video_io_info.svideo_inputs = {0 => [26]}
  video_io_info.svideo_outputs = {0 => [27]}
  video_io_info.composite_inputs = {0 => [26]}
  video_io_info.composite_outputs = {0 => [27]}
end

#############################################################
########### Smartbits test equipment information ############
#############################################################
#Smartbits SAI job queuing host settings. 
# Note: To setup the SAI job queuing host please see the following wikipage link: http://automation.telogy.design.ti.com/wiki/index.php?title=How_to_set_up_a_SmartBits_SAI_job_queuing_host
sb1 = EquipmentInfo.new("smartbits", 'smartbits@1') #the 'smartbits@1' shown here is the STAF service id for the SAI job queuing STAF service running on the hosting PC.
sb1.driver_class_name = 'StafMartbitsSaiDriver'
sb1.params = {'staf_ip' => '158.218.104.255'}       #the 'staf_ip' is the IP address of the host PC running the SAI job queuing STAF service.

#Second Smartbits SAI job queuing host settings. Added to go with the DUT example below 
sb2 = EquipmentInfo.new("smartbits", 'smartbits@7') #the 'smartbits@7' shown here is the STAF service id for the SAI job queuing STAF service running on the hosting PC.
sb2.driver_class_name = 'StafMartbitsSaiDriver'
sb2.params = {'staf_ip' => '158.218.106.155'}       #the 'staf_ip' is the IP address of the host PC running the SAI job queuing STAF service.

#Example for DUT using Smartbits SAI job queuing host settings.
# The dut.params 'smartbits' section below is what is required for the DUT to be able to use the SmartBits. Only one instance of SmartBits is required. Below shows two SmartBits instances as an example.
dut = EquipmentInfo.new("k2hk-evm","linux_k2k_sbsai") #the 'sbsai' shown here is to indicate that the test setup has support for SmartBits SAI.
dut.driver_class_name = "LinuxTCI6638Driver"
dut.prompt = /[\w\d]+@.+:/m
dut.boot_prompt = /(K2HK|TCI6638)\sEVM/
dut.power_port = {'apc' => 6 }
dut.login = 'root'
dut.telnet_login = 'root'
dut.login_prompt = /login:/
dut.serial_server_ip = '192.168.1.2'
dut.serial_server_port = 6006
dut.nfs_root_path = '/opt/min-root-c6638-le'
dut.params = {'smartbits' => {'0' => {'sb_equip' => sb1,                # 'smartbits' = set of SmartBits parameters, '0' = DUT eth0 port, 'sb_equip' = Smartbits EquipmentInfo reference for this port
                                      'sb_port' => '0:6:0',             # 'sb_port' = SmartBits port to use (as would be referenced in the SAI configuration file)
                                      'sb_mac' => '00:11:22:33:44:55',  # 'sb_mac' = base MAC to use for SmartBits MACs on this port
                                      'sb_ip' => '192.168.1.120',       # 'sb_ip' = base IP address to use for SmartBits IPs on this port
                                      'dut_speed' => '1000',            # 'dut_speed' = Physical speed in Mbps of DUT's ethernet port
                                      'dut_ip' => 'dhcp'                # 'dut_ip' = IP address to use for DUT's ethernet port (dhcp = use received dhcp address)
                                    },
                              '1' => {'sb_equip' => sb1,                # '1' = DUT eth1 port, 'sb_equip' = SmartBits EquimentInfo reference
                                      'sb_port' => '0:8:0',
                                      'sb_mac' => '00:11:22:33:44:66',
                                      'sb_ip' => '192.168.2.120',
                                      'dut_speed' => '1000',
                                      'dut_ip' => '192.168.2.50'
                                    }
                              '4' => {'sb_equip' => sb2,                # '4' = DUT eth4 port, 'sb_equip' = SmartBits EquimentInfo reference for this port. Here we are specifying a second SmartBits chassis.
                                      'sb_port' => '0:2:0',
                                      'sb_mac' => '00:12:22:33:44:55',
                                      'sb_ip' => '192.168.3.120',
                                      'dut_speed' => '1000',
                                      'dut_ip' => '192.168.3.50'
                                    },
                              '5' => {'sb_equip' => sb2,                # '5' = DUT eth5 port, 'sb_equip' = SmartBits EquimentInfo reference for this port. Still referencing second SmartBits chassis.
                                      'sb_port' => '0:3:0', 
                                      'sb_mac' => '00:12:22:33:44:66',
                                      'sb_ip' => '192.168.4.120',
                                      'dut_speed' => '1000',
                                      'dut_ip' => '192.168.4.50'
                                    }
                            }
            }

# Sample entry for BeagleboneSingleTouchDriver use to validate touchscreen
touchinfo = EquipmentInfo.new("singletouch")
touchinfo.serial_port = '/dev/ttyUSB10'
touchinfo.serial_params = {"baud" => 115200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
touchinfo.prompt = /[\w\d]+@.+[@:#]+/
touchinfo.driver_class_name = 'BeagleboneSingleTouchDriver'
touchinfo.params = {'executable_path' => '/root', 'number_of_servos' => 3}

dut = EquipmentInfo.new("am437x-sk", "linux_sd_sdhc_singletouch")
...
dut.params = {'singletouch' => touchinfo}

# Sample bench entries to setup a Simulator-based DUT
dut = EquipmentInfo.new("amXXXX-evm", "linux")
dut.driver_class_name='LinuxSimulatorDriver'
dut.serial_server_ip = '192.168.0.1'
dut.serial_server_port = 51000 # This value will be replaced once simulator starts. It is OK to hardcode to any value in the bench.
dut.params = {'simulator_startup_cmd' => "cd /home/linux-integrated; ./utilities/simulator/.../startup -c -p ",
              'simulator_python_script' => "soc_core_linux.py"}


# Sample bench entries to setup TI's Automation Interface Driver
# Please note that 2 separate entries are required, one for multimeter
# and another one for power_controller as the driver supports both roles.
minfo = EquipmentInfo.new("multimeter")
minfo.serial_port = '/dev/ttyACM0'
minfo.serial_params = {"baud" => 115200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE, "flow_control" => SerialPort::NONE}
minfo.prompt = /=>/
minfo.driver_class_name = 'AutomationInterfaceDriver'
minfo.params = {'number_of_channels' => 40}

pwr = EquipmentInfo.new("power_controller", "autoiface.dra71x")
pwr.driver_class_name = 'AutomationInterfaceDriver'
pwr.serial_params = {"baud" => 115200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
pwr.serial_port = '/dev/ttyACM0'
pwr.prompt = /=>/m


dut = EquipmentInfo.new("dra71x-evm", "linux_sd_sdhc_usbhostmsc_power")
dut.driver_class_name='LinuxEquipmentDriver'
...
dut.power_port = {'autoiface.dra71x' => 1}
dut.params = {'multimeter1' => minfo}


# Sample bench entry for AM654x EVM with automation interface connected
# "multimeter" and "power_controller" can be defined as in previous dra71x-evm section
# Please note usage of 'sysboot_ctrl' to also signal that sysboot pins can be controlled on this setup
# AM654x also supports traces on 3 different uart consoles serial_port (main one), bootloader_port (R5) and firmware_port (M3)
# secondary_serial_port is used for platforms that output to a serial port other than the main one. For AM654x this is the 
# same port as the bootloader port, but that does not have to be the case for other platforms (e.g. J721E).
dut = EquipmentInfo.new("am654x-evm", "linux_sd_sdhc_usbdevice_power")
dut.driver_class_name='LinuxArm64Driver'
dut.serial_port = '/dev/ttyUSB6'
dut.power_port = {'autoiface.am654x' => 1}
dut.params = {'bootloader_port'=> '/dev/ttyUSB7', 'bootloader_serial_params' => dut.serial_params, 'bootloader_prompt' => /.*/,
              'firmware_port'=> '/dev/ttyUSB8', 'firmware_serial_params' => dut.serial_params, 'firmware_prompt' => /.*/,
              'secondary_serial_port'=> '/dev/ttyUSB7', 'secondary_serial_params' => dut.serial_params, 'secondary_serial_prompt' => /.*/,
              'multimeter1' => minfo,
              'sysboot_ctrl' => minfo}


#Sample bench entries for an Android vatf setup that is shared with a lava-dispatcher setup
dut = EquipmentInfo.new("amXXXX-evm", "android_linux")
dut.driver_class_name='AndriodEquipmentDriver'
dut.board_id = '12345678'
.... 
dut.params = {'lxc-info' => {'name' => 'lxc-vatf@am57xx-evm', #name for the lxc container that created should be system unique
                             'adb-device' => '/dev/vatf@android-am57xx-evm-adb', #symlink pointing to the usb connection used for adb connectivity, 
                                                                                 #to handle dev node reassignment on reboot it is best to create a udev rule based on th board_id value 
                                                                                 # SUBSYSTEM=="usb", ATTR{serial}=="12345678", MODE="0666", GROUP="plugdev", SYMLINK+="vatf@android-am57xx-evm-adb
                             #config entry below is optional and overrides the default lxc container config of ubuntu,xenial,systemd, amd64
                             #all these config value can be overrided from the build description with var_lxc_xxxx definition, i.e var_lxc_template=trusty
                             'config' => { 'template' => 'ubuntu', #optional
                                           'release' => 'xenial', #optional
                                           'packages' => ['systemd'], #optional
                                           'arch' => 'amd64' #optional
                                         } 
                            }
             }
