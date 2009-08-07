# -*- coding: ISO-8859-1 -*-
require 'rubyclr'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module TestEquipment
    reference_file 'NDde.dll'
    include NDde::Client
    include Log4r
    class SpectraLab
        Logger = Log4r::Logger        		
        @@spectra_wait_time = 60000
        def initialize(equip_info, log_path)
            start_logger(log_path) if log_path
            log_info("Starting SpectraLab Session")
            @spectra_client = DdeClient.new('Softest','Data')
            @spectra_stats = Hash.new
            rescue Exception => e
                log_error(e.to_s)
                raise e
        end
        
        def connect
            @spectra_client.connect()
            spectra_exe("Mode Post Processing")
            spectra_exe("Open Time Series")
            spectra_exe("Open Spectrum")
            spectra_exe("Open Phase")
            spectra_exe("Open Surface")
            spectra_exe("Open Spectrogram") 
        end
        
        def process_file(file_buffer)
			test_file = File.new('test_file.wav','wb')
			test_file.write(file_buffer)
			test_file.close
            spectra_exe("File Open C:\\SpectraLabServer\\test_file.wav")
            spectra_exe("Run")
            sleep((get_spectra_stat("Total Time").to_f + 0.49999999).round)
            spectra_exe("Stop")
            get_stats
            spectra_exe("File Close")
        end
        
        def disconnect
            if @spectra_client
                spectra_exe("Close Time Series")
    	        spectra_exe("Close Spectrum")
                spectra_exe("Close Phase")
                spectra_exe("Close Surface")
                spectra_exe("Close Spectrogram")
                @spectra_client.disconnect() if @spectra_client
            end
        end
        
        def get_test_stat(stat)
            @spectra_stats[stat.strip.downcase]
        end
        
        def get_test_stats
            @spectra_stats
        end
        
         #Starts the logger for the session. Takes the log file path as parameter (string).
        def start_logger(file_path)
          if @spectra_log
            stop_logger
          end
          Logger.new('spectra_log')
          @spectra_log_outputter = Log4r::FileOutputter.new("spectra_log_out",{:filename => file_path.to_s , :truncate => false})
          @spectra_log = Logger['spectra_log']
          @spectra_log.level = Log4r::DEBUG
          @spectra_log.add  @spectra_log_outputter
          @pattern_formatter = Log4r::PatternFormatter.new(:pattern => "- %d [%l] %c: %M",:date_pattern => "%H:%M:%S")
          @spectra_log_outputter.formatter = @pattern_formatter     
        end
      
        #Stops the logger.
        def stop_logger
            @spectra_log_outputter = nil if @spectra_log_outputter
            @spectra_log = nil if @spectra_log
        end
        
        private
        
        def spectra_exe(cmd)
            log_info("Command: "+cmd.to_s)
            @spectra_client.execute("[" + cmd + "]", @@spectra_wait_time)
            rescue Exception => e
                log_error(e.to_s)
                raise e
        end
        
        def get_spectra_stat(stat)
            log_info("Stat request: "+stat.to_s)
            @spectra_client.request(stat,@@spectra_wait_time)
            rescue Exception => e
                log_error(e.to_s)
                raise e
        end
        
        def get_stats
           @spectra_stats["snr"] = get_spectra_stat("SNR")
           @spectra_stats["peak_freq"] = get_spectra_stat("Peak Frequency")        #Returns the frequency of the peak bin (same as Peak1 Frequency)
           @spectra_stats["peak1_freq"] = get_spectra_stat("Peak1 Frequency")      #Returns the 1st highest peak frequency.
           @spectra_stats["peak2_freq"] = get_spectra_stat("Peak2 Frequency")      #Returns the 2nd highest peak frequency.
           @spectra_stats["peak3_freq"] = get_spectra_stat("Peak3 Frequency")      #Returns the 3rd highest peak frequency.
           @spectra_stats["peak4_freq"] = get_spectra_stat("Peak4 Frequency")      #Returns the 4th highest peak frequency.
           @spectra_stats["peak5_freq"] = get_spectra_stat("Peak5 Frequency")      #Returns the 5th highest peak frequency.
           @spectra_stats["peak6_freq"] = get_spectra_stat("Peak6 Frequency")      #Returns the 6th highest peak frequency.
           @spectra_stats["peak_amp"] = get_spectra_stat("Peak Amplitude")     #Returns the amplitude of the peak bin (same as Peak1 Amplitude)
           @spectra_stats["peak1_amp"] = get_spectra_stat("Peak1 Amplitude")       #Returns the 1st highest peak amplitude.
           @spectra_stats["peak2_amp"] = get_spectra_stat("Peak2 Amplitude")       #Returns the 2nd highest peak amplitude.
           @spectra_stats["peak3_amp"] = get_spectra_stat("Peak3 Amplitude")       #Returns the 3rd highest peak amplitude.
           @spectra_stats["peak4_amp"] = get_spectra_stat("Peak4 Amplitude")       #Returns the 4th highest peak amplitude.
           @spectra_stats["peak5_amp"] = get_spectra_stat("Peak5 Amplitude")       #Returns the 5th highest peak amplitude.
           @spectra_stats["peak6_amp"] = get_spectra_stat("Peak6 Amplitude")       #Returns the 6th highest peak amplitude.
           @spectra_stats["total_pwr"] = get_spectra_stat("Total Power")       #Returns the total power with default weighting
           @spectra_stats["total_pwr_a"] = get_spectra_stat("Total Power A")       #Returns the total power with A weighting
           @spectra_stats["total_pwr_b"] = get_spectra_stat("Total Power B")       #Returns the total power with B weighting
           @spectra_stats["total_pwr_c"] = get_spectra_stat("Total Power C")       #Returns the total power with C weighting
           @spectra_stats["total_pwr_flat"] = get_spectra_stat("Total Power Flat")        #Returns the total power with flat weighting
           @spectra_stats["thd"] = get_spectra_stat("THD")         #Returns the THD value
           @spectra_stats["thd+n"] = get_spectra_stat("THD+N")         #Returns the THD+N value
           @spectra_stats["imd"] = get_spectra_stat("IMD")         #Returns the IMD value
           @spectra_stats["snr"] = get_spectra_stat("SNR")         #Returns the SNR value
           @spectra_stats["sinad"] = get_spectra_stat("SINAD")           #Returns the SINAD value
           @spectra_stats["nf"] = get_spectra_stat("NF")           #Returns the Noise Figure (NF) value
           @spectra_stats["spectrum"] = get_spectra_stat("Spectrum")           #Returns entire spectrum as array**
           @spectra_stats["zoomed_spectrum"] = get_spectra_stat("Zoomed Spectrum") #Returns spectrum range corresponding to the current zoom in/out settings on the view**
           @spectra_stats["marked_spectrum"] = get_spectra_stat("Marked Spectrum")     #Returns spectrum range between Marker1 and Marker2 as array**
           @spectra_stats["phase"] = get_spectra_stat("Phase")         #Returns entire phase as array**
           @spectra_stats["zoomed_phase"] = get_spectra_stat("Zoomed Phase")       #Returns phase range corresponding to the current zoom in/out settings on the view**
           @spectra_stats["marked_phase"] = get_spectra_stat("Marked Phase")       #Returns phase range between Marker1 and Marker2 as array**
           @spectra_stats["time_series"] = get_spectra_stat("Time Series")     #Returns entire time series values as array**
           @spectra_stats["zoomed_time_series"] = get_spectra_stat("Zoomed Time Series")   #Returns time series values corresponding to the current zoom in/out settings on the view**
           @spectra_stats["marker1_amp"] = get_spectra_stat("Marker1 Amplitude")   #Returns Marker 1 amplitude value
           @spectra_stats["marker2_amp"] = get_spectra_stat("Marker2 Amplitude")   #Returns Marker 2 amplitude value
           @spectra_stats["marker3_amp"] = get_spectra_stat("Marker3 Amplitude")   #Returns Marker 3 amplitude value
           @spectra_stats["marker4_amp"] = get_spectra_stat("Marker4 Amplitude")   #Returns Marker 4 amplitude value
           @spectra_stats["marker5_amp"] = get_spectra_stat("Marker5 Amplitude")   #Returns Marker 5 amplitude value
           @spectra_stats["marker6_amp"] = get_spectra_stat("Marker6 Amplitude")   #Returns Marker 6 amplitude value
           @spectra_stats["overload_status"] = get_spectra_stat("Overload Status")     #Returns current overload status (1=true, 0=false)
           @spectra_stats["overload_count"] = get_spectra_stat("Overload Count")       #Returns count of overload events since last Run command.
           @spectra_stats["fft_count"] = get_spectra_stat("FFT Count")     #Returns count of FFT's performed since last Run command.
           @spectra_stats["current_time"] = get_spectra_stat("Current Time")       #Returns the current  WAV file position in seconds.
           @spectra_stats["total_time"] = get_spectra_stat("Total Time")       #Returns the total WAV file time in seconds.
           @spectra_stats["logging_status"] = get_spectra_stat("Logging Status")       #Returns 1 if Data Logging is enabled, 0 otherwise
           @spectra_stats["peak_hold"] = get_spectra_stat("Peak Hold")     #Returns 1 if Peak Hold is enabled, 0 otherwise
           @spectra_stats["fft_overlap"] = get_spectra_stat("FFT Overlap")     #Returns the overlap percentage (0...99)
           @spectra_stats["fft_size"] = get_spectra_stat("FFT SIze")           #Returns the FFT size
           @spectra_stats["avg_block_size"] = get_spectra_stat("Average Size")     #Returns the averaging block size (1...1000; 1001 if infinite).
           @spectra_stats["smoothing_window"] = get_spectra_stat("Smoothing Window")   #Returns the name of the smoothing window being used
           @spectra_stats["macro_status"] = get_spectra_stat("Macro Status")           #Returns the run status of the macro command processor where 0 is stopped and 1 is
        end
	
        def log_info(info)
	   @spectra_log.info(info) if @spectra_log
	end
	  
        def log_error(error)
           @spectra_log.error(error) if @spectra_log
        end
        
        def log_warning(warning)
           @spectra_log.warning(error) if @spectra_log
        end
    end
end

