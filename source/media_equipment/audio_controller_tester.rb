require 'audio_controller'

include MediaEquipment

class AudioInfo
  
  def initialize
  end 
end

a = AudioController.new(nil,'C:\audio_log.txt')
a.sync_play_and_record_wav_file("C:\\AAC_Audio_files\\CLASSIC1_24kHz_m.wav", "C:\\AAC_Audio_files\\atest1.wav")
a.start_recording_wav_file("C:\\AAC_Audio_files\\atest2.wav")
a.async_play_wav_file("C:\\AAC_Audio_files\\CLASSIC1_24kHz_m.wav")
sleep 25
a.stop_recording_wav_file()
a.stop_playing_wav_file()
a.start_time_recording_wav_file("C:\\AAC_Audio_files\\atest3.wav",  7000)
a.sync_play_wav_file("C:\\AAC_Audio_files\\CLASSIC1_24kHz_m.wav")
a.stop_recording_wav_file()
