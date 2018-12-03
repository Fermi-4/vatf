require File.dirname(__FILE__)+'/../target/equipment_driver'
require 'socket'
require "net/http"
require "uri"

module TestEquipment

  class TekOscopeDriver < Equipment::EquipmentDriver

    attr_reader :number_of_channels, :oscope_model
    def initialize(platform_info, log_path)
      super(platform_info, log_path)
    end

    # This function enables communication with oscilloscope via SCPI commands over http
    def send_cmd(command)
      uri = URI.parse("http://#{@telnet_ip}/Comm.html")
      http = Net::HTTP.new(uri.host, uri.port)
      puts "*** COMMAND="+command+" ***"
      response = http.post(uri.request_uri, 'COMMAND='+command)
      cmd_resp = response.body.match(/TEXTAREA.*?name">(.*?)<\/TEXTAREA/i)
      log_info = $1
      puts log_info+"\n\n"
      return log_info
    end

    # This function compares the oscilloscope version with that defined in bench file.
    def check_oscope_model()
      @oscope_model = @params['oscope_model']
      model_response = ""
      tek_model = ""
      # Check equipment ID
      model_response = send_cmd("*IDN?")
      tek_model = model_response.match(/TDS\s+(\d+)/i).captures[0]
      if tek_model.to_s == @oscope_model.to_s
        puts "Oscilloscope model #{tek_model} matches expectation"
        return 1
      else
        puts "ERROR: Oscilloscope model #{tek_model} not supported! Expecting #{@oscope_model} oscilloscope version."
        return 0
      end
    end

    # This function resets the oscilloscope's controls and settings to their factory setup defaults.
    # It also clears the event queue as well as checks and clears the error status.
    # It is useful to clear past errros.
    def reset_oscope()
      send_cmd("*RST")
      send_cmd("*CLS")
      send_cmd("*ESR?")
      send_cmd("ALLEV?")
      return 1
    end

    # This function measures the jitter between two input channels.
    # Assumption here is that channel-a is the master (or reference) while channel-b is the slave.
    # Input Parameters => input channels and number of times the measurement is to be made.
    # Return value(s) => measured jitter value(s).
    def measure_jitter(cha=1, chb=2, loop_count=5)
      sleep 5
      counter = 0
      jitter_reading = Array.new

      # Make sure oscope is configured and DUT is in the right state
      sleep 5

      max_channels = @params['number_of_channels']
      if ((cha > max_channels) or (chb > max_channels))
        puts "ERROR: Specified channels are not supported. This oscilloscope supports up to #{max_channels}."
        return 0
      end

      # Jitter Measurement Setup
      # Configure the horizontal, vertical, triggering controls, etc. as desired
      # Choosing 20ns as horizontal unit, and 2V as vertical unit. These values were chosen
      # since typical accuracies are in the order of 5ns to 200ns and typical Sitara output voltage is ~2V.
      # Display channel a and channel b
      send_cmd("SELECT:CH#{cha} ON")
      send_cmd("SELECT:CH#{chb} ON")
      send_cmd("HORIZONTAL:MAIN:SCALE 20E-9")
      send_cmd("CH#{cha}:SCALE 2")
      send_cmd("CH#{chb}:SCALE 2")
      send_cmd("ACQUIRE:STATE RUN")
      # Sets the trigger level to 2.0V
      send_cmd("TRIGGER:A:LEVEL 2.0")
      send_cmd("TRIGGER:B:LEVEL 2.0")
      send_cmd("TRIGger:A:EDGe:SLOpe RISe")
      # return B trigger type i.e. edge
      send_cmd("TRIGGER:B:TYPE?")
      # indicate the time (in s) where B trigger is armed <x> ns after the A trigger occurs.
      send_cmd("TRIGger:B:TIMe?")
      # Set persistence to infinite
      send_cmd("DISplay:PERSistence:CLEAR")
      send_cmd("DISPLAY:PERSISTENCE Auto")
      send_cmd("DISPLAY:PERSISTENCE INFInite")
      # sets measurement 2 as a delay
      send_cmd(":MEASU:MEAS4:TYP DELAY;")
      # set the first source (start edge's source)
      send_cmd("SOURCE1 CH#{cha};")
      # set the second source (end edge's source)
      send_cmd("SOURCE2 CH#{chb};")
      # Use the first edge
      send_cmd("DEL:DIRE FORW;")
      # start with rising edge of source1
      send_cmd("EDGE1 RIS;")
      # end with falling edge of source2
      send_cmd("EDGE2 FALL;")
      # turn the measurement on
      send_cmd(":MEASU:MEAS4:STATE ON;")

      # Jitter Measurement
      while counter < loop_count
        # Wait until acquisition is complete before taking measurement
        send_cmd("While BUSY? keep looping")
        jitter_reading[counter] = send_cmd("MEASUREMENT:MEAS4:VALUE?").to_f
        counter += 1
      end
      puts "Jitter measurement(s) between reference channel #{cha} and slave channel #{chb} [in s]:"
       jitter_reading.each{|elem| puts "#{elem}"}
     return jitter_reading
    end

    # This function measures the time period of the signal connected to specified channel.
    # Input Parameters => input channel and number of times the measurement is to be made.
    # Return value(s) => measured time period value(s).
    def measure_time_period(ch=1, loop_count=5)
      period_reading = Array.new
      counter = 0
      # Make sure oscope is configured and DUT is in the right state
      sleep 5

      max_channels = @params['number_of_channels']
      if (ch > max_channels)
        puts "ERROR: Specified channel number is not supported. This oscilloscope supports up to #{max_channels}."
        return 0
      end

      # Setup time period measurement.
      # A horizontal unit of 1s was chosen since typical signal measurement
      # is for 1Hz or 1PPS (pulse per second) or signal time period = 1s.
      # A vertical unit of 2V was chosen since typical Sitara output voltage is ~2V.
      send_cmd("SELECT:CH#{ch} ON")
      send_cmd("HORIZONTAL:MAIN:SCALE 1")
      send_cmd("CH#{ch}:SCALE 2")
      # Acquire waveform
      send_cmd("ACQUIRE:STOPAFTER RUNSTop")
      send_cmd("ACQUIRE:STATE RUN")
      send_cmd("SELect:CH#{ch}")
      send_cmd("MEASUREMENT:MEAS1:SOURCE CH#{ch}")
      send_cmd("MEASUREMENT:MEAS1:TYPE PERIod")
      # Turn on the waveform display on oscilloscope
      send_cmd("MEASUREMENT:MEAS1:STATE ON")

      # Measure loop_count times, with a specified error margin.
       while counter < loop_count
        # Wait until acquisition is complete before taking measurement
        send_cmd("While BUSY? keep looping")
        period_reading[counter] = send_cmd("MEASUREMENT:MEAS1:VALUE?").to_f
        counter += 1
       end
       puts "Time period measurement(s) on channel #{ch} [in s]:"
       period_reading.each{|elem| puts "#{elem}"}
     return period_reading
    end
  end
end
