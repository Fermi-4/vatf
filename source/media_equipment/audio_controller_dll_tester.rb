require 'audio_controller_dll'

include MediaEquipment

class AudioHardwareInfo
  attr_accessor :analog_audio_inputs,:analog_audio_outputs,:digital_audio_inputs,:digital_audio_outputs, \
				:midi_audio_inputs, :midi_audio_outputs
end

class AudioInfo
  attr_reader :audio_hardware_info
  def initialize
    @audio_hardware_info = AudioHardwareInfo.new
    @audio_hardware_info.analog_audio_inputs = "0"
    @audio_hardware_info.analog_audio_outputs = "0"
    @audio_hardware_info.digital_audio_inputs = "1"
    @audio_hardware_info.digital_audio_outputs = "1"
  end 
end

1.upto(500) do |iter|
	puts "\n\nRunning iteration: "+iter.to_s
    testWaveIn = true
    testWaveOut = true
    test44K1Hz = false
	test8KHz = false
	test48KHz = false
	test96KHz = false
	puts "AudioCard objects = "+ObjectSpace.each_object(AudioCard){}.to_s
    aCard = AudioCard.new(AudioInfo.new,'C:\audio_log.txt')
    
	audioParams = Hash.new
	if rand(5) >= 2
		test44K1Hz = true
	else 
		test8KHz = true
	end
                    
	if test44K1Hz
		maxIOtime = 65000
		audioParams["device_id"] = 0
		audioParams["device_type"] = "analog"
		audioParams["ext_param_size"] = 0
		audioParams["avg_bytes_per_sec"] = 176400
		audioParams["channels"] = 2
		audioParams["samples_per_sec"] = 44100
		audioParams["bits_per_sample"] = 16
		audioParams["format_tag"] = 1
	end

	if test48KHz
		maxIOtime = 65000
		audioParams["device_id"] = 0
		audioParams["device_type"] = "analog"
		audioParams["ext_param_size"] = 0
		audioParams["avg_bytes_per_sec"] = 192000
		audioParams["channels"] = 2
		audioParams["samples_per_sec"] = 48000
		audioParams["bits_per_sample"] = 16
		audioParams["format_tag"] = 1
	end
	
	if test8KHz
		maxIOtime = 11000
		audioParams["device_type"] = "analog"
		audioParams["device_id"] = 0
		audioParams["ext_param_size"] = 0
		audioParams["avg_bytes_per_sec"] = 16000
		audioParams["channels"] = 1
		audioParams["samples_per_sec"] = 8000
		audioParams["bits_per_sample"] = 16
		audioParams["format_tag"] = 1
	end

	if test96KHz
		audioParams["device_type"] = "digital"
		audioParams["device_id"] = 0
		audioParams["ext_param_size"] = 0
		audioParams["avg_bytes_per_sec"] = 384000
		audioParams["channels"] = 2
		audioParams["samples_per_sec"] = 96000
		audioParams["bits_per_sample"] = 16
		audioParams["format_tag"] = 1
	end
	
	devInHandle = nil
	devOutHandle = nil

	if testWaveIn
		puts "Testing Wave In....."
		puts "Number of Wave Inputs: " + aCard.get_wave_in_devices.to_s
		devCaps = aCard.get_wave_in_device_capabilities(0)
		puts "name = "+devCaps["name"].to_s;
		puts "formats = "+devCaps["formats"].to_s
		puts "manufacturer" + devCaps["manufacturer_id"].to_s
		devInHandle = aCard.open_wave_in_audio_device(audioParams);
		aCard.record_wave_audio(devInHandle, "C:\\test_file.pcm");
		puts "Recording audio done? A: " + aCard.wave_audio_record_done(devInHandle).to_s
	end
	
	if testWaveOut
		puts "Testing Wave Out....."
		puts "Number of Wave Outputs: " + aCard.get_wave_out_devices.to_s
		devCaps = aCard.get_wave_out_device_capabilities(0)
		puts "name = "+devCaps["name"].to_s
		puts "formats = "+devCaps["formats"].to_s
		puts "support = "+devCaps["support"].to_s
		puts "manufacturer" + devCaps["manufacturer_id"].to_s
		devOutHandle = aCard.open_wave_out_audio_device(audioParams);		 
		aCard.play_wave_audio(devOutHandle, "C:\\test1_16bIntel.pcm") if test8KHz
		aCard.play_wave_audio(devOutHandle, "C:\\harp40_96kHz_s.pcm")  if test96KHz # valid for digital IO only
		aCard.play_wave_audio(devOutHandle, "C:\\HipHop_Shadowboxing_44KHz_Stereo.pcm") if test44K1Hz
		aCard.play_wave_audio(devOutHandle, "C:\\Stress_48KHz_Stereo.pcm") if test48KHz
		puts "Playing audio done? A: " + aCard.wave_audio_play_done(devOutHandle).to_s
	end
	
	a = [1000,rand(maxIOtime)].max
	puts "sleep time = " + a.to_s
	sleep(a/1000)
	
	if testWaveOut
		puts "Playing audio done? A: " + aCard.wave_audio_play_done(devOutHandle).to_s
		aCard.stop_wave_audio_play(devOutHandle)
		aCard.close_wave_out_device(devOutHandle)
	end
	
	if testWaveIn
		puts "Bytes recorded = " + aCard.stop_wave_audio_record(devInHandle).to_s
		puts "Recording audio done? A: " + aCard.wave_audio_record_done(devInHandle).to_s
		aCard.close_wave_in_device(devInHandle)
    end
	
	aCard = nil
end
