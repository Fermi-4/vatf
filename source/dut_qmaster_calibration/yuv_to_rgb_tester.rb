require 'yuv_to_rgb'

a = YuvToRGBConverter.new
b = Yuv422To444Converter.new
b.convert_uyvy("img6446.yuv",720,480,"img6446.yuv")
rgb_vals = a.convert_uyvy422_file("img1.yuv",720,480)
a.print_rgb_vals_to_csv("dut_rgb_vals.txt")
#a.print_rgb_vals_to_csv("dut_rgb_vals_firstquarter.txt",0,0,239,359)
a.print_rgb_vals_to_csv("dut_rgb_vals_lasteigth.txt",360,540,479,719)
#a.get_yuv_vals(479,719).each {|val| puts "yuv "+val.to_s}
