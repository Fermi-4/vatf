#This is an example bench file. A bench file is a ruby file where the
#physical setup information of the equipment used to run tests with the VATF
#is stored. A VATF user must taylor the bench file to match his/her hardware setup  
#All entries in the bench file must belong to the EquipmentInfo class. This class has the following
#methods and properties:
#   Methods
#     new(name,capabilities/id)
#     Constructor of the class takes two parameter as input:
#    	 name: string to associate an equipment with a given name
#         capabilities or id: used to differentiate equipment with the same "name" attribute but with different capabilities. 

#    Properties
#	  telnet_ip: string containing the ip address used to connect to an equipment. For example
#	  		     video_te = EquipmentInfo("video_te",0)
#	  			video_te.telnet_ip = "111.222.333.444"
#	  telnet_port: integer defining the port used to connect to an equipment.
#	              video_te = EquipmentInfo("video_te",0)
#				   ideo_te.telnet_port = 2024	  
#	  driver_class_name: string containing the name of the driver used to control an equipment.
#	               video_te = EquipmentInfo("video_te",0)
#				   video_te.driver_class_name = "PioneerDvdPlayer"	  
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
#	               video_te = EquipmentInfo("video_te",0)
#				   video_te.audio_hardware_info.analog_audio_inputs = "0,1"
#				   video_te.audio_hardware_info.analog_audio_outputs = "0,1"
#				   video_te.audio_hardware_info.digital_audio_inputs = "2,3"
#				   video_te.audio_hardware_info.digital_audio_outputs = "2,3"
#				   video_te.audio_hardware_info.midi_audio_inputs = "4"
#				   video_te.audio_hardware_info.midi_audio_outputs	= "4"  
#	                       
#	  telnet_login: string containing the username that will be used to login to an equipment via telnet, if an equipment requires to login for access. For example
#	               video_te = EquipmentInfo("video_te",0)
#				   video_te.telnet_login = "root"
#	  telnet_passwd: string containing the password that will be used to login to an equipment via telnet, if an equipment requires a password for access. For example
#	               video_te = EquipmentInfo("video_te",0)
#				   video_te.telnet_passwd = "admin"
#	  prompt: Regexp (regular expression) containing the pattern of the prompt expected after login in to an equipment 
#	               video_te = EquipmentInfo("video_te",0)
#				   video_te.prompt = /root.*#/
#    boot_prompt: egexp (regular expression) containing the pattern of the prompt in bootloader
#                   dut = EquipmentInfo("dm365",0)
#                    dut.boot_prompt = /:>/     
#	  executable_path: string containing the path, with respect to the root directory of the equipment, were the executables required by an equipment are placed
#	               video_te = EquipmentInfo("video_te",0)
#				   video_te.executable_path = "/opt/dvsdk/dm355"
#	  nfs_root_path: string containing the path in the nfs host used by the equipment to run via nfs
#	               video_te = EquipmentInfo("video_te",0)
#				   video_te.nfs_root_path = '/usr/workdir/filesys'
#	  samba_root_path: string containg a path, with respect to the VATF host, with the smb shared provided by the equipment
#	               video_te = EquipmentInfo("video_te",0)
#				   video_te.samba_root_path = "\\\\10.218.111.201\\mv_pro5_08\\filesys"
# login: string containing the username used to login to an equipment if it is not done via telnet
#               video_te = EquipmentInfo("video_te",0)
#                   video_te.login = "root"
# login_prompt: Regexp (regular expression) containing the pattern of the prompt expected to login in to an equipment
#               video_te = EquipmentInfo("video_te",0)
#                   video_te.login_prompt = /Login:/
# power_port: Hash whose key identifies the power_controller equipment and the value identifies the port 
#               video_te = EquipmentInfo("video_te",0)
#                   video_te.power_port = {'0'=> 6}
# tftp_path: string containing the tftp root path
#             video_te = EquipmentInfo("video_te",0)
#                   video_te.tftp_path = '/tftpboot'
# tftp_ip: string containing the ip address of tftp server
# video_te = EquipmentInfo("video_te",0)
# video_te.tftp_ip = "111.222.333.444"
#	  video_io_info: data structure containing the ids of the video inputs and outputs used by an equipment when connecting to other equipment through
#	                   a programmable video switch. The attributes supported in this data structure are vga_inputs, vga_outputs, component_inputs, component_outputs, composite_inputs, composite_outputs, svideo_inputs, \
#				       svideo_outputs, hdmi_inputs, hdmi_outputs, sdi_inputs, sdi_outputs, dvi_inputs, dvi_outputs, scart_inputs, scart_outputs. To specify an attribute in this
#                      data structure must be done with a hash were the key is the id number of a media_switch equipment specified somewhere else in the bench and the value
#                      is an array of the ids of the inputs used in the switch. For example
#	                   video_te = EquipmentInfo("video_te",0)
#				       video_te.video_io_info.component_inputs = {1 => [3]}
#					   video_te.video_io_info.component_outputs = {1 => [3]}
#					   video_te.video_io_info.composite_inputs = {0 => [22]}
#					   video_te.video_io_info.composite_outputs = {0 => [8]}
					
#	  audio_io_info: data structure containing the ids of the video inputs and outputs used by an equipment when connecting to other equipment through
#	                   a programmable audio switch. The attributes supported in this data structure are rca_inputs, rca_outputs, xlr_inputs, xlr_outputs, optical_inputs, optical_outputs, mini35mm_inputs, mini35mm_outputs, \
#				       mini25mm_inputs, mini25mm_outputs, phoneplug_inputs, phoneplug_outputs. To specify an attribute in this
#                      data structure must be done with a hash were the key is the id number of a media_switch equipment specified somewhere else in the bench and the value
#                      is an array of the ids of the inputs used in the switch. For example
#	                   video_te = EquipmentInfo("video_te",0)
#				       video_te.audio_io_info.mini35mm_inputs = {0 => [15,13]}
#					   video_te.audio_io_info.mini35mm_outputs = {0 => [5]}
					  
#NOTE: TO SPECIFY AN EQUIPMENT IN A BENCH FILE IT IS NOT NECESSARY TO SPECIFY ALL THE ATTRIBUTES LISTED BEFORE ONLY THE ATTRIBUTES RELEVANT TO THAT EQUIPMENT ARE REQUIRED
#FOR SOME EXAMPLES SEE BELOW


# DUTs
# DM365 located at Rack 3, shelf3
dut = EquipmentInfo.new("dm365")
dut.driver_class_name = "LinuxDm365Driver"
dut.video_io_info.composite_inputs = {0 => [11]}
dut.video_io_info.composite_outputs = {0 => [11]}
dut.video_io_info.svideo_inputs = {0 => [17]}
dut.video_io_info.component_inputs = {1 => [3]}
dut.video_io_info.component_outputs = {1 => [3]}
dut.audio_io_info.mini35mm_inputs = {0 => [25]}
dut.audio_io_info.mini35mm_outputs = {0 => [25]}
dut.telnet_ip = '10.0.0.100'
dut.telnet_port = 6011
dut.executable_path = '/drop2'
dut.prompt = /root.*#/m
dut.boot_prompt = /DM365\s*EVM\s*>/m
dut.login = 'root'
dut.telnet_login = 'root'
dut.login_prompt = 'login'
dut.nfs_root_path = '/usr/workdir/filesys/dvsdk_310/dm365'
dut.samba_root_path = "\\\\10.218.111.201\\filesys\\dvsdk_310\\dm365"
dut.power_port = {0 => 7}

# Freon board located at Rack 2, shelf3
dut = EquipmentInfo.new("omapl138")
dut.driver_class_name = "LinuxOmapL13xDriver"
dut.telnet_ip = '10.0.0.100'
dut.telnet_port = 6008
dut.executable_path = '/drop1'
dut.prompt = /root.*#/
dut.boot_prompt = /Boot\s*>/
dut.login = 'root'
dut.telnet_login = 'root'
dut.login_prompt = 'login'
dut.nfs_root_path = '/usr/workdir/filesys/freon/'
dut.samba_root_path = "\\\\10.218.111.201\\filesys\\freon"
dut.power_port = {0 => 3}

# Media connection equipment information

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
# tv.video_io_info.composite_inputs = {0 => [30]}
# tv.audio_io_info.mini35mm_inputs = {0 => [30]}
tv.video_io_info.composite_inputs = {0 => [25]}
tv.video_io_info.svideo_inputs = {0 => [25]}
tv.audio_io_info.mini35mm_inputs = {0 => [23]}
tv.video_io_info.component_inputs = {1 => [11]}

tv = EquipmentInfo.new("tv")  #right tv
# tv.video_io_info.composite_inputs = {0 => [31]}
# tv.audio_io_info.mini35mm_inputs = {0 => [31]}
tv.video_io_info.composite_inputs = {0 => [27]}
tv.video_io_info.svideo_inputs = {0 => [27]}
#tv.audio_io_info.mini35mm_inputs = {0 => [27]}
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
#dvd.driver_class_name = "PioneerDvdPlayer"
#dvd.telnet_ip = "10.0.0.100"
#dvd.telnet_port = 6002

dvd = EquipmentInfo.new("dvd","ntsc")
dvd.video_io_info.composite_outputs = {0 => ["29"]}
dvd.video_io_info.svideo_outputs = {0 => ["29"]}
dvd.audio_io_info.mini35mm_outputs = {0 => ["29"]}
#dvd.driver_class_name = "PioneerDvdPlayer"
#dvd.telnet_ip = "10.0.0.100"]
#dvd.telnet_port = 6001

dvd = EquipmentInfo.new("dvd", "hd") # blue-ray
dvd.video_io_info.composite_outputs = {0 => ["26"]}
dvd.video_io_info.svideo_outputs = {0 => ["26"]}
dvd.video_io_info.component_outputs = {1 => ["15"]}
#dvd.audio_io_info.mini35mm_outputs = {1 => ["17"]}
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

#Power controller 1 on rack 3
te = EquipmentInfo.new("power_controller", 0)
te.telnet_ip = '10.0.0.60'
te.telnet_port = 23
te.driver_class_name = "ApcPowerController"
te.telnet_login = 'apc'
te.telnet_passwd = 'apc'

#Audio equipment Information
audio_controller = EquipmentInfo.new("audio_player")
audio_controller.driver_class_name = "AudioCard"
audio_controller.audio_hardware_info.analog_audio_inputs = "0"
audio_controller.audio_hardware_info.analog_audio_outputs = "0"
audio_controller.audio_io_info.mini35mm_inputs = {0 => [27]}
audio_controller.audio_io_info.mini35mm_outputs = {0 => [27]}

#Objective Speech Tester information
aud = EquipmentInfo.new("speech_tester")
aud.driver_class_name = "OperaForClr"
aud.telnet_ip = "10.218.111.209"

#Linux Host
linux_server = EquipmentInfo.new("linux_server")
linux_server.driver_class_name = "LinuxEquipmentDriver"
linux_server.telnet_ip = '10.218.111.201'
linux_server.telnet_port = 23
linux_server.telnet_login = 'mylogin'
linux_server.telnet_passwd = 'mypassword'
linux_server.prompt = /\$@@/m
linux_server.boot_prompt = /\$/m
linux_server.nfs_root_path = '/usr/workdir/filesys/'
linux_server.samba_root_path = "filesys"
linux_server.tftp_path = '/tftpboot'

