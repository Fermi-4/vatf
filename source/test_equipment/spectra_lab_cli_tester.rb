# -*- coding: ISO-8859-1 -*-
require 'spectra_lab_cli'

class SpectraLabInfo
    attr_reader :telnet_ip, :telnet_port
  
  def initialize
    @telnet_ip = '10.218.111.202'
    @telnet_port = 8787
  end
  
end

a = TestEquipment::SpectraLab.new(SpectraLabInfo.new,"C:\spectra_lab.txt")
a.process_file('C:\Video_tools\Mixed11_11KHz_Mono.wav')
b = a.get_test_stats
b.each {|key,val| puts key.to_s+"= "+val.to_s}
sleep(5)
a.disconnect
