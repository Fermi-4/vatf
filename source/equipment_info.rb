$equipment_table = nil #table containing information for all the equipment

#Singleton hash table. $equipment_table is an instance of this class
class InfoTable < Hash
  private_class_method :new #making the defualt constructor private
  @@table = nil #variable to hold the singleton

  #method to create the table with default value
  def InfoTable.create(defaultVal)
    @@table = Hash.new(defaultVal) unless @@table
    @@table
  end
  
  #method to create the table
  def InfoTable.create
    @@table = Hash.new unless @@table
    @@table
  end
end

class AudioHardwareInfo
  attr_accessor :analog_audio_inputs,:analog_audio_outputs,:digital_audio_inputs,:digital_audio_outputs, \
        :midi_audio_inputs, :midi_audio_outputs
end

class VideoIOInfo
  attr_accessor :vga_inputs, :vga_outputs, :component_inputs, :component_outputs, :composite_inputs, :composite_outputs, :svideo_inputs, \
        :svideo_outputs, :hdmi_inputs, :hdmi_outputs, :sdi_inputs, :sdi_outputs, :dvi_inputs, :dvi_outputs, :scart_inputs, :scart_outputs
end

class AudioIOInfo
  attr_accessor :rca_inputs, :rca_outputs, :xlr_inputs, :xlr_outputs, :optical_inputs, :optical_outputs, :mini35mm_inputs, :mini35mm_outputs, \
        :mini25mm_inputs, :mini25mm_outputs, :phoneplug_inputs, :phoneplug_outputs
end

#Class to store equipment information:
class EquipmentInfo
  public
    attr_reader :name, :id
    attr_accessor :telnet_ip, :telnet_port, :port_master, :driver_class_name, :audio_hardware_info, :telnet_login, 
            :telnet_passwd, :prompt, :boot_prompt, :executable_path, :nfs_root_path, :samba_root_path, \
            :login, :login_prompt, :power_port, :tftp_path, :tftp_ip, :video_io_info, :audio_io_info, :usb_ip
            
    #Constructor of the class            
    def initialize(name, id = nil)
      @name = name.downcase.strip
      @id = sort_caps(id.to_s.strip.downcase)
      @audio_hardware_info = AudioHardwareInfo.new
      @port_master = Array.new
      @video_io_info = VideoIOInfo.new
      @audio_io_info = AudioIOInfo.new
      $equipment_table = InfoTable.create
      if !$equipment_table[@name]
        $equipment_table[@name] = Hash.new
      end
      if !$equipment_table[@name][@id] 
        $equipment_table[@name][@id] = []
      end  
      $equipment_table[@name][@id] << self
    end
  
    def sort_caps(caps)
      caps_array = caps.split("_").sort
      result = caps_array[0]
      1.upto(caps_array.length-1){|i| result += '_' + caps_array[i]}
      result
    end
end
