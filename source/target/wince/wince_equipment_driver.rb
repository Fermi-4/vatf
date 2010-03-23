require File.dirname(__FILE__)+'/../equipment_driver'
require 'socket'

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
      raise "Failed to boot. Make sure #{File.join(SiteInfo::UTILS_FOLDER, SiteInfo::WINCE_DOWNLOAD_APP)} exists on your VATF PC" if !system("#{File.join(SiteInfo::UTILS_FOLDER, SiteInfo::WINCE_DOWNLOAD_APP)} -i#{local_ip} -t#{@board_id} #{params['test_params'].kernel}")
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
    
    private
    
    # Implementation taken from stackoverflow.com
    # The [below] code does NOT make a connection or send any packets (to 64.233.187.99 which is google). 
    # Since UDP is a stateless protocol connect() merely makes a system call which figures out how to route the packets based on the address
    # and what interface (and therefore IP address) it should bind to. addr() returns an array containing the family (AF_INET), local port, and local address (which is what we want) of the socket.
    def local_ip
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

      UDPSocket.open do |s|
        s.connect '64.233.187.99', 1
        s.addr.last                  
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end

    
  end
end  