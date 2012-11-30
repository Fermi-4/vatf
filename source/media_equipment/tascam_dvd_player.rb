require 'net/telnet'
require File.dirname(__FILE__)+'/dvd_player'

module MediaEquipment
  class TascamDvdPlayer < DvdPlayer
    public

      #Constructor of the class. Takes dvd_info a data structure with the equipment information (equipment_info), and log_path path were the 
      #log file will be stored (string).
      def initialize(dvd_info, log_path = nil)
        load_tables
        start_logger(log_path) if log_path
        log_info("Starting DVD session")
        @streamSock = Net::Telnet::new('Host'       => dvd_info.telnet_ip,
                                       'Port'       => dvd_info.telnet_port,
                                       'Timeout'    => 10,
                                       'Telnetmode' => false)
        cmd_handler("init_command")
	#	go_to_menu
	#	sleep 20
	#	play
	#	while /MODs:4/.match(get_dvd_status)
	#		sleep 20
	#		play
	#	end
      end
      
      #This function powers the dvd player on or off. Takes on (boolean) if true turns on the dvd player, otherwise turns the dvd player off.
      def power(on)
        if on
          cmd_handler("power_on")
          go_to_menu
        else
          cmd_handler("power_off")
        end
      end
      
      #This function will cause the dvd to start playing the movie.
      def play
        cmd_handler("play")
      end
      
      #This function will make the dvd player to move to the track/chapter specified. Takes chapter_number the number of the chapter to go to (number).
      def go_to_track(chapter_number)
        option = "G"+"0"*(3-chapter_number.to_s.length)+chapter_number.to_s
        @@cmd_table["go_to_trk"] = ["skp",option,true,Regexp.new("SKPs#{option}\\s*\\w{2}")]
        cmd_handler("go_to_trk")
      end
      
      #This function will make the dvd player to open or close it's tray.
      def open_close_dvd
        cmd_handler("open_close_tray")
      end
      
      #This function will ask the dvd player to retunr it's current status
      def get_dvd_status
        cmd_handler("status")
      end
      
      #This function stops the dvd player
      def stop
        cmd_handler("stop")
      end
      
      #This function causes the dvd player to go to the main menu.
      def go_to_menu
        stop
        cmd_handler("go_to_menu")
      end
      
       #Closes the telnet connection with the dvd
      def disconnect
        @streamSock.close if @streamSock
        ensure
        @streamSock = nil
      end
       
  private
      @@cmd_table = Hash.new()
      
      #This function load a table with the commands that can be sent to the dvd player.
      def load_tables
        @@cmd_table["pause"] = ["PLY","PAU",true]
        @@cmd_table["play"] = ["PLY","FWD",true,/MODs:4\s*BF/i]
        @@cmd_table["stop"] = ["STP","",true,/STPs\s*A8/i]
        @@cmd_table["fast_forward"] = ["PLY","FWD",true]
        @@cmd_table["open_close_tray"] = ["MED","EJC",true,/MEDsEJC\s*\w{2}/i]
        @@cmd_table["power_on"] = ["POW","ON",true,/POWsON\s*04/i]
        @@cmd_table["power_off"] = ["POW","OF",true]
        @@cmd_table["init_command"] = ["ini","",true]
        @@cmd_table["status"] = ["mod","",true]
        @@cmd_table["go_to_menu"] = ["mnu","t",true,/MNUsT\s*D5/i]
      end
         
      #This function translates a given cmd into dvd player messages. Takes cmd_array an array containing the command (string), commmand option (string) and status flag (boolean) as parameter.
      def send_cmd(cmd_array)
        preamble1= "\x02"
        preamble2= "\x3e"
        endByte  = "\x03"
        oper = cmd_array[0].upcase
        param = cmd_array[1].upcase
        (8-param.length).times do
          param = "#{param}\x20"
        end
        if cmd_array[2] == true then
          cmdFlag = "\x63"
        else
          cmdFlag = "\x73"
        end 
        tempCmd = %Q{#{preamble2}#{oper}#{cmdFlag}#{param}}
        charsum = 0
        tempCmd.each_byte {|c| charsum += c}
        checksum = ("%x" % charsum)
        
        checksum = checksum.slice(checksum.length-2,checksum.length-1)
        cmdtoSend = "#{preamble1}#{tempCmd}#{checksum.upcase}#{endByte}"
        log_info("Host: "+cmdtoSend.to_s)
        cmdtoSend
      end 
    
    #This function performs the communication operation with the dvd player. Takes the comd_to_send the command to be performed (string), option associated with the command as parameters.
    def cmd_handler(cmd_to_send)
      cmd = @@cmd_table[cmd_to_send]
      dvd_response = nil
      @streamSock.write(send_cmd(cmd))
      if cmd[3]
        @streamSock.write(send_cmd(@@cmd_table["status"]))
        @streamSock.waitfor('Match' => cmd[3], 'Timeout' => 60) do |data_received|
          log_info("DVD: "+data_received)
          dvd_reponse = data_received
        end
      elsif cmd_to_send == "status" 
        @streamSock.waitfor('Match' => /.{17}/)do |data_received|
            dvd_response = data_received
        end
            log_info("DVD: "+dvd_response.to_s)
      end 
        sleep 10
        dvd_response     
      rescue Exception => e
        log_error(e.to_s)
        raise
    end
  end

end     

