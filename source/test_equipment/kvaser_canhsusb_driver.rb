require File.dirname(__FILE__)+'/../target/linux/linux_equipment_driver'
#require File.dirname(__FILE__)+'/../os_func'
require 'rubygems'
require 'net/ftp' 
require 'net/telnet'
####################
# Setup Information
####################
# Bench entries should be as follows
#
#-------------- Kvaser CAN Device ------------------------------
#can_kvaser_host = EquipmentInfo.new("can","kvaser")
#can_kvaser_host.telnet_bin_mode = false
#can_kvaser_host.driver_class_name = "KvaserHSUSBDriver"
#can_kvaser_host.params={'root'=>'C:\\\"Program Files\"\\Kvaser\\canking','shared_path'=>'canking','linux_mount_point'=>'/mnt/kvaser','windows_mount_point'=>'W\:','shared_root'=>'kvaser'}
#can_kvaser_host.telnet_ip = '10.218.103.117'
#can_kvaser_host.telnet_port = 2424
#can_kvaser_host.password_prompt = /password:.*/i
#can_kvaser_host.prompt = /Documents/
#can_kvaser_host.telnet_login = 'admintest'
#can_kvaser_host.telnet_passwd = 'admin123Test'
#can_kvaser_host.login_prompt = /login:/i
#can_kvaser_host.timeout = 30

# Hardware asset information - DUT should contain following entry as part of its hardware assets
#[can,kvaser]

# When registering TEE on staf, it is advisable to include the mounting commands so that the Kvaser server gets mounted on the linux TEE. Following are the commands recommended to be entered when sending staf registration commands
#sudo umount /mnt/kvaser
#sudo mount -t smbfs -o username=a0133110,domain=ENT,uid=1000,gid=1000 //10.218.103.117/canking /mnt/kvaser 
# In above sudo mount command, first enter linux user password at first password prompt, followed by windows ENT password of the user logged into Kvaser server

module TestEquipment
  # This class controls basic functions used in the TiPowercontrollers, 
  # such as on, off, reboot, and get port status.  
  # The interactions from this driver can be logged using Log4r functionality
  class KvaserHSUSBDriver < LinuxEquipmentDriver
 
	 def create_vbscript(params)
		  baud_rate = params['baudrate']
		  direction = params['direction']
		  duration = params['test_duration']
		  #can_version = params['can_version'] # for future expansion
		  #data_length = params['data_length_in_bytes'] # for future expansion
		  kvaser_root = @params['root']
		  if direction == "tx"
			  kvaser_config_script_name = "rx"
		  else
			  kvaser_config_script_name = "tx"
		  end
		  kvaser_config_script_name = kvaser_config_script_name+'_'+baud_rate.to_s+'.wcc'
		  if (OsFunctions::is_linux?)
		  #puts "Entered linux option and linux_temp_folder is #{SiteInfo::LINUX_TEMP_FOLDER}\n"
		     kvaser_vbscript = File.new(File.join( SiteInfo::LINUX_TEMP_FOLDER,'can_kvaser.vbs'),'w')
		  else
		     kvaser_vbscript = File.new(File.join(@wince_temp_folder,'can_kvaser.vbs'),'w')
		  end
			kvaser_vbscript.puts("set c = CreateObject(\"wc32.Main\")")
			kvaser_vbscript.puts("c.OpenConfig(\"c:\\#{kvaser_config_script_name}\")")
			kvaser_vbscript.puts("c.StartRunning")
			kvaser_running_time = (duration.to_i)+20
			puts "Kvaser Running Time is #{kvaser_running_time}\n"
			kvaser_vbscript.puts("WScript.Sleep(#{kvaser_running_time})")
			kvaser_vbscript.puts("c.StopRunning")
			kvaser_vbscript.puts("set c = Nothing")
			kvaser_vbscript.close
		end
	 def transfer_kvaser_script(params)
	   if (OsFunctions::is_linux?)
		   kvaser_mount_point = @params['linux_mount_point']
		   system("cp #{File.join(SiteInfo::LINUX_TEMP_FOLDER,'can_kvaser.vbs')} #{kvaser_mount_point}")
		 else
		   system("net use W: /delete")
			 system("Y")
			 can_ip = params['kvaser_server'].params['telnet_ip']
			 sleep 10
			 response = system("net use W: \\\\#{can_ip.to_s}\\canking")
			 system("copy #{File.join(@wince_temp_folder,'can_kvaser.vbs').gsub('/','\\')} W:")
		end
	end
    
    def start_kvaser_script(params)
		  puts "\n start_kvaser_script"
		  kvaser_root = @params['root'] # Get this from equipment **TBD**
		  command = "start cscript //nologo #{kvaser_root}\\can_kvaser.vbs"
			puts "Command sent to CAN server is #{command}\n"
		  if respond_to?(:telnet_port) and respond_to?(:telnet_ip) and !target.telnet
		    connect({'type'=>'telnet'})
		  else  
		    raise "You need Telnet connectivity to the Kvaser CAN Server. Please check your bench file" 
		  end
		#puts "Command sent to CAN server is #{command}\n"
		send_cmd(command, />/,1)
		sleep 10 # to ensure kvaser tool is started before script is called from target
	 end	
 end    
end

