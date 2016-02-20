
require File.dirname(__FILE__)+'/equipment_info'
require File.dirname(__FILE__)+'/connection_equipment/connection_equipment'

include ConnectionEquipment
class ConnectionHandler
    attr_reader :media_switches, :logs
    def initialize(files_dir)
      @files_dir = files_dir
      @media_switches = Hash.new
      @logs = Hash.new()
    end
    
    #This function makes a video and audio connection between tests equipments, it connects the specified output of from_equip to the specified inputs of to_equip. Takes from_equip a hash whose entries are
    #of the form <equip> => <output_num>, where <equip> is an object related to an equipment and output_num is the index assigned to the output that will be used for the connection, to_equip a hash whose entries are
    #of the form <equip> => <input_num>, where <equip> is an object related to an equipment and input_num is the index assigned to the input that will be used for the connection, video_iface a string indicating the type of video connection (i.e composite)
    #, and audio_iface a string indicating the type of audio connection (i.e mini35mm)
    def make_video_audio_connection(from_equip, to_equip)
      make_io_connection(from_equip, to_equip, 'video_audio')
    end
    
    #This function makes a video connection between tests equipments, it connects the specified output of from_equip to specified inputs of to_equip. Takes from_equip a hash whose entries are
    #of the form <equip> => <output_num>, where <equip> is an object related to an equipment and output_num is the index assigned to the output that will be used for the connection, to_equip a hash whose entries are
    #of the form <equip> => <input_num>, where <equip> is an object related to an equipment and input_num is the index assigned to the input that will be used for the connection, and iface a string indicating the type of video connection (i.e composite)
    def make_video_connection(from_equip, to_equip)
      make_io_connection(from_equip, to_equip, 'video')
    end
    
    #This function makes an audio connection between tests equipments, it connects the specified output of from_equip to the specified inputs of to_equip. Takes from_equip a hash whose entries are
    #of the form <equip> => <output_num>, where <equip> is an object related to an equipment and output_num is the index assigned to the output that will be used for the connection, to_equip a hash whose entries are
    #of the form <equip> => <input_num>, where <equip> is an object related to an equipment and input_num is the index assigned to the input that will be used for the connection, and iface a string indicating the type of audio connection (i.e mini35mm)
    def make_audio_connection(from_equip, to_equip)
      make_io_connection(from_equip, to_equip, 'audio')
    end
    
    def disconnect
      @media_switches.values.each do|switch_obj|
        switch_obj.stop_logger 
        switch_obj.disconnect
      end
    end
    
    def get_switch(info)
      sw_info = get_sw_info(info)
      @media_switches[sw_info]
    end

  private
  
  def make_io_connection(from, to, io_type)
    sw_info = get_sw_info(from)
    to_info = get_sw_info(to)
    if sw_info.name != to_info.name || sw_info.id != to_info.id
      puts "WARNING: Trying to connect io in different switches"
      return false
    end
    init_switch(sw_info)
    switch_outputs_array = get_io_array(to.values)
    @media_switches[sw_info].send('connect_'+io_type, from.values.flatten.join(''), switch_outputs_array)
    true
    rescue Exception => e
      begin
        raise "Unable to make #{io_type.to_s} connection: input #{[sw_str, from.values.to_s].join('-')} to output(s) #{[to_info.name, to_info.id, to.values.to_s].join('-')}\n" + e.backtrace.to_s 
      rescue Exception => e2
        raise e
      end
  end
  
  def get_sw_info(id)
    sw_info = id.keys[0]
    sw_info = $equipment_table['media_switch'][sw_info.to_s][0] if sw_info.is_a?(Fixnum) || sw_info.is_a?(String)
    sw_info
  end
  
  def init_switch(sw_info)
    sw_str = [sw_info.name, sw_info.id].join('-')
    if !@media_switches.has_key?(sw_info)
      switch_log = @files_dir+"/switch_#{sw_str}_log.txt"
      @media_switches[sw_info] = Object.const_get(sw_info.driver_class_name).new(sw_info, switch_log)
      @logs[sw_str] = switch_log
    end
  end
  
  def get_io_array(io_ranges)
    io_array = Array.new
    return io_array if !io_ranges
    Array(io_ranges).each do |current_range|
      io_string_array = current_range.to_s.split('-')
      io_array + [*io_string_array[0].to_i..io_string_array[-1].to_i]
    end
    io_array
  end
end
