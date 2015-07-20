class PowerHandler
  attr_reader :power_controllers

  def initialize
    @power_controllers = Hash.new

    [:get_status, :switch_on, :switch_off].each do |method|
      define_singleton_method(method) do |p_port|
        call(method, p_port)
      end
    end

  end

  def load_power_ports(lio_info)
    return if !lio_info
    io_info = lio_info
    io_info = [lio_info] if !io_info.kind_of?(Array)
      io_info.each { |io_info_element|
        io_info_element.each_key do |key|
          if !@power_controllers[key.to_s.downcase]
            @power_controllers[key.to_s.downcase] = Object.const_get($equipment_table['power_controller'][key.to_s.downcase][0].driver_class_name).new($equipment_table['power_controller'][key.to_s.downcase][0])
          end
        end
     }
    rescue Exception => e
      raise e.to_s+"\nUnable to create power controller: " + io_info.to_s
  end

  def disconnect
    @power_controllers.each_value { |val| val.disconnect()}
  end

  def reset(p_port)
    power_port = p_port
    power_port = [p_port] if !p_port.kind_of?(Array)
    power_port.each {|power_port_element|
      switch_off(power_port_element)
      sleep 1
      switch_on(power_port_element)
      # Sleep extra on first power port if there are multiple ports
      # First port most likely controls USB power so allow extra time
      sleep 3 if (power_port.size > 1 and power_port.index(power_port_element) == 0)
    }
  end

  private
    def call(method, p_port)
      power_port = p_port
      power_port = [p_port] if !p_port.kind_of?(Array)
      power_port.each do |port_info|
        port_info.each do |key, val|
         v_arr = val
         v_arr = [val] if !val.kind_of?(Array)
         v_arr.each do |v|
           puts "Calling #{method} on port #{v} at #{key} ..."
           @power_controllers[key.to_s.downcase].send(method, v)
         end
        end
      end
    end
end
