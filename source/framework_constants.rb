module FrameworkConstants
  Result = {:nry => 0, :pass => 1, :fail => 2, :blk =>3, :opt =>4, :ns =>5, :np =>3}
  Status = {:idle => 0,:pending => 1, :running => 2, :cancelled =>3, :complete =>4}
  Optimum_mode = {:ext_to_ether_in => 0, :ext_to_comp_in => 1, :ext_to_s_in => 2, :int_to_ether_in =>3, :int_to_comp_in =>4, :int_to_s_in => 5}
  Streaming_Protocol = {:udp => 1, :rtp => 2}
end
