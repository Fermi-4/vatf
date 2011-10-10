require File.dirname(__FILE__)+'/../equipment_driver'

module Equipment

  class Cent0SEquipmentDriver < EquipmentDriver

    def connect(params)
      super(params)
      case params['type'].to_s.downcase.strip
      when 'serial'
        send_cmd("\n", /.*/, 10) 	
        send_cmd("\n", /.*/, 10) 	
        wait_for(/localhost login:/, 360) 	  
        if response.include?('login')
          send_cmd(@login,/Password/,10, false)
          raise 'Unable to login' if timeout?
        end
        if response.include?('Password')
          send_cmd(@login_passwd,//,10, false)
          raise 'Unable to login' if timeout?
        end
      end
    end
  
  end
end
