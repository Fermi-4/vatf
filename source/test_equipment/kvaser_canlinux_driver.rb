require File.dirname(__FILE__)+'/../target/linux/linux_equipment_driver'
require 'rubygems'
require 'net/ftp' 
require 'net/telnet'
####################
# Setup Information
####################

# Installation Instructions at http://opbuwiki.dal.design.ti.com/index.php/Farm#Kvaser_CAN_Equipment_Setup
# Bench entries should be as follows
#
#-------------- Kvaser CAN Device ------------------------------
#'server' below is name of linux server in bench file
#'exec_path' below is absolute path where kvaser canlib binaries are located in the tee server 
#can_kvaser_host = EquipmentInfo.new("can","kvaser")
#can_kvaser_host.driver_class_name = "KvaserLinuxDriver"
#can_kvaser_host.params = {'server'=>'server', 'exec_path'=>"/home/tidfarm-xx/canlib/examples"}
#can_kvaser_host.telnet_ip = '10.8.45.29'
#can_kvaser_host.telnet_port = 23
#can_kvaser_host.telnet_login = 'login_of_linux_tee'
#can_kvaser_host.telnet_passwd = 'telnet_password_of_linux_tee'
#can_kvaser_host.prompt = /prompt of linux_tee/m

# Hardware asset information - DUT should contain following entry as part of its hardware assets
#[can,kvaser]

# DUT bench entry should have:
#dut.params ={'kvaser_can_port'=>{'can0'=>0}, where can0 is can0 port on DUT and 0 refers to kvaser tool's port 0 or 1 to which can0 is connected.

module TestEquipment
  # This class controls basic functions used in the TiPowercontrollers, 
  # such as on, off, reboot, and get port status.  
  # The interactions from this driver can be logged using Log4r functionality
  class KvaserLinuxDriver < LinuxEquipmentDriver
  
         def bitrate_to_kvaser_value(params,data_flag=0)
         # Values from Kvaser CAN SDK code
         #  canBITRATE_1M = -1;
         #  canBITRATE_500K = -2;
         #  canBITRATE_250K = -3;
         #  canBITRATE_125K = -4;
         #  canBITRATE_100K = -5;
         #  canBITRATE_62K = -6;
         #  canBITRATE_50K = -7;
         #  canBITRATE_83K = -8;
         #  canBITRATE_10K = -9;

         #  canFD_BITRATE_500K_80P = -1000;
         #  canFD_BITRATE_1M_80P   = -1001;
         #  canFD_BITRATE_2M_80P   = -1002;
         #  canFD_BITRATE_4M_80P   = -1003;
         #  canFD_BITRATE_8M_60P   = -1004;
             canlegacy_hash=Hash.new
             canfd_hash=Hash.new
             canlegacy_hash={1000000=>-1, 500000=>-2, 250000=>-3, 125000=>-4, 100000=>-5, 62000=>-6, 50000=>-7, 83000=>-8, 10000=>-9}
             canfd_hash={500000=>-1000, 1000000=>-1001, 2000000=>-1002, 4000000=>-1003, 8000000=>-1004}
             if (params['can_type'] == "dcan")
                kvaserid=canlegacy_hash[params['baudrate']]
             else 
               if (data_flag == 0)
                  if (canfd_hash.has_key?(params['baudrate'])) 
                     kvaserid=canfd_hash[params['baudrate']]
                  else
                     return false
                  end
               else
                  if (canfd_hash.has_key?(params['databaudrate'])) 
                     kvaserid=canfd_hash[params['databaudrate']]
                  else
                     return false
                  end
               end
             end
             kvaserid
         end

         def check_channel(params)
             response=`cd #{@params['exec_path']};./listChannels|grep -i "ch *#{params['kvaser_channel']}"`
             if response.to_s.strip.empty?
                puts "Check kvaser tool connection to PC - the channel cannot be listed on PC"
                return false
             end
         end

         def transmit(params)
             if (params['can_type'] == "dcan")
                command="writeloop"
                if (bitrate_to_kvaser_value(params,0) == false)
                   return false
                else
                   `cd #{@params['exec_path']};timeout #{params['test_duration']} ./#{command} #{params['kvaser_channel']} #{bitrate_to_kvaser_value(params, 0)}`
                end
             else
                command="canfdwrite"
                #extended_command="_#{params['databaudrate']}"
                if (bitrate_to_kvaser_value(params,0) == false or bitrate_to_kvaser_value(params,1) == false)
                   return false
                else
                   for i in 1..params['test_duration'] do
                       `cd #{@params['exec_path']};timeout #{params['test_duration']} ./#{command} #{params['kvaser_channel']} #{bitrate_to_kvaser_value(params, 0)} #{bitrate_to_kvaser_value(params, 1)}`
             
                   end
                end
             end
         end

         def receive(params)
             @m1 = []
             sum_rate=0
             sum_error=0
             rx=0
             total=0
             if (params['can_type'] == "dcan")
                if (bitrate_to_kvaser_value(params,0) == false)
                   return false
                else
                   cmdline="cd #{@params['exec_path']};timeout #{params['test_duration']} ./cancount #{params['kvaser_channel']} #{bitrate_to_kvaser_value(params, 0)}"
                   response=`cd #{@params['exec_path']};timeout #{params['test_duration']} ./cancount #{params['kvaser_channel']} #{bitrate_to_kvaser_value(params, 0)}`
                   response.each_line{|line|
                       if (line.include? "msg/s")
                           m11 = /msg\/s\s*\S*\s*\d*/.match(line).to_s.gsub("msg/s",'').gsub('=','').strip
                           @m1 << m11.to_i
                       end
                       if (line.include? "err")
                           puts "line is #{line}"
                           m21= /\s*\S*err\s*=\s*\d*/.match(line).to_s.gsub("err",'').gsub('=','').strip
                           puts "m21 is #{m21}\n"
                           sum_error=sum_error+m21.to_i
                       end
                  }
                  @m1.shift
                  @m1.pop
                  mean_rate=@m1.inject{ |sum_rate, element| sum_rate + element }.to_f / @m1.size
                  output={"mean_rate"=>mean_rate,"sum_error"=>sum_error}
               end

           else
                if (bitrate_to_kvaser_value(params,0) == false or bitrate_to_kvaser_value(params,1) == false)
                   return false
                else
                   response=`cd #{@params['exec_path']};timeout #{params['test_duration']} ./canfdmonitor #{params['kvaser_channel']} #{bitrate_to_kvaser_value(params, 0)} #{bitrate_to_kvaser_value(params, 1)}`
                   response.each_line{|line|
                        if (line.include? "rx")
                           rx=/rx\s*:\s*\d*/.match(line).to_s.gsub("rx",'').gsub(':','').strip
                           @m1 << rx.to_i
                        end
                        if (line.include? "total")
                           total=/total\s*:\s*\d*/.match(line).to_s.gsub("total",'').gsub(':','').strip
                        end
                   }
                   @m1.shift
                   @m1.pop
                   mean_rx=@m1.inject{ |sum_rx, element| sum_rx + element }.to_f / @m1.size
                   output={"mean_rx"=>mean_rx,"total"=>total}
                end
           end
      
     end
end
end

