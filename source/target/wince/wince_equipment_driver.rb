require File.dirname(__FILE__)+'/../equipment_driver'
#require File.dirname(__FILE__)+'/wince_eboot_options'

module Equipment

  class WinceEquipmentDriver < EquipmentDriver

   Boot_Menu = {'boot_device'=>{'val'=>'2', 'submenu'=>{'ethernet'=>'1','usb'=>'2','nand'=>'3'}},
             'network_settings'=>{'val'=>'4','submenu' =>{'dhcp'=>'5','ip_address'=>'6','ip_mask'=>'7'}},
             'save_settings' =>{'val'=>'7'},
             'show_current_settings' =>{'val'=>'1'},
             'debug_device'=>{'val'=>'3','submenu'=>{'lan'=>'1','usb'=>'2'}}
             }
             
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
    end
    
    def boot (params)
      @power_handler = params['power_handler'] if !@power_handler
      puts "Power cycling the board ........\n\n\n"
      @power_handler.reset(@power_port)
      # Call mpc-data executable or call boot staf process. Raise exception if booting fails.                                                                     
      raise "Failed to boot" if !system("#{File.join(SiteInfo::UTILS_FOLDER, SiteInfo::WINCE_DOWNLOAD_APP)} -i158.218.103.25 -tFREON-CARLOS #{params['test_params'].kernel}")
    end
    
    # stop the bootloader after a reboot
    def stop_boot(sp)
      0.upto 3 do
        send_cmd('\s', sp)
      end
    end
     # Reboot the unit to the bootloader prompt
    
    # def set_param(command)
     # command_array = Array.new
     # menu = {}.merge(Boot_Menu)
     # command.each {|cmd|
       # if (menu != nil)
       # menu.has_key? (cmd) ? command_array << menu[cmd]['val'] : command_array<<cmd
       # menu.has_key? (cmd) ? menu = menu[cmd]['submenu'] : menu = nil   
       # else
       # command_array<<cmd
       # end
       # command_array
      # }	
    # end
    
    
    
  end
end  