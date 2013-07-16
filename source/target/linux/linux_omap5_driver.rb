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
        self.send_cmd params, "setenv usbethaddr #{get_random_mac_address()}", params['dut'].boot_prompt, 2
        self.send_cmd params, "usb start", params['dut'].boot_prompt, 30
      end
    end

    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      @system_loader = SystemLoader::UbootSystemLoader.new
      @system_loader.insert_step_before('kernel', Omap5ExtrasStep.new)
    end
  end

end

