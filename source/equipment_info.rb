$equipment_table = nil #table containing information for all the equipment

#Singleton hash table. $equipment_table is an instance of this class
class InfoTable < Hash
  private_class_method :new #making the defualt constructor private
  @@table = nil #variable to hold the singleton

  def InfoTable.create(defaultVal = nil)
    @@table = Hash.new(defaultVal) unless @@table
    @@table
  end
end

class AudioHardwareInfo
    attr_accessor :analog_audio_inputs
    attr_accessor :analog_audio_outputs
    attr_accessor :digital_audio_inputs
    attr_accessor :digital_audio_outputs
    attr_accessor :midi_audio_inputs
    attr_accessor :midi_audio_outputs
end

class VideoIOInfo
    attr_accessor :vga_inputs
    attr_accessor :vga_outputs
    attr_accessor :component_inputs
    attr_accessor :component_outputs
    attr_accessor :composite_inputs
    attr_accessor :composite_outputs
    attr_accessor :svideo_inputs
    attr_accessor :svideo_outputs
    attr_accessor :hdmi_inputs
    attr_accessor :hdmi_outputs
    attr_accessor :sdi_inputs
    attr_accessor :sdi_outputs
    attr_accessor :dvi_inputs
    attr_accessor :dvi_outputs
    attr_accessor :scart_inputs
    attr_accessor :scart_outputs
end

class AudioIOInfo
    attr_accessor :rca_inputs
    attr_accessor :rca_outputs
    attr_accessor :xlr_inputs
    attr_accessor :xlr_outputs
    attr_accessor :optical_inputs
    attr_accessor :optical_outputs
    attr_accessor :mini35mm_inputs
    attr_accessor :mini35mm_outputs
    attr_accessor :mini25mm_inputs
    attr_accessor :mini25mm_outputs
    attr_accessor :phoneplug_inputs
    attr_accessor :phoneplug_outputs
end

#Class to store equipment information:
class EquipmentInfo
    attr_reader :name
    attr_reader :id
    attr_accessor :telnet_ip
    attr_accessor :telnet_port
    attr_accessor :driver_class_name
    attr_accessor :audio_hardware_info
    attr_accessor :telnet_login
    attr_accessor :telnet_passwd
    attr_accessor :prompt
    attr_accessor :first_boot_prompt
    attr_accessor :boot_prompt
    attr_accessor :executable_path
    attr_accessor :nfs_root_path
    attr_accessor :samba_root_path
    attr_accessor :login
    attr_accessor :login_prompt
    attr_accessor :login_passwd
    attr_accessor :power_port
    attr_accessor :tftp_path
    attr_accessor :tftp_ip
    attr_accessor :video_io_info
    attr_accessor :audio_io_info
    attr_accessor :usb_ip
    attr_accessor :serial_server_ip
    attr_accessor :serial_server_port
    attr_accessor :serial_port
    attr_accessor :serial_params
    attr_accessor :board_id
    attr_accessor :boot_load_address
    attr_accessor :params
    attr_accessor :password_prompt
    attr_accessor :timeout
    attr_accessor :telnet_bin_mode


    #Constructor of the class
    def initialize(name, id = nil, &block)
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

      instance_eval &block if block_given?
    end
 
    private 
    def sort_caps(caps)
      result = caps.split("_").sort.join("_")
      result
    end
end
