using System;
using System.Collections.Generic;
using System.Text;
using Ti.Atf.Ted.Drivers;

namespace Ti.Atf.Ted.Drivers
{
    public sealed class AudioControllerTester
    {
    

        [STAThread]
        static int Main() 
        {
            try
            {
                AudioController audio_test = new AudioController();
                RecAudioParams audioParams = new RecAudioParams();
                audioParams.channels = 1;
                audioParams.samplesPerSec = 24000;
                audioParams.bitsPerSample = 16;
                audioParams.bytesPerSec = 88000;
                audioParams.alignment = 2;
                audioParams.recFileName = "C:\\AAC_Audio_files\\atest.wav";
                audio_test.PlayWavFile("C:\\AAC_Audio_files\\CLASSIC1_24kHz_m.wav");
                audio_test.PlayAndRecordWavFile("C:\\AAC_Audio_files\\CLASSIC1_24kHz_m.wav", "C:\\AAC_Audio_files\\atest.wav");
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
