require 'net/telnet'
require 'serialport'
require 'rubygems'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module ConnectionEquipment
include Log4r
=begin
This class allows the user to control the extron video switch via a telnet session.
=end

  class RequiredVideoMethodException < Exception
    def initialize()
      super("Calling method from baseclass, all Video switch classes must override this function. At least with NOOP" )
    end
  end
  
  class BaseVideoSwitch
    Logger = Log4r::Logger
    ESC = "\x1B"
    ERROR_RESPONSE_TABLE = Hash.new()
    ERROR_RESPONSE_TABLE["E01"]="Invalid input channel number (out of range)"
    ERROR_RESPONSE_TABLE["E06"]="Invalid input selection during auto-input switching"
    ERROR_RESPONSE_TABLE["E10"]="Invalid command"
    ERROR_RESPONSE_TABLE["E11"]="Invalid preset number"
    ERROR_RESPONSE_TABLE["E12"]="Invalid output number"
    ERROR_RESPONSE_TABLE["E13"]="Invalid value (out of range)"
    ERROR_RESPONSE_TABLE["E14"]="Illegal command for this configuration"
    ERROR_RESPONSE_TABLE["E17"]="Timeout (caused by direct write of global preset)"
    ERROR_RESPONSE_TABLE["E21"]="Invalid room number"
    ERROR_RESPONSE_TABLE["E24"]="Privilege violation (Ethernet, Extron software only)"
    
    def initialize(log_path=nil)  
      start_logger(log_path) if log_path
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
    
    def log_info(info)
      @switch_log.info(info) if @switch_log
    end
    
    def log_error(error)
      @switch_log.error(error) if @switch_log
    end
    
    #Connects the video and audio signals of an input to one or more outputs.
    #Takes the input number (1 based); and an ouput or an array of outputs and ranges as parameters.   
    def connect_video_audio(input,ranges=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Disconnects the given output(s)' audio and video signals from their inputs
    #Takes an ouput or an array of ouputs and ranges as parameter.
    def disconnect_video_audio(output_ranges=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Connects the video signal of an input to one or more outputs.
    #Takes the input number (1 based); and an ouput or an array of ouputs and ranges as parameters.
    def connect_video(input, ranges=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Disconnects the given output(s)' video signal(s) from their inputs
    #Takes an ouput or an array of ouputs and ranges as parameter.
    def disconnect_video(output_ranges=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Connects the audio signal of an input to one or more outputs.
    #Takes the input number (1 based); and an ouput or an array of ouputs and ranges as parameters.
    def connect_audio(input, ranges=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Disconnects the given output(s)' audio signal(s) from their inputs
    #Takes an ouput or an array of ouputs and ranges as parameter.
    def disconnect_audio(output_ranges=nil)
      raise RequiredVideoMethodException.new()
    end
    

    
    #Gets the output's video signal source.
    #Takes the output number (1 based) as parameter.
    def get_output_video_connection(output=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Gets the output's audio signal source.
    #Takes the output number as parameter.
    def get_output_audio_connection(output=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Mutes/Unmutes the video signal of the output specified.
    #Takes the output number (1 based), and mute flag (true = mute, false = unmute) as parameter
    def mute_video_output(mute, output=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Mutes/Unmutes the audio signal of the output specified.
    #Takes the output number (1 based), and mute flag (true = mute, false = unmute) as parameters
    def mute_audio_output(mute, output=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Checks if the given output audio signal is muted.
    #Returns true is output is muted, false otherwise
    def is_output_audio_muted(output=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Checks if the given output video signal is muted.
    #Returns true is output is muted, false otherwise
    def is_output_video_muted(output=nil)
      raise RequiredVideoMethodException.new()
    end
    
    #Clears all the connections, resets all the gains to 0dB and all audio levels to 64 dB (100%)
    def reset_switch
      raise RequiredVideoMethodException.new()
    end

  end
  
  class BaseDigitalVideoSwitch < BaseVideoSwitch
    #Select and EDID for the inputs
    def set_edid(edid_num)
      raise RequiredVideoMethodException.new()
    end

    #Returns the edid_num of the currently selected EDID
    def get_edid_num()
      raise RequiredVideoMethodException.new()
    end
    
    #Returns the EDID data in Hex format
    def get_edid_data()
      raise RequiredVideoMethodException.new()
    end
  end
  
  class ExtronHDMISW8Switch < BaseDigitalVideoSwitch
  
    def initialize(switch_info,log_path = nil)
      super(log_path)
      @switch_info = switch_info
    end
    
    def disconnect()
      stop_logger
      sleep 1
    end
    
    #Select and EDID for the inputs
    def set_edid(edid_num)
      res = esc_cmd("A#{edid_num}EDID")
      raise "Unable to set EDID" if !res.match(/EdidA#{edid_num}/im)
    end
    
    def disable_hdcp()
      res = esc_cmd('E0HDCP')
      raise "Unable to disable HDCP" if !res.match(/HdcpE0/im)
    end

    #Returns the edid_num of the currently selected EDID
    def get_edid_num()
      esc_cmd('AEDID')
    end
    
    #Returns the EDID data in Hex format
    def get_edid_data()
      esc_cmd('REDID').match(/^[0-9A-F]+.*/im)[0]
    end
    
    #Connects an HDMI input to the HDMI output.
    #Takes the input number (1 based); ranges value not used in this equipment  
    def connect_video_audio(input,ranges=nil)
      res = send_cmd("#{Array(input).flatten.join(' ')}!", '', '')
      raise "Unable to connect hdmi input #{res}" if !res.match(/In#{input} All/im)
    end
    
    #Disconnects the output
    #Input parameter not used
    def disconnect_video_audio(output_ranges=nil)
      connect_video_audio(0)
    end
    
    #Connects an HDMI input to the HDMI output.
    #Takes the input number (1 based); ranges value not used
    def connect_video(input, ranges=nil)
      connect_video_audio(input)
    end
    
    #Disconnects the output
    #Input parameter not used
    def disconnect_video(output_ranges=nil)
      connect_video_audio(0)
    end
    
    #Connects an HDMI input to the HDMI output.
    #Takes the input number (1 based); ranges value not used
    def connect_audio(input, ranges=nil)
      connect_video_audio(input)
    end
    
    #Disconnects the output
    #Input parameter not used
    def disconnect_audio(output_ranges=nil)
      connect_video_audio(0)
    end

    def get_signal_status()
      res = esc_cmd('LS')
      signals = res.scan(/\d/).collect { |x| x.to_i }
      raise "Unable to get signal status #{signals}" if signals.length != 9
      signals
    end
    
    #Gets the output's HDMI source (HDMI input connected).
    #Input parameter not used
    def get_output_video_connection(output=nil)
      status = get_signal_status()
      input = status[0..-2].index(1)
      return -1 if status[-1] == 0 || !input
      input + 1
    end
    
    #Gets the output's HDMI source (HDMI input connected).
    #Input parameter not used
    def get_output_audio_connection(output=nil)
      get_output_video_connection()
    end
    
    #Mutes/Unmutes the video signal of the output
    #Inputs: output parameter not used
    #        mute flag (true = mute, false = unmute) as parameter
    def mute_video_output(mute, output=nil)
      status = mute ? 1 : 0
      raise 'Unable to (un)mute video' if !send_cmd("#{status}B", '', '').match(/Vmt#{status}/im)
    end
    
    #Mutes/Unmutes the audio signal of the output specified.
    #Takes the output number (1 based), and mute flag (true = mute, false = unmute) as parameters
    def mute_audio_output(mute, output=nil)
      status = mute ? 1 : 0
      raise 'Unable to (un)mute audio' if !send_cmd("#{status}Z", '', '').match(/Amt#{status}/im)
    end
    
    #Checks if the output's audio signal is muted.
    #output parameter not used
    #Returns true is output is muted, false otherwise
    def is_output_audio_muted(output=nil)
      send_cmd('Z', '', '').strip() == "1"
    end
    
    #Checks if the output's video signal is muted.
    #output parameter not used
    #Returns true is output is muted, false otherwise
    def is_output_video_muted(output=nil)
      send_cmd('B', '', '').strip() == "1"
    end
    
    #Clears all the connections, resets all the gains to 0dB and all audio levels to 64 dB (100%)
    def reset_switch
      raise 'Unable to reset switch' if !esc_cmd('ZXXX').match(/Zpx/im)
    end
    
    private
      
      def send_cmd(cmd_to_send, prefix='', suffix="\r", c_id=0)
        switch = SerialPort.new(@switch_info.serial_port, @switch_info.serial_params)
        log_info("Host: #{prefix+cmd_to_send} (#{caller[c_id].split("in")[1].strip()})")        
        switch.write(prefix+cmd_to_send+suffix)
        tries = 0
        rcv_data = ''
        while (rcv_data == '' || IO::select([switch],nil,nil,1)) && tries < 6
          begin
            sleep 1
            rcv_data += switch.read_nonblock(1000)
          rescue IO::WaitReadable
            tries += 1
            log_info("Read would block") if tries == 6
          end
        end
        log_info("Switch: "+rcv_data)
        raise ERROR_RESPONSE_TABLE[Regexp.last_match(0)] + " (#{cmd_to_send}) " if rcv_data.match(/E\d{2}/i) && check_error
        rcv_data
        ensure
          switch.close() if switch
      end
      
      def esc_cmd(cmd_to_send)
        send_cmd(cmd_to_send, ESC, "\r", 1)
      end
  end
  
  class ExtronVideoSwitch < BaseVideoSwitch
    private
      RGB_CHAR = "&"
      VIDEO_CHAR = "%"
      AUDIO_CHAR = "$"
      AV_CHAR = "!"
      SEP_CHAR = "*"
      SWITCH_MESSAGE_TABLE = Hash.new()
      SWITCH_MESSAGE_TABLE["conn_established"]=/^(C)Copyright\s*\d{4},\s*Extron\s*Electronics,\s*[-\w]+,\s*V\d+\.\d+/i
      SWITCH_MESSAGE_TABLE["password"] = /^Password:/i
      SWITCH_MESSAGE_TABLE["login"] = /^Login\s*(User|Administrator)/i
      SWITCH_MESSAGE_TABLE["quick_connect"] = /^Qik/i
      SWITCH_MESSAGE_TABLE["mem_preset"] = /^Spr(\d+)/i
      SWITCH_MESSAGE_TABLE["gain_change"] = /^In(\d+)\s*Aud((?:-|\+)\d+)/i
      SWITCH_MESSAGE_TABLE["vol_change"] = /^Out(\d+)\s*Vol(\d+)/i
      SWITCH_MESSAGE_TABLE["video_mute"] = /^Vmt(\d+)\s*\*(\d+)/i
      SWITCH_MESSAGE_TABLE["audio_mute"] = /^Amt(\d+)\s*\*(\d+)/i
      SWITCH_MESSAGE_TABLE["audio_muted"] = /^Amt(\d+)/i
      SWITCH_MESSAGE_TABLE["video_muted"] = /^Vmt(\d+)/i
      SWITCH_MESSAGE_TABLE["executive_mode"] = /^Exe(\d+)/i
      SWITCH_MESSAGE_TABLE["connect_to"] =/^Out(\d+)\s*In(\d+)\s*(\w+)/i
      SWITCH_MESSAGE_TABLE["connect_all"] = /^In(\d+)\s*(\w+)/i
      SWITCH_MESSAGE_TABLE["connected_to"] = /^(\d+)/i
      SWITCH_MESSAGE_TABLE["input_frequencies"] = /^([\d\.]+),([\d\.]+)/i
      SWITCH_MESSAGE_TABLE["input_gain"] = /^((?:-|\+)\d+)/i
      SWITCH_MESSAGE_TABLE["output_rgb_delay"] = /^(\d+)/i
      SWITCH_MESSAGE_TABLE["rgb_delay"] = /^Out(\d+)\s*Dly(\d+)/i
      SWITCH_MESSAGE_TABLE["outputs_muted"] = /(\d+)/i
      SWITCH_MESSAGE_TABLE["output_volume"] = /^(\d+)/i
      SWITCH_MESSAGE_TABLE["reset_response"] = /Zp(.)/i
      SWITCH_MESSAGE_TABLE["exe_mode"] = /Exe(\d)/i
      SWITCH_MESSAGE_TABLE["is_muted"] = /^(0|1)/i
      SWITCH_MESSAGE_TABLE["mute_all"] = /^(?:Amt|Vmt)\s*(0|1)/i  
      
      #Generic connection command. Connects an input's audio, video, or both (audio and video) signals to all outputs. Takes the connection type
      #audio ("$"), video("%") or both ("!"); input number, an array or value of outputs; and the expected response as arguments.
      def connect_to(cmd_suffix, input, output_ranges, response_check)
        if output_ranges.kind_of?(Array)
          cmd = ESC+"+Q"
          0.upto(output_ranges.length-1) do |arr_index|
            range_match = /(\d+)(?:-(\d+)){0,1}/.match(output_ranges[arr_index].to_s)
            start_channel = end_channel = range_match.captures[0].to_i
            end_channel = range_match.captures[1].to_i if range_match.captures[1]
            start_channel.upto(end_channel) do |out_index|
              cmd = cmd + input.to_s + SEP_CHAR + out_index.to_s + cmd_suffix
            end
          end
          send_cmd(cmd,SWITCH_MESSAGE_TABLE["quick_connect"])
        else
          cmd = input.to_s + SEP_CHAR + output_ranges.to_s + cmd_suffix
          response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["connect_to"])
          if response_captures[0].to_i != output_ranges || response_captures[1].to_i != input || response_captures[2].downcase != response_check
            raise "Connection was not acknowledge by the switch.\n"+response_captures.to_s
          end
        end  
      end
      
      #Generic connect all command. Connects an input's audio, video, or both (audio and video) signals to all outputs. Takes the connection type
      #audio ("$"), video("%") or both ("!"); input number; and the expected response as arguments.
      def connect_all(cmd_suffix, input, response_check)
        cmd = input.to_s + SEP_CHAR + cmd_suffix
        response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["connect_all"])
        if response_captures[0].to_i != input || response_captures[1].downcase != response_check
          raise "Connection was not acknowledge by the switch.\n"+response_captures.to_s
        end  
      end
      
      #Generic get connection information function. Gets the video or audio input that is connected to the given ouput.
      #Takes the output number and signal type as parameter.
      def get_connection(output, connection_type)
        cmd = output.to_s + connection_type
        response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["connected_to"])
        response_captures[0].to_i
      end
      
      public 
      #Constructor of the class loads the message and response tables; makes a connections if switch connection parameters are specified; and starts the logger 
      #if the log file path is specified.
      def initialize(switch_info,log_path = nil)
        super()
        connect(switch_info.telnet_ip,switch_info.telnet_port) if switch_info.telnet_ip && switch_info.telnet_port
      end

      #Establishes a telnet connection with the switch. Takes the switch's IP address and port number as parmaters.
      def connect(ip_address, port)
        @switch_log.info("Starting switch session") if @switch_log
        @telnet_socket = Net::Telnet.new('Host' => ip_address,
                                          'Port' => port,
                                          'Timeout' => 10,
                                          'WaitFor' => SWITCH_MESSAGE_TABLE["conn_established"])
        @switch_log.info("Login into the switch") if @switch_log
        @telnet_socket.waitfor(SWITCH_MESSAGE_TABLE["password"])do |recv_data|
          response_captures = send_cmd("gguser",SWITCH_MESSAGE_TABLE["login"])
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
      
      
         
      #Connects the video and audio signals of an input to one or more outputs.
      #Takes the input number (1 based); and an ouput or an array of outputs and ranges as parameters.   
      def connect_video_audio(input,ranges)
        connect_to(AV_CHAR, input, ranges, "all")
      end
      
      #Disconnects the given output(s)' audio and video signals from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_video_audio(output_ranges)
        connect_to(AV_CHAR, 0, output_ranges, "all")
      end
      
      #Connects the video signal of an input to one or more outputs.
      #Takes the input number (1 based); and an ouput or an array of ouputs and ranges as parameters.
      def connect_video(input, ranges)
        connect_to(VIDEO_CHAR, input, ranges, "vid")
      end
      
      #Disconnects the given output(s)' video signal(s) from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_video(output_ranges)
        connect_to(VIDEO_CHAR, 0, output_ranges, "vid")
      end
      
      #Connects the audio signal of an input to one or more outputs.
      #Takes the input number (1 based); and an ouput or an array of ouputs and ranges as parameters.
      def connect_audio(input, ranges)
        connect_to(AUDIO_CHAR, input, ranges, "aud")
      end
      
      #Disconnects the given output(s)' audio signal(s) from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_audio(output_ranges)
        connect_to(AUDIO_CHAR, 0, output_ranges, "aud")
      end
      
      #Connects the video and audio signals of an input to all outputs.
      #Takes the input number (1 based) as parameter.
      def connect_all_video_audio(input)
        connect_all(AV_CHAR, input, "all")
      end
      
      #Disconnects all the outputs' video and audio signals from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_all_video_audio
        connect_all(AV_CHAR, 0, "all")
      end
      
      #Connects the video signal of an input to all outputs.
      #Takes the input number (1 based) as parameter.
      def connect_all_video(input)
        connect_all(VIDEO_CHAR, input, "vid")
      end
      
      #Disconnects all the outputs' video signals from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_all_video
        connect_all(VIDEO_CHAR, 0, "vid")
      end
      
      #Connects the audio signal of an input to all outputs.
      #Takes the input number (1 based) as parameter.
      def connect_all_audio(input)
        connect_all(AUDIO_CHAR, input, "aud")
      end
      
      #Disconnects all the outputs' audio signals from their inputs
      #Takes an ouput or an array of ouputs and ranges as parameter.
      def disconnect_all_audio
        connect_all(AUDIO_CHAR, 0, "aud")
      end
      
      #Gets the output's video signal source.
      #Takes the output number (1 based) as parameter.
      def get_output_video_connection(output)
        get_connection(output, VIDEO_CHAR)
      end
      
      #Gets the output's audio signal source.
      #Takes the output number as parameter.
      def get_output_audio_connection(output)
        get_connection(output, AUDIO_CHAR)
      end
      
      #Gets the vertical and horizontal frequency for the specified input.
      #Takes the input number (1 based) as a parameter. Returns an array with the horinzontal frequency in KHz at index 0 and the vertical
      #frequency in Hz at index 1
      def get_input_frequencies(input)
        cmd = input.to_s + "LS"
        send_cmd(cmd,SWITCH_MESSAGE_TABLE["input_frequencies"])
      end
      
      #Sets the audio gain if a given input to the value specified.
      #Takes the input number (1 based) and gain (-18 to +24 dB) as parameters
      def set_input_audio_gain(input,gain)
        cmd = input.to_s + SEP_CHAR + gain.abs.to_s
        if gain >= 0
          cmd = cmd + "G"
        else
          cmd = cmd + "g"
        end
        response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["gain_change"])
        if response_captures[0].to_i != input || response_captures[1].to_i != gain
          raise "Input gain change was not acknowledge by the switch.\n"+response_captures.to_s
        end 
      end
      
      #Gets the audio gain of the input specified.
      #Takes the input number  (1 based) as a parameter.
      def get_input_audio_gain(input)
        cmd = input.to_s + "G"
        send_cmd(cmd,SWITCH_MESSAGE_TABLE["input_gain"])[0].to_i
      end
      
      #Sets the volume for the output specified.
      #Takes the input number  (1 based); and volume level (0 to 64, where 0 = 0% output and 64 = 100% output) as parameters. 
      #Every 1 increment = 1.5% volume increment, except when going from 0 to 1 which is equal to 5.5%
      def set_output_volume(output, volume)
        cmd = output.to_s + SEP_CHAR + volume.to_s + "V"
        response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["vol_change"])
        if response_captures[0].to_i != output || response_captures[1].to_i != volume
          raise "Output volume change was not acknowledge by the switch.\n"+response_captures.to_s
        end 
      end
      
      #Returns the volume setting for the output specified.
      #Takes the output number  (1 based) as a parameter. Returns the volume setting in level (0-64) of max volume.
      def get_output_volume(output)
        cmd = output.to_s + "V"
        send_cmd(cmd,SWITCH_MESSAGE_TABLE["output_volume"])[0].to_i
      end
      
      #Mutes/Unmutes the video signal of the output specified.
      #Takes the output number (1 based), and mute flag (true = mute, false = unmute) as parameter
      def mute_video_output(output, mute)
        cmd = output.to_s + SEP_CHAR
        if mute
          cmd = cmd + "1B"
        else
          cmd = cmd + "0B"
        end
        response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["video_mute"])
        if response_captures[0].to_i != output || (response_captures[1].to_i != 0 && response_captures[1].to_i != 1)
          raise "Output video mute was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Mutes/Unmutes the audio signal of the output specified.
      #Takes the output number (1 based), and mute flag (true = mute, false = unmute) as parameters
      def mute_audio_output(output, mute)
        cmd = output.to_s + SEP_CHAR
        if mute
          cmd = cmd + "1Z"
        else
          cmd = cmd + "0Z"
        end
        response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["audio_mute"])
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
        response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["mute_all"])
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
        response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["mute_all"])
        if response_captures[0].to_i != 0 && response_captures[0].to_i != 1
          raise "Mute all video outputs was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Checks if the given output audio signal is muted.
      #Returns true is output is muted, false otherwise
      def is_output_audio_muted(output)
        response_captures = send_cmd(output.to_s + "Z",SWITCH_MESSAGE_TABLE["is_muted"])
        response_captures[0].to_i == 1
      end
      
      #Checks if the given output video signal is muted.
      #Returns true is output is muted, false otherwise
      def is_output_video_muted(output)
        response_captures = send_cmd(output.to_s + "B",SWITCH_MESSAGE_TABLE["is_muted"])
        response_captures[0].to_i == 1
      end
      
      #Returns an output number addressable hash table containing the muted states of all the ouputs. The ouput states are:
      #not_muted, video_muted, audio_muted or video_audio_muted.
      def get_outputs_mute_state
        response_captures = send_cmd(ESC+"VM",SWITCH_MESSAGE_TABLE["outputs_muted"])
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
        response_captures = send_cmd(ESC+"ZA",SWITCH_MESSAGE_TABLE["reset_response"])
        if response_captures[0].downcase != "a"
          raise "Reset all audio input levels was not acknowledge by the switch.\n"+response_captures.to_s
        end    
      end
      
      #Resets the audio levels of all the outputs in the switch to 64 dB (100% output)
      def reset_all_audio_ouput_levels
        response_captures = send_cmd(ESC+"ZV",SWITCH_MESSAGE_TABLE["reset_response"])
        if response_captures[0].downcase != "v"
          raise "Reset all audio output levels was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Resets all the video and audio mutes in the switch
      def reset_all_mutes
        response_captures = send_cmd(ESC+"ZZ",SWITCH_MESSAGE_TABLE["reset_response"])
        if response_captures[0].downcase != "z"
          raise "Reset all mutes was not acknowledge by the switch.\n"+response_captures.to_s
        end
      end
      
      #Clears all the connections, resets all the gains to 0dB and all audio levels to 64 dB (100%)
      def reset_switch
        response_captures = send_cmd(ESC+"ZXXX",SWITCH_MESSAGE_TABLE["reset_response"])
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
        response_captures = send_cmd(cmd,SWITCH_MESSAGE_TABLE["exe_mode"])
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
          raise ERROR_RESPONSE_TABLE[Regexp.last_match(0)] if Regexp.last_match(0)
          resp_captures = expected_expression.match(rcv_data).captures        
        end
        resp_captures
        rescue Exception => e
          @switch_log.error("On command "+cmd_to_send+"\n"+e.to_s)
          raise
      end
  end  
end



