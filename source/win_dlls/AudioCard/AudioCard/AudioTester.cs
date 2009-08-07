using System;
using System.Collections.Generic;
using System.Collections;
using System.Text;
using TeHandlers;
using System.IO;

namespace TeHandlers
{
    class AudioTester
    {

        public AudioTester() { }

        [STAThread]
        static int Main()
        {
            Random randomSleep = new Random();
            try
            {
                for (int i = 0; i < 500; i++)
                {
                    System.Console.WriteLine("Running iteration: "+i.ToString());
                    bool testWaveIn = true;
                    bool testWaveOut = true;
                    bool test8KHz = false;
                    bool test44K1Hz = false;
                    bool test96KHz = false;
                    bool test48KHz = false;

                    int maxIOtime = 1000;
                    System.Console.WriteLine(System.GC.GetTotalMemory(false));
                    Hashtable equipmentInfo = new Hashtable();
                    equipmentInfo["analog_inputs"] = "0";
                    equipmentInfo["analog_outputs"] = "0";
                    equipmentInfo["digital_inputs"] = "1";
                    equipmentInfo["digital_outputs"] = "1";
                    AudioCard aCard = new AudioCard(equipmentInfo, "C:\\Audiocard_log.txt");

                    Hashtable audioParams = new Hashtable();
                    if (randomSleep.Next(5)  >= 2) test44K1Hz = true;
                    else test8KHz = true;
                    
                    if (test44K1Hz)
                    {
                        maxIOtime = 65000;
                        audioParams["device_id"] = 0;
                        audioParams["device_type"] = "analog";
                        audioParams["ext_param_size"] = 0;
                        audioParams["avg_bytes_per_sec"] = 176400;
                        audioParams["channels"] = 2;
                        audioParams["samples_per_sec"] = 44100;
                        audioParams["bits_per_sample"] = 16;
                        audioParams["format_tag"] = 1;
                    }

                    if (test48KHz)
                    {
                        maxIOtime = 65000;
                        audioParams["device_id"] = 0;
                        audioParams["device_type"] = "analog";
                        audioParams["ext_param_size"] = 0;
                        audioParams["avg_bytes_per_sec"] = 192000;
                        audioParams["channels"] = 2;
                        audioParams["samples_per_sec"] = 48000;
                        audioParams["bits_per_sample"] = 16;
                        audioParams["format_tag"] = 1;
                    }
                    
                    if(test8KHz)
                    {
                        maxIOtime = 11000;
                        audioParams["device_type"] = "analog";
                        audioParams["device_id"] = 0;
                        audioParams["ext_param_size"] = 0;
                        audioParams["avg_bytes_per_sec"] = 16000;
                        audioParams["channels"] = 1;
                        audioParams["samples_per_sec"] = 8000;
                        audioParams["bits_per_sample"] = 16;
                        audioParams["format_tag"] = 1;
                    }

                    if (test96KHz)
                    {
                        audioParams["device_type"] = "digital";
                        audioParams["device_id"] = 0;
                        audioParams["ext_param_size"] = 0;
                        audioParams["avg_bytes_per_sec"] = 384000;
                        audioParams["channels"] = 2;
                        audioParams["samples_per_sec"] = 96000;
                        audioParams["bits_per_sample"] = 16;
                        audioParams["format_tag"] = 1;
                    }
                    int devInHandle = 0;
                    int devOutHandle = 0;

                    System.Console.WriteLine(System.GC.GetTotalMemory(false));
                    if (testWaveIn)
                    {
                        System.Console.WriteLine("Testing Wave In.....");
                        System.Console.WriteLine("Number of Wave Inputs: " + aCard.GetWaveInDevices());
                        Hashtable devCaps = aCard.GetWaveInDeviceCapabilities(0);
                        System.Console.WriteLine("name = "+(string)devCaps["name"]);
                        System.Console.WriteLine("formats = "+((uint)devCaps["formats"]).ToString());
                        devInHandle = aCard.OpenWaveInAudioDevice(audioParams);
                        aCard.RecordWaveAudio(devInHandle, "C:\\test_file.pcm");
                        System.Console.WriteLine("Recording audio done? A: " + aCard.WaveAudioRecordDone(devInHandle).ToString());
                    }
                    if (testWaveOut)
                    {
                        System.Console.WriteLine("Testing Wave Out.....");
                        System.Console.WriteLine("Number of Wave Outputs: " + aCard.GetWaveOutDevices());
                        Hashtable devCaps = aCard.GetWaveOutDeviceCapabilities(0);
                        System.Console.WriteLine("name = "+(string)devCaps["name"]);
                        System.Console.WriteLine("formats = "+((uint)devCaps["formats"]).ToString());
                        System.Console.WriteLine("support = "+((uint)devCaps["support"]).ToString());
                        devOutHandle = aCard.OpenWaveOutAudioDevice(audioParams);
                        if (test8KHz) aCard.PlayWaveAudio(devOutHandle, "C:\\test1_16bIntel.pcm");
                        if (test96KHz) aCard.PlayWaveAudio(devOutHandle, "C:\\harp40_96kHz_s.pcm"); // valid for digital IO only
                        if (test44K1Hz) aCard.PlayWaveAudio(devOutHandle, "C:\\HipHop_Shadowboxing_44KHz_Stereo.pcm");
                        if (test48KHz) aCard.PlayWaveAudio(devOutHandle, "C:\\Stress_48KHz_Stereo.pcm");
                        System.Console.WriteLine("Playing audio done? A: " + aCard.WaveAudioPlayDone(devOutHandle).ToString());
                    }
                    int a = randomSleep.Next(1000, maxIOtime);
                    System.Console.WriteLine("sleep time = " + a.ToString());
                    System.Threading.Thread.Sleep(a);
                    if (testWaveOut)
                    {
                        System.Console.WriteLine("Playing audio done? A: " + aCard.WaveAudioPlayDone(devOutHandle).ToString());
                        aCard.StopWaveAudioPlay(devOutHandle);
                        aCard.CloseWaveOutDevice(devOutHandle);
                    }
                    if (testWaveIn)
                    {
                        System.Console.WriteLine("Bytes recorded = "+aCard.StopWaveAudioRecord(devInHandle).ToString());
                        System.Console.WriteLine("Recording audio done? A: " + aCard.WaveAudioRecordDone(devInHandle).ToString());
                        aCard.CloseWaveInDevice(devInHandle);
                    }
                    System.Console.WriteLine(System.GC.GetTotalMemory(false) + "\n\n");
                    aCard = null;
                    System.Threading.Thread.Sleep(1000);
                }
                System.Console.WriteLine("End of tests.....");
                System.Console.ReadLine();
            }
            catch (Exception e)
            {
                System.Console.WriteLine(e.ToString());
                System.Console.ReadLine();
            }
            return 0;
        }
    }
}
