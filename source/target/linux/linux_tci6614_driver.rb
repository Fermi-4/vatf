require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'

module Equipment
  class LinuxTCI6614Driver < LinuxEquipmentDriver

    def set_api(dummy_var)
    end
    
    def get_boot_cmd(params)
      image_path = params['image_path']
      cmds = []
      cmds << "setenv bootcmd 'dhcp;tftp;bootm'"
      cmds << "setenv serverip '#{params['server'].telnet_ip}'"
      bootargs = params['bootargs'] ? "setenv bootargs #{params['bootargs']}" : "setenv bootargs #{@boot_args} root=/dev/nfs nfsroot=${nfs_root_path},v3,tcp rw"
      cmds << bootargs
      cmds
    end
    
  end
end
