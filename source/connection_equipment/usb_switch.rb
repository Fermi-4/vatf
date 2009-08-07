require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module ConnectionEquipment
include Log4r
=begin
This class allows the user to control the extron USB switch via a telnet session.
=end
  class UsbSwitch
    Logger = Log4r::Logger
    private
      @@ESC = "\x1B"
			@@SPC = "\x20"
      @@error_response_table = Hash.new()
      @@switch_message_table = Hash.new()
      
      #Loads the switch's error responsed into a table
      def load_error_response_table
        @@error_response_table["E01"]="Invalid input channel number (too large)"
        @@error_response_table["E10"]="Invalid command"
        @@error_response_table["E13"]="Invalid value (out of range)"
      end
   
      #Loads the switch generated messages into a table   
      def load_switch_message_table
        @@switch_message_table["conn_established"]=/^E\d+/i
				@@switch_message_table["exe_mode"] = /Exe(\d)/i
      end
      
			public
			#Starts the logger for the session. Takes the log file path as parameter.
      def start_logger(file_path)
        if @switch_log
          stop_logger
        end
        Logger.new('switch_log')
        @switch_log_outputter = Log4r::FileOutputter.new("switch_log_out",{:filename => file_path.to_s , :truncate => false})
        @switch_log = Logger['switch_log']
        @switch_log.level = Log4r::DEBUG
        @switch_log.add  @switch_log_outputter
        @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
        @switch_log_outputter.formatter = @pattern_formatter     
      end
      
      #Stops the logger.
      def stop_logger
          @switch_log_outputter = nil if @switch_log_outputter
          @switch_log = nil if @switch_log
      end

      
      #Constructor of the class loads the message and response tables; makes a connections if switch connection parameters are specified; and starts the logger 
      #if the log file path is specified.
      def initialize(switch_info,log_path = nil)
			  load_error_response_table
        load_switch_message_table     
        start_logger(log_path) if log_path
        connect(switch_info.telnet_ip, switch_info.telnet_port) if switch_info.telnet_ip && switch_info.telnet_port 
      end

      #Establishes a telnet connection with the switch. Takes the switch's IP address and port number as parmaters.
      def connect(ip_address, port)
        @switch_log.info("Starting switch session") if @switch_log
        @telnet_socket = Net::Telnet.new('Host' => ip_address,
                                          'Port' => port,
                                          'Timeout' => 10)
                                          #'WaitFor' => @@switch_message_table["conn_established"])
        @switch_log.info("Connected to the switch") if @switch_log
				rescue Exception => e
          @switch_log.error("Error login into the switch\n"+e.to_s) 
          raise
      end
      
      #Closes the telnet connection with the switch
      def disconnect
        @telnet_socket.close if @telnet_socket
        ensure
        @telnet_socket = nil
      end
      
      #Connects the usb input port to the output port/hub.
      #Takes the input number (1 based); and an ouput or an array of ouputs and ranges as parameters.
      def connect_port(input)
        send_cmd("#{input}^",/usb#{input}/i)
      end
			
			#Locks/Unlocks the switch's front panel
      def lock_front_panel(lock)
        if lock
          cmd = "1X"
        else
          cmd = "0X"
        end
        response_captures = send_cmd(cmd,@@switch_message_table["exe_mode"])
        if response_captures[0].to_i != 0 && response_captures[0].to_i != 1
          raise "Reset switch was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end

      #Sends a command to the switch and waits for a response containing/matching the regular expression expected_expression.
      #Takes the command to send as a parameter (see  switch documentation for allowed commands), and the expected regular expression.
      #Returns an array containing all the grouping specified in the regular expression.
      def send_cmd(cmd_to_send,expected_expression)
        resp_captures = nil
        @switch_log.info("Host: "+cmd_to_send) if @switch_log
        @telnet_socket.print(cmd_to_send)
				@telnet_socket.waitfor("Match" => expected_expression)do |rcv_data|
          @switch_log.info("Switch:"+rcv_data)
          /E\d{2}/i =~ rcv_data
          raise @@error_response_table[Regexp.last_match(0)] if Regexp.last_match(0)
        end
        rescue Exception => e
          @switch_log.error("On command "+cmd_to_send+"\n"+e.to_s)
          raise
      end

  end  
end



