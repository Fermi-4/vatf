require 'rubygems'
require 'FileConverter'

#YuvToBmpConverter::convert('-a convert -N c:\videoTools\football.bmp -S BMP -n c:\videoTools\football_352x288_420p_90frames.yuv -s yuv420 -o yuv -f progressive -p planar -w 352 -h 288 -e exit')
a = YuvToBmpConverter.new
a.convert( { 'inFile' => 'C:\Video_tools\football_352x240_420p_125frames.yuv',
#YuvToBmpConverter::convert( { 'inFile' => 'c:\4CIF_YUV\football_704x480_420p_150frames.yuv',
                              'inSamplingFormat'  => 'yuv420',
                              'inComponentOrder'  => 'yuv',
                              'inFieldFormat'     => 'progressive',
                              'inPixelFormat'     => 'planar',
                              'inHeight'          => '240',
                              'inWidth'           => '352',
                              'outFile'           => 'C:\Video_tools\football_352x240_420p_125frames.bmp',
                              'outSamplingFormat' => 'BMP',
                              'outFieldFormat'    => 'progressive',
                              'outPixelFormat'    => 'planar' } )
b = BmpToAviConverter.new
#BmpToAviConverter::convert('-start C:\Video_tools\football_0000.bmp -end C:\Video_tools\football_0089.bmp -framerate 15 -output C:\Video_tools\football.avi')
b.convert( {'start'     => 'C:\Video_tools\football_352x240_420p_125frames_0000.bmp',
                             'end'       => 'C:\Video_tools\football_352x240_420p_125frames_124.bmp',
                             'frameRate' => '30',
                             'output'    => 'C:\Video_tools\football_352x240_420p_125frames.avi'} )
=begin
d = PcmToWave.new
d.convert('C:\Video_tools\test1_16bIntel.u','C:\Video_tools\ruby_test1_16bIntel_ulaw.wav')
d.convert('C:\Video_tools\test1_16bIntel.a','C:\Video_tools\ruby_test1_16bIntel_alaw.wav',"alaw")
d.convert('C:\Video_tools\test1_16bIntel.pcm','C:\Video_tools\ruby_test1_16bIntel_linear.wav',"linear", 1, 8000, 16000, 2, 16)

e = WaveToPcm.new
e.convert('C:\Video_tools\test1_16bIntel_ulaw.wav','C:\Video_tools\ruby_test1_16bIntel_ulaw.u')
e.convert('C:\Video_tools\test1_16bIntel_alaw.wav','C:\Video_tools\ruby_test1_16bIntel_alaw.a')
e.convert('C:\Video_tools\test1_16bIntel_linear.wav','C:\Video_tools\ruby_test1_16bIntel.pcm')


f = Mpeg4To420pYuvConverter.new
f.convert({'Source' => 'C:\Video_tools\amelie_9_720x480_420p_468frames_6000000bps.mpeg4','Target' => 'C:\Video_tools\amelie_9_720x480_420p_468frames_6000000bps_converter_test.yuv'})
=end 