require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/system_loader'

module Equipment
  
  class LinuxOmap5Driver < LinuxEquipmentDriver
   
    class Omap5ExtrasStep < SystemLoader::UbootStep
      def initialize
        super('omap5_extras')
      end

      def run(params)
        self.send_cmd params, "usb start", params['dut'].boot_prompt, 30
      end
    end

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      if params.has_key?("var_use_default_env") and params['var_use_default_env'].to_s == '1'
        @system_loader = SystemLoader::UbootDefaultEnvSystemLoader.new
      elsif params.has_key?("var_use_default_env") and params['var_use_default_env'].to_s == '2'
        @system_loader = SystemLoader::UbootLetItGoSystemLoader.new
      else
        @system_loader = SystemLoader::UbootSystemLoader.new
        @system_loader.insert_step_before('kernel', Omap5ExtrasStep.new)
      end
      if params.has_key?("bootargs_append")
        @system_loader.insert_step_before('boot', SetExtraArgsStep.new) 
      end
    end
  end
end

