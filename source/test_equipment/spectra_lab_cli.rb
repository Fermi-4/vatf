# -*- coding: ISO-8859-1 -*-
require 'drb/drb'

module TestEquipment
   
    class SpectraLab
        
        def initialize(equipment_info,log_path)
            DRb.start_service
            @spec_lab = DRbObject.new_with_uri("druby://"+equipment_info.telnet_ip.to_s+":"+equipment_info.telnet_port.to_s)
            @spec_lab.connect
        end
        
        def process_file(file_path)
            file_handle = File.new(file_path,'rb')
			file_data = file_handle.read
			@spec_lab.process_file(file_data)
        end
        
        def get_test_stat(stat)
            @spec_lab.get_test_stat(stat)
        end
        
        def get_test_stats
            @spec_lab.get_test_stats
        end
        
        def start_logger(log_path)
        end
        
        def stop_logger
        end
        
        def disconnect
            @spec_lab.disconnect
        end
        
    end
end