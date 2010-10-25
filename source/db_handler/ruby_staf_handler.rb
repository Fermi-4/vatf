if(system("staf local service help"))
  require File.dirname(__FILE__)+'/staf/STAFException'
  require File.dirname(__FILE__)+'/staf/STAFResult'
  if RUBY_PLATFORM.downcase.include?("mswin") || RUBY_PLATFORM.downcase.include?("mingw")
    require File.dirname(__FILE__)+'/staf/windows/STAFHandle'
  elsif RUBY_PLATFORM.downcase.include?("linux")
    require File.dirname(__FILE__)+'/staf/linux/STAFHandle'
  end
  require File.dirname(__FILE__)+'/staf/STAFCommand'
  include STAF
end
