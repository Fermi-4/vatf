require 'net/telnet'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module ConnectionEquipment
include Log4r
=begin
This class allows the user to control the extron video switch via a telnet session.
=end
  class VideoSwitch
    Logger = Log4r::Logger
    private
      @@ESC = "\x1B"
      @@RGB_CHAR = "&"
      @@VIDEO_CHAR = "%"
      @@AUDIO_CHAR = "$"
      @@AV_CHAR = "!"
      @@SEP_CHAR = "*"
      @@error_response_table = Hash.new()
      @@switch_message_table = Hash.new()
      
      #Loads the switch's error responsed into a table
      def load_error_response_table
        @@error_response_table["E01"]="Invalid input channel number (too large)"
        @@error_response_table["E10"]="Invaid command"
        @@error_response_table["E11"]="Invalid preset number"
        @@error_response_table["E12"]="Invalid output number"
        @@error_response_table["E13"]="Invalid value (out of range)"
        @@error_response_table["E14"]="Illegal command for this configuration"
        @@error_response_table["E17"]="Timeout (caused by direct write of global preset)"
        @@error_response_table["E21"]="Invalid room number"
        @@error_response_table["E24"]="Privilege violation (Ethernet, Extron software only)"
      end
   
      #Loads the switch generated messages into a table   
      def load_switch_message_table
        @@switch_message_table["conn_established"]=/^(C)Copyright\s*\d{4},\s*Extron\s*Electronics,\s*[-\w]+,\s*V\d+\.\d+/i
        @@switch_message_table["password"] = /^Password:/i
        @@switch_message_table["login"] = /^Login\s*(User|Administrator)/i
        @@switch_message_table["quick_connect"] = /^Qik/i
        @@switch_message_table["mem_preset"] = /^Spr(\d+)/i
        @@switch_message_table["gain_change"] = /^In(\d+)\s*Aud((?:-|\+)\d+)/i
        @@switch_message_table["vol_change"] = /^Out(\d+)\s*Vol(\d+)/i
        @@switch_message_table["video_mute"] = /^Vmt(\d+)\s*\*(\d+)/i
        @@switch_message_table["audio_mute"] = /^Amt(\d+)\s*\*(\d+)/i
        @@switch_message_table["audio_muted"] = /^Amt(\d+)/i
        @@switch_message_table["video_muted"] = /^Vmt(\d+)/i
        @@switch_message_table["executive_mode"] = /^Exe(\d+)/i
        @@switch_message_table["connect_to"] =/^Out(\d+)\s*In(\d+)\s*(\w+)/i
        @@switch_message_table["connect_all"] = /^In(\d+)\s*(\w+)/i
        @@switch_message_table["connected_to"] = /^(\d+)/i
        @@switch_message_table["input_frequencies"] = /^([\d\.]+),([\d\.]+)/i
        @@switch_message_table["input_gain"] = /^((?:-|\+)\d+)/i
        @@switch_message_table["output_rgb_delay"] = /^(\d+)/i
        @@switch_message_table["rgb_delay"] = /^Out(\d+)\s*Dly(\d+)/i
        @@switch_message_table["outputs_muted"] = /(\d+)/i
        @@switch_message_table["output_volume"] = /^(\d+)/i
        @@switch_message_table["reset_response"] = /Zp(.)/i
        @@switch_message_table["exe_mode"] = /Exe(\d)/i
        @@switch_message_table["is_muted"] = /^(0|1)/i
        @@switch_message_table["mute_all"] = /^(?:Amt|Vmt)\s*(0|1)/i  
      end
      
      #Generic connection command. Connects an input's audio, video, or both (audio and video) signals to all outputs. Takes the connection type
      #audio ("$"), video("%") or both ("!"); input number, an array or value of outputs; and the expected response as arguments.
      def connect_to(cmd_suffix, input, output_ranges, response_check)
        if output_ranges.kind_of?(Array)
          cmd = @@ESC+"+Q"
          0.upto(output_ranges.length-1) do |arr_index|
            range_match = /(\d+)(?:-(\d+)){0,1}/.match(output_ranges[arr_index].to_s)
            start_channel = end_channel = range_match.captures[0].to_i
            end_channel = range_match.captures[1].to_i if range_match.captures[1]
            start_channel.upto(end_channel) do |out_index|
              cmd = cmd + input.to_s + @@SEP_CHAR + out_index.to_s + cmd_suffix
            end
          end
          send_cmd(cmd,@@switch_message_table["quick_connect"])
        else
          cmd = input.to_s + @@SEP_CHAR + output_ranges.to_s + cmd_suffix
          response_captures = send_cmd(cmd,@@switch_message_table["connect_to"])
          if response_captures[0].to_i != output_ranges || response_captures[1].to_i != input || response_captures[2].downcase != response_check
            raise "Connection was not acknowledge by the switch.\n"+response_captures.to_s
          end
        end  
      end
      
      #Generic connect all command. Connects an input's audio, video, or both (audio and video) signals to all outputs. Takes the connection type
      #audio ("$"), video("%") or both ("!"); input number; and the expected response as arguments.
      def connect_all(cmd_suffix, input, response_check)
        cmd = input.to_s + @@SEP_CHAR + cmd_suffix
        response_captures = send_cmd(cmd,@@switch_message_table["connect_all"])
        if response_captures[0].to_i != input || response_captures[1].downcase != response_check
          raise "Connection was not acknowledge by the switch.\n"+response_captures.to_s
        end  
      end
      
      #Generic get connection information function. Gets the video or audio input that is connected to the given ouput.
      #Takes the output number and signal type as parameter.
      def get_connection(output, connection_type)
        cmd = output.to_s + connection_type
        response_captures = send_cmd(cmd,@@switch_message_table["connected_to"])
        response_captures[0].to_i
      end
      
      public 
=begin      
      #Constructor of the class loads the message and response tables; makes a connections if switch connection parameters are specified; and starts the logger 
      #is the log file path is specified.
      def initialize(ip_address = nil,port = nil,log_path = nil)
        load_error_response_table
        load_switch_message_table     
        start_logger(log_path) if log_path
        connect(ip_address,port) if ip_address && port 
      end
=end

      #Constructor of the class loads the message and response tables; makes a connections if switch connection parameters are specified; and starts the logger 
      #if the log file path is specified.
      def initialize(switch_info,log_path = nil)
        load_error_response_table
        load_switch_message_table     
        start_logger(log_path) if log_path
        connect(switch_info.telnet_ip,switch_info.telnet_port) if switch_info.telnet_ip && switch_info.telnet_port 
      end

      #Establishes a telnet connection with the switch. Takes the switch's IP address and port number as parmaters.
      def connect(ip_address, port)
        @switch_log.info("Starting switch session") if @switch_log
        @telnet_socket = Net::Telnet.new('Host' => ip_address,
                                          'Port' => port,
                                          'Timeout' => 10,
                                          'WaitFor' => @@switch_message_table["conn_established"])
        @switch_log.info("Login into the switch") if @switch_log
        @telnet_socket.waitfor(@@switch_message_table["password"])do |recv_data|
          response_captures = send_cmd("gguser",@@switch_message_table["login"])
          if response_captures[0].downcase != "administrator"
            raise "Unable to login correctly to switch\n"+recv_data
          end
        end      
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
         
      #Connects the video and audio signals of an input to one or more outputs.
      #Takes the input number (1 based); and an ouput or an array of outputs and ranges as parameters.   
      def connect_video_audio(input,ranges)
        connect_to(@@AV_CHAR, input, ranges, "all")
      end
      
      #Disconnects the given output(s)' audio and video signals from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_video_audio(output_ranges)
        connect_to(@@AV_CHAR, 0, output_ranges, "all")
      end
      
      #Connects the video signal of an input to one or more outputs.
      #Takes the input number (1 based); and an ouput or an array of ouputs and ranges as parameters.
      def connect_video(input, ranges)
        connect_to(@@VIDEO_CHAR, input, ranges, "vid")
      end
      
      #Disconnects the given output(s)' video signal(s) from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_video(output_ranges)
        connect_to(@@VIDEO_CHAR, 0, output_ranges, "vid")
      end
      
      #Connects the audio signal of an input to one or more outputs.
      #Takes the input number (1 based); and an ouput or an array of ouputs and ranges as parameters.
      def connect_audio(input, ranges)
        connect_to(@@AUDIO_CHAR, input, ranges, "aud")
      end
      
      #Disconnects the given output(s)' audio signal(s) from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_audio(output_ranges)
        connect_to(@@AUDIO_CHAR, 0, output_ranges, "aud")
      end
      
      #Connects the video and audio signals of an input to all outputs.
      #Takes the input number (1 based) as parameter.
      def connect_all_video_audio(input)
        connect_all(@@AV_CHAR, input, "all")
      end
      
      #Disconnects all the outputs' video and audio signals from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_all_video_audio
        connect_all(@@AV_CHAR, 0, "all")
      end
      
      #Connects the video signal of an input to all outputs.
      #Takes the input number (1 based) as parameter.
      def connect_all_video(input)
        connect_all(@@VIDEO_CHAR, input, "vid")
      end
      
      #Disconnects all the outputs' video signals from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_all_video
        connect_all(@@VIDEO_CHAR, 0, "vid")
      end
      
      #Connects the audio signal of an input to all outputs.
      #Takes the input number (1 based) as parameter.
      def connect_all_audio(input)
        connect_all(@@AUDIO_CHAR, input, "aud")
      end
      
      #Disconnects all the outputs' audio signals from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_all_audio
        connect_all(@@AUDIO_CHAR, 0, "aud")
      end
      
      #Gets the output's video signal source.
      #Takes the output number (1 based) as parameter.
      def get_output_video_connection(output)
        get_connection(output, @@VIDEO_CHAR)
      end
      
      #Gets the output's audio signal source.
      #Takes the output number as parameter.
      def get_output_audio_connection(output)
        get_connection(output, @@AUDIO_CHAR)
      end
      
      #Gets the vertical and horizontal frequency for the specified input.
      #Takes the input number (1 based) as a parameter. Returns an array with the horinzontal frequency in KHz at index 0 and the vertical
      #frequency in Hz at index 1
      def get_input_frequencies(input)
        cmd = input.to_s + "LS"
        send_cmd(cmd,@@switch_message_table["input_frequencies"])
      end
      
      #Sets the audio gain if a given input to the value specified.
      #Takes the input number (1 based) and gain (-18 to +24 dB) as parameters
      def set_input_audio_gain(input,gain)
        cmd = input.to_s + @@SEP_CHAR + gain.abs.to_s
        if gain >= 0
          cmd = cmd + "G"
        else
          cmd = cmd + "g"
        end
        response_captures = send_cmd(cmd,@@switch_message_table["gain_change"])
        if response_captures[0].to_i != input || response_captures[1].to_i != gain
          raise "Input gain change was not acknowledge by the switch.\n"+response_captures.to_s
        end 
      end
      
      #Gets the audio gain of the input specified.
      #Takes the input number  (1 based) as a parameter.
      def get_input_audio_gain(input)
        cmd = input.to_s + "G"
        send_cmd(cmd,@@switch_message_table["input_gain"])[0].to_i
      end
      
      #Sets the volume for the output specified.
      #Takes the input number  (1 based); and volume level (0 to 64, where 0 = 0% output and 64 = 100% output) as parameters. 
      #Every 1 increment = 1.5% volume increment, except when going from 0 to 1 which is equal to 5.5%
      def set_output_volume(output, volume)
        cmd = output.to_s + @@SEP_CHAR + volume.to_s + "V"
        response_captures = send_cmd(cmd,@@switch_message_table["vol_change"])
        if response_captures[0].to_i != output || response_captures[1].to_i != volume
          raise "Output volume change was not acknowledge by the switch.\n"+response_captures.to_s
        end 
      end
      
      #Returns the volume setting for the output specified.
      #Takes the output number  (1 based) as a parameter. Returns the volume setting in level (0-64) of max volume.
      def get_output_volume(output)
        cmd = output.to_s + "V"
        send_cmd(cmd,@@switch_message_table["output_volume"])[0].to_i
      end
      
      #Mutes/Unmutes the video signal of the output specified.
      #Takes the output number (1 based), and mute flag (true = mute, false = unmute) as parameter
      def mute_video_output(output, mute)
        cmd = output.to_s + @@SEP_CHAR
        if mute
          cmd = cmd + "1B"
        else
          cmd = cmd + "0B"
        end
        response_captures = send_cmd(cmd,@@switch_message_table["video_mute"])
        if response_captures[0].to_i != output || (response_captures[1].to_i != 0 && response_captures[1].to_i != 1)
          raise "Output video mute was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Mutes/Unmutes the audio signal of the output specified.
      #Takes the output number (1 based), and mute flag (true = mute, false = unmute) as parameters
      def mute_audio_output(output, mute)
        cmd = output.to_s + @@SEP_CHAR
        if mute
          cmd = cmd + "1Z"
        else
          cmd = cmd + "0Z"
        end
        response_captures = send_cmd(cmd,@@switch_message_table["audio_mute"])
        if response_captures[0].to_i != output || (response_captures[1].to_i != 0 && response_captures[1].to_i != 1)
          raise "Output audio mute was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Mutes/Unmutes the audio signals of all the outputs.
      #Takes the mute flag (true = mute, false = unmute) as a parameter
      def mute_all_audio_ouputs(mute)
        if mute
          cmd = "1*Z"
        else
          cmd = "0*Z"
        end
        response_captures = send_cmd(cmd,@@switch_message_table["mute_all"])
        if response_captures[0].to_i != 0 && response_captures[0].to_i != 1
          raise "Mute all audio outputs was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Mutes/Unmutes the video signals of all the outputs.
      #Takes the mute flag (true = mute, false = unmute) as a parameter
      def mute_all_video_ouputs(mute)
        if mute
          cmd = "1*B"
        else
          cmd = "0*B"
        end
        response_captures = send_cmd(cmd,@@switch_message_table["mute_all"])
        if response_captures[0].to_i != 0 && response_captures[0].to_i != 1
          raise "Mute all video outputs was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Checks if the given output audio signal is muted.
      #Returns true is output is muted, false otherwise
      def is_output_audio_muted(output)
        response_captures = send_cmd(output.to_s + "Z",@@switch_message_table["is_muted"])
        response_captures[0].to_i == 1
      end
      
      #Checks if the given output video signal is muted.
      #Returns true is output is muted, false otherwise
      def is_output_video_muted(output)
        response_captures = send_cmd(output.to_s + "B",@@switch_message_table["is_muted"])
        response_captures[0].to_i == 1
      end
      
      #Returns an output number addressable hash table containing the muted states of all the ouputs. The ouput states are:
      #not_muted, video_muted, audio_muted or video_audio_muted.
      def get_outputs_mute_state
        response_captures = send_cmd(@@ESC+"VM",@@switch_message_table["outputs_muted"])
        state_arr = response_captures[0].to_s.scan(/\d/)
        muted_outputs = Hash.new
        output = 0
        state_arr.each do |state|
          case state
            when '0'
              muted_outputs[output+1] = "not_muted"
            when '1'
              muted_outputs[output+1] = "video_muted"
            when '2'
              muted_outputs[output+1] = "audio_muted"
            when '3'
              muted_outputs[output+1] = "video_audio_muted"
          end 
          output +=1
        end
        muted_outputs
      end
      
      #Resets the audio gains of all the inputs in the switch to 0 dB
      def reset_all_audio_inputs_levels
        response_captures = send_cmd(@@ESC+"ZA",@@switch_message_table["reset_response"])
        if response_captures[0].downcase != "a"
          raise "Reset all audio input levels was not acknowledge by the switch.\n"+response_captures.to_s
        end    
      end
      
      #Resets the audio levels of all the outputs in the switch to 64 dB (100% output)
      def reset_all_audio_ouput_levels
        response_captures = send_cmd(@@ESC+"ZV",@@switch_message_table["reset_response"])
        if response_captures[0].downcase != "v"
          raise "Reset all audio output levels was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Resets all the video and audio mutes in the switch
      def reset_all_mutes
        response_captures = send_cmd(@@ESC+"ZZ",@@switch_message_table["reset_response"])
        if response_captures[0].downcase != "z"
          raise "Reset all mutes was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Clears all the connections, resets all the gains to 0dB and all audio levels to 64 dB (100%)
      def reset_switch
        response_captures = send_cmd(@@ESC+"ZXXX",@@switch_message_table["reset_response"])
        if response_captures[0].downcase != "x"
          raise "Reset switch was not acknowledge by the switch.\n"+response_captures.to_s
        end
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
        @telnet_socket.cmd("String" => cmd_to_send, "Match" => expected_expression)do |rcv_data|
          @switch_log.info("Switch:"+rcv_data)
          /E\d{2}/i =~ rcv_data
          raise @@error_response_table[Regexp.last_match(0)] if Regexp.last_match(0)
          resp_captures = expected_expression.match(rcv_data).captures        
        end
        resp_captures
        rescue Exception => e
          @switch_log.error("On command "+cmd_to_send+"\n"+e.to_s)
          raise
      end
  end  
end



