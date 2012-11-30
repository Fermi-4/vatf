
require File.dirname(__FILE__)+'/equipment_info'
require File.dirname(__FILE__)+'/connection_equipment/connection_equipment'

include ConnectionEquipment
class ConnectionHandler
    attr_reader :media_switches, :equipment_switch_connections
    def initialize(files_dir)
      @files_dir = files_dir
      @media_switches = Hash.new
      @equipment_switch_connections = Hash.new
    end
    #This function loads the connections defined for each equipment in the switch into hashes, these hashes are used to keep track of the connections made
    #between equipments during a test.
    def load_switch_connections(var, class_type,class_id, index, iter)
      load_connections(var, 'video', $equipment_table[class_type][class_id][index].video_io_info, iter)
      load_connections(var, 'audio', $equipment_table[class_type][class_id][index].audio_io_info, iter)
      rescue Exception => e
      puts e.to_s
      raise
    end 
    
    #This function makes a video and audio connection between tests equipments, it connects the specified output of from_equip to the specified inputs of to_equip. Takes from_equip a hash whose entries are
    #of the form <equip> => <output_num>, where <equip> is an object related to an equipment and output_num is the index assigned to the output that will be used for the connection, to_equip a hash whose entries are
    #of the form <equip> => <input_num>, where <equip> is an object related to an equipment and input_num is the index assigned to the input that will be used for the connection, video_iface a string indicating the type of video connection (i.e composite)
    #, and audio_iface a string indicating the type of audio connection (i.e mini35mm)
    def make_connection(from_equip, to_equip)
    end
    
    #This function makes a video connection between tests equipments, it connects the specified output of from_equip to specified inputs of to_equip. Takes from_equip a hash whose entries are
    #of the form <equip> => <output_num>, where <equip> is an object related to an equipment and output_num is the index assigned to the output that will be used for the connection, to_equip a hash whose entries are
    #of the form <equip> => <input_num>, where <equip> is an object related to an equipment and input_num is the index assigned to the input that will be used for the connection, and iface a string indicating the type of video connection (i.e composite)
    def make_video_connection(from_equip, to_equip)
      make_io_connection(from_equip, to_equip, 'video')
      rescue Exception => e
        puts e.to_s
        raise
    end
    
    #This function makes an audio connection between tests equipments, it connects the specified output of from_equip to the specified inputs of to_equip. Takes from_equip a hash whose entries are
    #of the form <equip> => <output_num>, where <equip> is an object related to an equipment and output_num is the index assigned to the output that will be used for the connection, to_equip a hash whose entries are
    #of the form <equip> => <input_num>, where <equip> is an object related to an equipment and input_num is the index assigned to the input that will be used for the connection, and iface a string indicating the type of audio connection (i.e mini35mm)
    def make_audio_connection(from_equip, to_equip)
      make_io_connection(from_equip, to_equip, 'audio')
      rescue Exception => e
        puts e.to_s
        raise
    end
    
    def disconnect
      @media_switches.values.each{|switch_obj| switch_obj[0].disconnect}
    end
  
  private

  def load_connections(var, io_type, io_info, iter)
    io_info.instance_variables.each do |iface_type|
      io_info.instance_variable_get(iface_type).each do |key,val|
        switch_direction = '_outputs'
        switch_direction = '_inputs' if iface_type.to_s.include?('output')
        switch_log = @files_dir+"/switch"+iter.to_s+"_"+key.to_s+"_log.txt"
        if !@media_switches[key]
          @media_switches[key] = [Object.const_get($equipment_table['media_switch'][key.to_s][0].driver_class_name).new($equipment_table['media_switch'][key.to_s][0], switch_log),switch_log]
        end
        current_iface_type = iface_type.to_s.sub('@','').sub(/_.*$/,switch_direction)
        @equipment_switch_connections[var] = Hash.new if !@equipment_switch_connections[var]
        @equipment_switch_connections[var][io_type] = Hash.new if !@equipment_switch_connections[var][io_type]
        @equipment_switch_connections[var][io_type][current_iface_type] = Array.new if !@equipment_switch_connections[var][io_type][current_iface_type]
        @equipment_switch_connections[var][io_type][current_iface_type] = @equipment_switch_connections[var][io_type][current_iface_type] | get_io_array(key,val)
        @media_switches[key][0].disconnect_video(val) if io_info.kind_of?(VideoIOInfo) && iface_type.to_s.include?('input')
        @media_switches[key][0].disconnect_audio(val) if io_info.kind_of?(AudioIOInfo) && iface_type.to_s.include?('input')
      end
    end
    rescue Exception => e
      raise e.to_s+"\n"+e.backtrace.to_s+"\nUnable to load #{io_type.to_s} IO information for #{var.to_s}"
  end
  
  def make_io_connection(from, to, io_type)
    if @media_switches.length > 0
      source = from.keys[0]
      source_output = from[source]
      src_output_type = source_output.keys[0]
      src_output_number = source_output[src_output_type]
      switch_id = @equipment_switch_connections[source][io_type][src_output_type+"_inputs"][src_output_number][0]
      switch = @media_switches[switch_id][0]
      switch_outputs_array = Array.new
      to.each do |equip, input_info|
        input_info.each do |iface_type, sw_output_number|
          switch_outputs_array << @equipment_switch_connections[equip][io_type][iface_type+"_outputs"][sw_output_number][1]
        end
      end
      switch.send('connect_'+io_type, @equipment_switch_connections[source][io_type][src_output_type+"_inputs"][src_output_number][1], switch_outputs_array)
    end
    rescue Exception => e
      raise e.backtrace.to_s+"\n Unable to make #{io_type.to_s} connection from #{from.to_s.gsub(/[<#>]+/,'')} to #{to.to_s.gsub(/[<#>]+/,'')}"
  end
  
  def get_io_array(switch_id,io_ranges)
    io_array = Array.new
    io_ranges.each do |current_range|
      io_string_array = current_range.to_s.split('-')
      start_io = end_io = io_string_array[0].to_i
      end_io = io_string_array[1].to_i if io_string_array[1]
      start_io.upto(end_io){|current_io| io_array << [switch_id, current_io]}
    end
    io_array
  end
end
