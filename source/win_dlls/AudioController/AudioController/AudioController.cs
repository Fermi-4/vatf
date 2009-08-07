using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using Ti.Atf.Ted.Drivers;
using System.Threading;

namespace Ti.Atf.Ted.Drivers
{
   // [GuidAttribute("E8730C0D-0E50-4af7-9785-AA8FAE7EA222")]
    [ClassInterface(ClassInterfaceType.AutoDual)]
   // [ProgId("test_equipment.AudioController")]
    public class RecAudioParams
    {
        public uint samplesPerSec = 8000;
        public uint channels = 2;
        public object alignment = null;
        public uint bitsPerSample = 8;
        public string format = "pcm";
        public string recFileName = null;
        public uint bytesPerSec = 8000;
    }

    public class AudioController : BaseMCIController
    {
        private string recordFile;
        private string playAlias = "wavSrcFile";
        private string recAlias = "wavRecFile";
        public AudioController()
        {
        }
        
        public void PlayWavFile(string fileName)
        {
            try
            {
                OpenWavDevice(fileName, playAlias);
                if (SendCommand("play " + playAlias + " wait", IntPtr.Zero) != 0)
                {
                    throw new Exception("Unable to play wav file " + fileName);
                }
            }
            finally
            {
                SendCommand("close " + this.playAlias, IntPtr.Zero);
            }

         
        }

        public void PlayAndRecordWavFile(string srcFile, RecAudioParams recordingParameters)
        {
            StartRecordingWavFile(recordingParameters);
            PlayWavFile(srcFile);
            StopRecordingWavFile();
        }

        public void PlayAndRecordWavFile(string srcFile, string fileName)
        {
            StartRecordingWavFile(fileName);
            PlayWavFile(srcFile);
            StopRecordingWavFile();
        }

        public uint SendCommand(string command, IntPtr cmdDelegate)
        {
            return mciSendString(command, new StringBuilder(""), 10, cmdDelegate);
        }


        private uint OpenWavDevice(string devName, string devAlias)
        {
            if (SendCommand("open " + devName + " type waveaudio alias " + devAlias, IntPtr.Zero) == 0)
            {
                throw new Exception("Unable to open " + devName);
            }
            return mciGetDeviceID(devAlias);
        }

        public void StartRecordingWavFile(RecAudioParams audioParams)
        {
            OpenWavDevice("new", recAlias);
            this.recordFile = audioParams.recFileName;
            try
            {
                SetRecParams(audioParams);
                if (SendCommand("record " + this.recAlias, IntPtr.Zero) != 0)
                {
                    throw new Exception("Unable to start wav recording process for file " + audioParams.recFileName);
                }
                
            }
            catch(Exception e)
            {
                SendCommand("close "+this.recAlias, IntPtr.Zero);
                throw e;
            }
        }

        public void StartRecordingWavFile(string fileName)
        {
            OpenWavDevice("new", recAlias);
            this.recordFile = fileName;
            try
            {
                if (SendCommand("record " + this.recAlias, IntPtr.Zero) != 0)
                {
                    throw new Exception("Unable to start wav recording process for file " + fileName);
                }

            }
            catch (Exception e)
            {
                SendCommand("close " + this.recAlias, IntPtr.Zero);
                throw e;
            }
        }

        public void StartRecordingWavFile(RecAudioParams audioParams, uint msecDuration)
        {
            OpenWavDevice("new", recAlias);
            this.recordFile = audioParams.recFileName;
            try
            {
                SetRecParams(audioParams);
                if (SendCommand("record " + this.recAlias+ "to "+msecDuration.ToString(), IntPtr.Zero) != 0)
                {
                    throw new Exception("Unable to start wav recording process for file " + audioParams.recFileName);
                }

            }
            catch (Exception e)
            {
                SendCommand("close " + this.recAlias, IntPtr.Zero);
                throw e;
            }
        }

        public void StopRecordingWavFile()
        {
            uint saveResult = SendCommand("stop " + this.recAlias, IntPtr.Zero);
            saveResult += SendCommand("save " + this.recAlias + " " + this.recordFile, IntPtr.Zero);
            SendCommand("close " + this.recAlias, IntPtr.Zero);

            if (saveResult != 0)
            {
                throw new Exception("Unable to save audio data into file " + this.recordFile);
            }
        }

        private void SetRecParams(RecAudioParams audioParams)
        {
            string setCommand = "set " + this.recAlias + " time format milliseconds";
            if (audioParams.alignment != null)
            {
                setCommand += " alignment " + ((int)audioParams.alignment).ToString();
            }
            setCommand += " bitspersample " + audioParams.bitsPerSample.ToString() + " channels " + audioParams.channels.ToString() + " samplespersec " + audioParams.samplesPerSec.ToString() + " format tag " + audioParams.format.ToString() + " wait";
            if (SendCommand(setCommand,IntPtr.Zero) != 0)
            {
                SendCommand("close " + this.recAlias, IntPtr.Zero);
                throw new Exception("Unable to set recorder parameters");
            }
            if (SendCommand("set " + this.recAlias + " bytespersec " + audioParams.bytesPerSec.ToString() + " wait", IntPtr.Zero) != 0) System.Console.WriteLine("Warning set " + this.recAlias + " bytespersec " + audioParams.bytesPerSec.ToString() + " wait was not successful!!!!");

        }

    }
}
