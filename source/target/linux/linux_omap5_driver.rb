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
      super
      @system_loader.insert_step_before('setip', Omap5ExtrasStep.new) if @system_loader.is_a?(SystemLoader::UbootSystemLoader)
    end
  end
end

