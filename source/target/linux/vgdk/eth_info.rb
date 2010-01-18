
module ETHInfo
    class Eth_info
        attr_reader :platform_ip, :platform_mac, :eth_dev, :pc_ip, :pc_mac
        def initialize
            cores = 6
            begin
            f_pc_ip = File.open("C:\\VGDK\\pc_eth.txt",File::RDWR)
            rescue 
              $stderr.print "File.open failed" + $!
              raise
            end
            begin
              while (line = f_pc_ip.readline)
                case (line)
                  when /^#/
                    # do nothing
                  when /PC_ETH/
                    @pc_ip = f_pc_ip.gets.chomp.to_s
                    @pc_mac = f_pc_ip.gets.chomp.to_s 
                    @eth_dev = f_pc_ip.gets.chomp.to_s 
                  when /PLATFORM_IP/
                    @platform_ip = Hash.new
                    cores.times do |i|
                      @platform_ip["CORE_#{i}"] = f_pc_ip.gets.chomp.to_s
                    end
                  when /PLATFORM_MAC/
                    @platform_mac = Hash.new
                    cores.times do |i|
                      @platform_mac["CORE_#{i}"] = f_pc_ip.gets.chomp.to_s
                    end
                end
              end
            rescue EOFError
              f_pc_ip.close
            end 
        end
        def get_platform_ip
           @platform_ip
        end
        def get_platform_mac
           @platform_mac
        end
        def get_eth_dev
          @eth_dev
        end
        def get_pc_ip
          @pc_ip
        end
        def get_pc_mac
          @pc_mac
        end
  end
end