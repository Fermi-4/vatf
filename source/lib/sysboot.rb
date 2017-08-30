module SysBootModule

# Function to set sysboot via relay to $setting
#     This function is to switch the diff bits between $setting and default setting 
# Setup:    
#     The sysboot pins are connected to relay ports. 'pin0' to 'relay port1', 
#     'pin1' to 'relay port2' and so on. Also, the connection should be set to 
#     default bootmode.
# Input: 'setting' [n:0], Ex: '110111'
def SysBootModule.set_sysboot(dut, setting)
  return if !dut.instance_variable_defined?(:@params) or !dut.params.key?('sysboot_ctrl')
  sysboot_controller = Object.const_get(dut.params['sysboot_ctrl'].driver_class_name).new(dut.params['sysboot_ctrl'])

  default_bootmedia = get_default_bootmedia(dut.name)
  default_sysboot = get_sysboot_setting(dut, default_bootmedia)

  # find out which bit need to be change, either on->off or off->on
  sysboot_diff = get_sysboot_diff(default_sysboot, setting)
  # if bit in sysboot_diff is 1, means there is change; otherwise, no change
  sysboot_diff.reverse.split("").each_with_index do |val,idx|
    next if val == '0'
    puts "Changing state for sysboot pin: #{idx}"
    sysboot_controller.switch_off(idx.to_i + 1)   #idx starts from 0 and relay port starts from 1
  end
end

def SysBootModule.reset_sysboot(dut)
  return if !dut.instance_variable_defined?(:@params) or !dut.params.key?('sysboot_ctrl')
  puts "resetting sysboot to default..."
  sysboot_controller = Object.const_get(dut.params['sysboot_ctrl'].driver_class_name).new(dut.params['sysboot_ctrl'])

  default_bootmedia = get_default_bootmedia(dut.name)
  default_sysboot = get_sysboot_setting(dut, default_bootmedia)

  default_sysboot.split("").each_with_index do |val,idx|
    puts "resetting pin: #{idx}"
    sysboot_controller.switch_on(idx.to_i + 1)
  end

end


# Compare two binary settings. 
# Input: s1 and s2 are binary string like '11011'
# Output: binary string 
#   '1' means there is difference; '0' means no diff
def SysBootModule.get_sysboot_diff(s1, s2)
  return ( s1.to_i(2) ^ s2.to_i(2) ).to_s(2)
end

  # the sysboot format [5:0] 
def SysBootModule.get_sysboot_setting(dut, boot_media)
    return if !dut.instance_variable_defined?(:@params) or !dut.params.key?('sysboot_ctrl')
    platform = dut.name.downcase
    boot_media  = boot_media.downcase
    machines = {}
    machines['dra7xx-evm'] = {'qspi'=>'110111', 'mmc'=>'110000', 'emmc'=>'111000', 'uart'=>'010011', 'spldfu'=>'010000', 'nand'=>'111001'}
    machines['dra72x-evm'] = machines['dra7xx-evm']
    machines['dra71x-evm'] = machines['dra7xx-evm']
    machines['dra72x-hsevm'] = machines['dra7xx-evm']
    machines['dra71x-hsevm'] = machines['dra7xx-evm']
    machines['dra7xx-hsevm'] = machines['dra7xx-evm']
    machines['am43xx-gpevm'] = {'mmc'=>'101100', 'nand'=>'100110', 'eth'=>'111100', 'usbeth'=>'111101', 'usbmsc'=>'111110', 'uart'=>'111010', 'qspi'=>'101010' }
    machines['am437x-sk'] = machines['am43xx-gpevm']
    machines['am43xx-hsevm'] = machines['am43xx-gpevm']
    machines['am335x-evm'] = {'mmc'=>'10111', 'nand'=>'10100', 'uart'=>'00101', 'usbeth'=>'01101', 'eth'=>'01010' }

    raise "Sysboot setting for #{boot_media} not defined for #{platform}" if !machines[platform][boot_media]
    machines[platform][boot_media]
end

def SysBootModule.get_default_bootmedia(platform)
    platform = platform.downcase
    case platform
    when /k2hk-evm|k2e-evm|k2l-evm/
      return 'nand'
    else
      return 'mmc'
    end
end


end 
