require File.dirname(__FILE__)+'/linux_equipment_driver'
require File.dirname(__FILE__)+'/build_client'
require File.dirname(__FILE__)+'/../../lib/cmd_translator'
require File.dirname(__FILE__)+'/../../lib/sysboot'
require File.dirname(__FILE__)+'/../../site_info.rb'
require File.dirname(__FILE__)+'/boot_loader'
require File.dirname(__FILE__)+'/system_loader'

module Equipment

  class LinuxAm65xDriver < LinuxEquipmentDriver

    class R5BootStep < SystemLoader::UbootStep
      def initialize
        super('r5_boot')
      end

      def run(params)
        boot_timeout = params['var_boot_timeout'] ? params['var_boot_timeout'].to_i : 210
        send_cmd params, "rproc init; rproc list;rproc load 1 0x70000000 0x200; rproc start 1", /.*/, 1, true, false
        params['dut'].target.default = params['dut'].target.serial
        send_cmd params, "", params['dut'].login_prompt, boot_timeout, true, false
        params['dut'].boot_log = params['dut'].response
        params['dut'].check_for_boot_errors()
        if params['dut'].timeout?
          params['dut'].log_info("Collecting kernel traces via sysrq...")
          params['dut'].send_sysrq('t')
          params['dut'].send_sysrq('l')
          params['dut'].send_sysrq('w')
        end
        3.times {
          send_cmd params, params['dut'].login, params['dut'].prompt, 40, false, false # login to the unit
          break if !params['dut'].timeout?
        }
        raise "Error executing boot" if params['dut'].timeout?

      end
    end

    class SwitchConsoleStep < SystemLoader::UbootStep
      def initialize
        super('switch_console')
      end

      def run(params)
        params['dut'].target.default = params['dut'].target.bootloader
      end
    end


    # Select SystemLoader's Steps implementations based on params
    def set_systemloader(params)
      @system_loader = SystemLoader::AtfSystemLoader.new
      @system_loader.remove_step('')
      @system_loader.replace_step('boot', R5BootStep.new)  if @system_loader.contains?('boot')
      @system_loader.insert_step_before('setip', SwitchConsoleStep.new) if @system_loader.contains?('setip')
    end

  end
end
