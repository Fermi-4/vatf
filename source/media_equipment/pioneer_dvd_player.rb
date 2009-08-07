require 'net/telnet'
require 'media_equipment/dvd_player'

module MediaEquipment
  class PioneerDvdPlayer < DvdPlayer
    public

      #Constructor of the class. Takes dvd_info a data structure with the equipment information (equipment_info), and log_path path were the 
      #log file will be stored (string).
      def initialize(dvd_info, log_path = nil)
        
        start_logger(log_path) if log_path
        log_info("Starting DVD session")
        @streamSock = Net::Telnet::new('Host'       => dvd_info.telnet_ip,
                                       'Port'       => dvd_info.telnet_port,
                                       'Timeout'    => 10,
                                       'Telnetmode' => false)
        #Commented until dvd is used in automated mode
        #stop if !/^P01/.match(get_dvd_mode)
        # go_to_menu
        #  sleep 20
        #while /^M2/.match(get_title_number)do
        #  enter
        #  sleep 20
        #end       
      end
      
      #This function powers the dvd player on or off. Takes on (boolean) if true turns on the dvd player, otherwise turns the dvd player off.
      def power(on)
        if on
          cmd_handler("SA")       
        end
      end
      
      #This function will cause the dvd to start playing the movie.
      def play
        cmd_handler("PL")
      end
      
      #This function will cause the dvd to stop playing the movie.
      def stop
        cmd_handler("RJ")
      end
      
      #This function will cause the dvd to move the cursor to the right in a menu
      def move_cursor_right
        cmd_handler("4CU")
      end
      
      #This function will cause the dvd to move the cursor to the left in a menu
      def move_cursor_left
        cmd_handler("3CU")
      end
      
      #This function will cause the dvd to move the cursor up in a menu
      def move_cursor_up
        cmd_handler("1CU")
      end
      
      #This function will cause the dvd to move the cursor down in a menu
      def move_cursor_down
        cmd_handler("2CU")
      end
      
      #This function will make the dvd player to move to the track/chapter specified. Takes chapter_number the number of the chapter to go to (number).
      def go_to_track(chapter_number)
        cmd_handler("CH"+chapter_number.to_s+"SL")
        #play
      end
      
      #This function will cause the dvd to move one frame forward
      def step_forward
       cmd_handler("SF")     
      end
      
      #This function will cause the dvd to move one frame back
      def step_reverse
        cmd_handler("SR")
      end
      
      #This function will cause the dvd to scan forward until scan_stop is called
      def scan_forward
        cmd_handler("NF")
      end
      
      #This function will cause the dvd to scan backwards until scan_stop is called
      def scan_reverse
        cmd_handler("NR")
      end
      
      #This function will cause the dvd to stop scanning
      def scan_stop
        cmd_handler("NS")
      end
      
      #This function will open the DVD's tray.
      def open_dvd
        cmd_handler("OP")
      end
      
      #This function will close the DVD's tray.
      def close_dvd
        cmd_handler("CO")
      end
      
      #This function will ask the dvd player to retunr it's current status
      def get_dvd_status
       cmd_handler("?V",/\w+/)
      end
      
      #This function requests the chapter number
      def get_dvd_chapter_number
       cmd_handler("?C",/\d+/)
      end
      
      #This function resturns the current p-block information 
      def get_p_block_info
        cmd_handler("?A",/\w+/)
      end
      
      #This function returns the title number of the dvd being played
      def get_title_number
        cmd_handler("?R",/\w+/)
      end
      
      #This function pauses the dvd player
      def pause
       cmd_handler("ST")
      end
      
      #This function causes the dvd player to go to the main menu.
      def go_to_menu
        cmd_handler("2MC")
      end
      
      #This function sets the subtitle used when playin the movie. Takes subtitle (string) the type of subtitle to be played as parameter.
      #Valid subtitle values are: off, english, spanish or french
      def set_subtitle(subtitle)
        subtitle_type = {"off" => 0,
                         "english" => 1,
                         "spanish" => 2,
                         "french" => 3,
                         }
        cmd_handler(subtitle_type[subtitle.strip.downcase].to_s+"SU")
      end
      
      #This function will cause the dvd to select a button from the menu. It emulates pressing the enter button in the dvd controls
      def enter
        cmd_handler("ET")
      end
      
      #This function returns the dvd's current active mode
      def get_dvd_mode
        cmd_handler("?P",/\w+/)
      end
      
      #This function will cause the dvd to enter repeat mode
      def repeat
        cmd_handler("RM")
      end
            
       #Closes the telnet connection with the dvd
      def disconnect
        @streamSock.close if @streamSock
        ensure
        @streamSock = nil
      end
       
 private
           
      @@error_table = {"E00" => "Communication Error",
                       "E04" => "Feature not available",
                       "E06" => "Missing argument",
                       "E11" => "Disc not exist",
                       "E12" => "Search Error",
                       "E15" => "Picture Stop",
                       "E16" => "Interrupt by other device",
                       "E99" => "Fatal error received"
                      }              
      #This function translates a given cmd into dvd player messages. Takes cmd_array an array containing the command (string), commmand option (string) and status flag (boolean) as parameter.
      
        
    
    #This function performs the communication operation with the dvd player. Takes the comd_to_send the command to be performed (string), option associated with the command as parameters.
    def cmd_handler(cmd_to_send, exp_resp = /R/)
        log_info("Host: "+cmd_to_send)
        dvd_response = nil
      @streamSock.cmd("String" => cmd_to_send.upcase, "Match" => exp_resp) do |recv_data|
        log_info("DVD: "+recv_data)
        dvd_response = recv_data
        raise @@error_table[recv_data.gsub("\r","")] if @@error_table[recv_data.gsub("\r","")]
      end
        dvd_response
      rescue Exception => e
        log_error(e.to_s)
        raise
    end
  end

end     

