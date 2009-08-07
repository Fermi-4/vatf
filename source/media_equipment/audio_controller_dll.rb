require 'rubyclr'

reference_file 'C:\Program Files\Automation Studio\AudioCard.dll'

module MediaEquipment  
  include TeHandlers 
  include System::Collections
  include System 
  class AudioCard

    def initialize(equipment_info, log_path = nil)
		e_info = Hashtable.new
		e_info.Add("analog_inputs", equipment_info.audio_hardware_info.analog_audio_inputs) if equipment_info.audio_hardware_info.analog_audio_inputs
		e_info.Add("digital_inputs",equipment_info.audio_hardware_info.digital_audio_inputs) if equipment_info.audio_hardware_info.digital_audio_inputs
		e_info.Add("midi_inputs", equipment_info.audio_hardware_info.midi_audio_inputs) if equipment_info.audio_hardware_info.midi_audio_inputs
		e_info.Add("analog_outputs", equipment_info.audio_hardware_info.analog_audio_outputs) if equipment_info.audio_hardware_info.analog_audio_outputs
        e_info.Add("digital_outputs", equipment_info.audio_hardware_info.digital_audio_outputs) if equipment_info.audio_hardware_info.digital_audio_outputs
		e_info.Add("midi_outputs", equipment_info.audio_hardware_info.midi_audio_outputs) if equipment_info.audio_hardware_info.midi_audio_outputs
        @my_audio_card = TeHandlers::AudioCard.new(e_info,log_path)
    end
    
    def start_logger(log_path)
        @my_audio_card.StartLogger(log_path)
    end
	
    #This function allows the user to open a wave audio input for recording with a specific configuration.
    #
    #Takes "record_settings" :a hashtable containing the wave audio input configuration. The hashtable required values are:
    #"device_type": type of input used for recording, allowed values are "analog", "digital" or "midi".
    #"device_id": represents the number associated with the type that will be used for recording if device_type is present, or the id associated with the input used for recording in which case has to be a value between 0 and whatever is returned by GetWaveInDevices - 1
    #"ext_param_size": size of the audio inputs extended parameters, currently only 0 is supported
    #"avg_bytes_per_sec": average audio recording rate in bytes per seconds
    #"channels": number of channels in the recorded signal 1 for mono, 2 for stereo);
    #"samples_per_sec": sampling rate
    #"bits_per_sample": number of bits per audio sample;
    #"format_tag": recorded audio format, currently only 1 (for linear format) is supported 
	#
    # returns: a handle (int) to the opened device, -1 otherwise.
	def open_wave_in_audio_device(record_settings)
	   settings = get_dotnet_hash(record_settings)
	   settings.Add("ext_param_size",0) if !record_settings["ext_param_size"]
	   settings.Add("format_tag",1) if !record_settings["format_tag"]
	   @my_audio_card.OpenWaveInAudioDevice(settings)
	end
	
	#This function allows the user to open a wave audio output for playout with a specific configuration.
    #
    #Takes "play_settings": a hashtable containing the wave audio input configuration. The hashtable required values are:
    #"device_type": type of input used for recording, allowed values are "analog", "digital" or "midi".
    #"device_id": represents the number associated with the type that will be used for recording if device_type is present, or the id associated with the input used for recording in which case has to be a value between 0 and whatever is returned by GetWaveInDevices - 1
    #"ext_param_size": size of the audio inputs extended parameters, currently only 0 is supported
    #"avg_bytes_per_sec": average audio recording rate in bytes per seconds
    #"channels": number of channels in the recorded signal 1 for mono, 2 for stereo);
    #"samples_per_sec": sampling rate
    #"bits_per_sample": number of bits per audio sample;
    #"format_tag": recorded audio format, currently only 1 (for linear format) is supported 
	#
    # returns: a handle (int) to the opened device, -1 otherwise.
	def open_wave_out_audio_device(play_settings)
	   settings = get_dotnet_hash(play_settings)
	   settings.Add("ext_param_size",0) if !play_settings["ext_param_size"]
	   settings.Add("format_tag",1) if !play_settings["format_tag"]
	   @my_audio_card.OpenWaveOutAudioDevice(settings)
	end
	
	# This functions is used to record audio
    # 
	# Takes:
    # "device_handle": handle to the input that will be used for recording
    # "audio_file": path of a file were the recorded audio will be stored    
	def record_wave_audio(device_handle, audio_file)
	   @my_audio_card.RecordWaveAudio(device_handle, audio_file)
	end
    
	#  This functions is used to play audio
    #
	# Takes:
	# "device_handle": handle to the output used for playout
    # "audio_file": path of a file containing the audio to be played out
    def play_wave_audio(device_handle, audio_file)
	   @my_audio_card.PlayWaveAudio(device_handle,audio_file)
	end
	
	#  This function is used to stop recording audio.
    #
	# Takes:
	# "device_handle": handle to the input used for recording
	#
	# returns:  the number of bytes recorded
	def stop_wave_audio_record(device_handle)
        @my_audio_card.StopWaveAudioRecord(device_handle)
	end
	
	#  This function is used to stop audio playout
    #  
    #  Takes:
	# "device_handle": handle of the output used to playout audio<
	def stop_wave_audio_play(device_handle)
        @my_audio_card.StopWaveAudioPlay(device_handle)
	end
	
	#  This function allows the user to query if a device is still playing a file.
    #  
    #  Takes:
	# "device_handle": handle of the output used to playout audio
    #
	# returns:  true if the device has finished playing the file; false if the device is still playing the file
	def wave_audio_play_done(device_handle)
        @my_audio_card.WaveAudioPlayDone(device_handle)
	end
	
	#  This function allows the user to query if a record operation is still running.
    #  
    #  Takes:
	# "device_handle": handle to the input used for recording
    #
	# returns:  true if the record operation has finished; false if the record operation is still running
	def wave_audio_record_done(device_handle)
        @my_audio_card.WaveAudioRecordDone(device_handle)
	end
	
	#  This function is used to release control of an audio input.
    #  
    #  Takes:
	# "device_handle": handle of the input acquire with OpenWaveInAudioDevice
	def close_wave_in_device(device_handle)
        @my_audio_card.CloseWaveInDevice(device_handle)
	end
	
	#  This function is used to release control of an audio output.
    #  
    #  Takes:
	# "device_handle": handle of the output acquire with OpenWaveOutAudioDevice
	def close_wave_out_device(device_handle)
        @my_audio_card.CloseWaveOutDevice(device_handle)
	end
	
	#  This function returns the capabilities of the audio input specified
    #  
    #  Takes:
	#  "device_id": id associated with the input, has to be a value between 0 and whatever is returned by GetWaveOutDevices - 1</param>
    #
	# returns: A Hashtable containing the output's capabilities. The hashtable keys are:
    #  "manufacturer_id", "product_id", "driver_version", "formats", and "name". MMSystem.h is required to understand the values.
	def get_wave_in_device_capabilities(device_id)
        marshal_dotnet_hash(@my_audio_card.GetWaveInDeviceCapabilities(device_id))
	end

    # This function returns the capabilities of the audio output specified
    #  
    # Takes:
	# "device_id": id associated with the output , has to be a value between 0 and whatever is returned by GetWaveOutDevices - 1</param>
    #
	# returns: A Hashtable containing the output's capabilities. The hashtable keys are:
    #  "manufacturer_id", "product_id", "driver_version", "formats", and "name". MMSystem.h is required to understand the values.
	def get_wave_out_device_capabilities(device_id)
        marshal_dotnet_hash(@my_audio_card.GetWaveOutDeviceCapabilities(device_id))
	end

    #  This function returns the number of audio inputs available in the system
    #
	# returns: the number of audio inputs available in the system
	def get_wave_in_devices()
        @my_audio_card.GetWaveInDevices()
	end
	
    #  This function returns the number of audio outputs available in the system
    #
	# returns: the number of audio outputs available in the system
	def get_wave_out_devices()
        @my_audio_card.GetWaveOutDevices()
	end
	
    #Stops the logger.
    def stop_logger
        @my_audio_card.StopLogger
    end
    
    private
    
    def get_dotnet_hash(ruby_hash = nil)
        result = Hashtable.new
        ruby_hash.each{|key,val| result.Add(key,val)} if ruby_hash
        result
    end
	
	def marshal_dotnet_hash(dotnet_hash)
		result = Hash.new
		0.upto(dotnet_hash.Count-1) do |index|
			result[dotnet_hash.Keys.to_a[index]] = dotnet_hash.Values.to_a[index]
		end
		result
	end
    
  end
end

