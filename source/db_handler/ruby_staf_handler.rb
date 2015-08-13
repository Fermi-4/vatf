require File.dirname(__FILE__)+'/../lib/os_func.rb'
if(system("staf local service help"))
  require File.dirname(__FILE__)+'/staf/STAFException'
  require File.dirname(__FILE__)+'/staf/STAFResult'
  if OsFunctions::is_windows?
    require File.dirname(__FILE__)+'/staf/windows/STAFHandle'
  elsif OsFunctions::is_linux?
    if OsFunctions::is_64bit? 
      require File.dirname(__FILE__)+'/staf/linux/64bit/' + RUBY_VERSION.match(/^\d+\.\d+/)[0] + '/STAFHandle'
    else
      require File.dirname(__FILE__)+'/staf/linux/32bit/STAFHandle'
    end
  end
  require File.dirname(__FILE__)+'/staf/STAFCommand'
  include STAF
end
