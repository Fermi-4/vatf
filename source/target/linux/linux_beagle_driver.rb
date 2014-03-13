require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/system_loader'

module Equipment
  
  class LinuxBeagleDriver < LinuxEquipmentDriver
   
    class BeagleExtrasStep < SystemLoader::UbootStep
      def initialize
        super('beagle_extras')
      end

      def run(params)
        self.send_cmd params, "dcache off"
        self.send_cmd params, "usb start", params['dut'].boot_prompt, 30
      end
    end

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      @system_loader = SystemLoader::UbootSystemLoader.new
      @system_loader.insert_step_before('setip', BeagleExtrasStep.new)
    end
  end

end

