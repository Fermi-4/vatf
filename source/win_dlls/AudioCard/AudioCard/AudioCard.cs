using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.ComponentModel;
using System.Text;
using System.Collections;
using System.Threading;
using TeHandlers;

namespace TeHandlers
{
    /// <summary>
    /// This class is used to control audio card operations in a system.
    /// </summary>
    public class AudioCard : IDisposable
    {
        private ArrayList waveInAudioDevices; /* Collection of waveAudio inputs */
        private ArrayList waveOutAudioDevices; /* Collection of waveAudio outputs */
        private Hashtable inputDevices;
        private Hashtable outputDevices;
        private AudioCardLogger audioCardLogger;
        /// <summary>
        /// Constructor of the class. Used to gather audio IO information
        /// </summary>
        /// <param name="equipmentInfo">A Hashtable containing the system's audio IO information</param>
        public AudioCard(Hashtable equipmentInfo, string logPath) 
        {
            try
            {
                this.InitializeTables();
                this.StartLogger(logPath);
                if (equipmentInfo.ContainsKey("analog_inputs")) this.inputDevices["analog"] = ((string)equipmentInfo["analog_inputs"]).Split(new char[] { ',' });
                if (equipmentInfo.ContainsKey("digital_inputs")) this.inputDevices["digital"] = ((string)equipmentInfo["digital_inputs"]).Split(new char[] { ',' });
                if (equipmentInfo.ContainsKey("midi_inputs")) this.inputDevices["midi"] = ((string)equipmentInfo["midi_inputs"]).Split(new char[] { ',' });
                if (equipmentInfo.ContainsKey("analog_outputs")) this.outputDevices["analog"] = ((string)equipmentInfo["analog_outputs"]).Split(new char[] { ',' });
                if (equipmentInfo.ContainsKey("digital_outputs")) this.outputDevices["digital"] = ((string)equipmentInfo["digital_outputs"]).Split(new char[] { ',' });
                if (equipmentInfo.ContainsKey("midi_outputs")) this.outputDevices["midi"] = ((string)equipmentInfo["midi_outputs"]).Split(new char[] { ',' });
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// Constructor of the class.
        /// </summary>
        public AudioCard()
        {
            this.InitializeTables();
        }

        /// <summary>
        /// Constructor of the class
        /// </summary>
        /// <param name="logPath">path of the file containing the log</param>
        public AudioCard(string logPath)
        {
            this.InitializeTables();
            this.StartLogger(logPath);
        }

        private void InitializeTables()
        {
            this.waveInAudioDevices = new ArrayList(); /* Collection of waveAudio inputs */
            this.waveOutAudioDevices = new ArrayList(); /* Collection of waveAudio outputs */
            this.inputDevices = new Hashtable();
            this.outputDevices = new Hashtable();
        }

        ~AudioCard()
        {
        }

        public void Dispose()
        {
            this.waveInAudioDevices = null;
            this.waveOutAudioDevices = null;
            this.inputDevices = null;
            this.outputDevices = null;
        }

        /// <summary>
        /// This function allows the user to open a wave audio input for recording with a specific configuration.
        /// </summary>
        /// <param name="audioParams">a hashtable containing the wave audio input configuration. The hashtable required values are:
        /// "device_type": type of input used for recording, allowed values are "analog", "digital" or "midi".
        /// "device_id": represents the number associated with the type that will be used for recording if device_type is present, or the id associated with the input used for recording in which case has to be a value between 0 and whatever is returned by GetWaveInDevices - 1
        /// "ext_param_size": size of the audio inputs extended parameters, currently only 0 is supported
        /// "avg_bytes_per_sec": average audio recording rate in bytes per seconds
        /// "channels": number of channels in the recorded signal 1 for mono, 2 for stereo);
        /// "samples_per_sec": sampling rate
        /// "bits_per_sample": number of bits per audio sample;
        /// "format_tag": recorded audio format, currently only 1 (for linear format) is supported 
        /// </param>
        /// <returns>a handle (int) to the open device, -1 otherwise.</returns>
        public int OpenWaveInAudioDevice(Hashtable audioParams)
        {
            Hashtable localParams = (Hashtable)audioParams.Clone();
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name+" Operation:");
                WaveAudio audioDevice = new WaveAudio();
                if (localParams.ContainsKey("device_type"))
                {
                    localParams["device_id"] = int.Parse(((string[])this.inputDevices[(string)localParams["device_type"]])[(int)localParams["device_id"]]);
                }
                foreach (DictionaryEntry ioParam in localParams)
                {
                    LogInfo(ioParam.Key.ToString() + " = " + ioParam.Value.ToString());
                }
                audioDevice.OpenWaveInDevice(localParams);
                waveInAudioDevices.Add(audioDevice);
                LogInfo("input handle: " + (waveInAudioDevices.Count - 1).ToString());
                return waveInAudioDevices.Count - 1;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }
        
        /// <summary>
        /// This functions is used to record audio
        /// </summary>
        /// <param name="devHandle">handle to the input that will be used for recording</param>
        /// <param name="audioFile">path of a file were the recorded audio will be stored</param>
        public void RecordWaveAudio(int devHandle, string audioFile)
        {
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name+" Operation with input handle " + devHandle.ToString() + " and file " + audioFile);
                Hashtable audioParams = new Hashtable();
                audioParams["audio_file"] = audioFile;
                ((WaveAudio)this.waveInAudioDevices[devHandle]).RecordWaveAudio(audioParams);
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// This functions is used to play audio
        /// </summary>
        /// <param name="devHandle">handle to the output used for playout</param>
        /// <param name="audioFile">files containing the audio to be played out</param>
        public void PlayWaveAudio(int devHandle, string audioFile)
        {
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name + " Operation with output handle " + devHandle.ToString() + " and file " + audioFile);
                Hashtable audioParams = new Hashtable();
                audioParams["audio_file"] = audioFile;
                ((WaveAudio)this.waveOutAudioDevices[devHandle]).PlayWaveAudio(audioParams);
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// This function is used to stop audio playout
        /// </summary>
        /// <param name="devHandle">handle of the output used to playout audio</param>
        public void StopWaveAudioPlay(int devHandle)
        {
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name + " Operation with output handle " + devHandle.ToString());
                ((WaveAudio)this.waveOutAudioDevices[devHandle]).StopWaveAudioPlay();
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// This function is used to stop recording audio.
        /// </summary>
        /// <param name="devHandle">handle to the input used for recording</param>
        /// <returns>the number of bytes recorded</returns>
        public uint StopWaveAudioRecord(int devHandle)
        {
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name + " Operation with input handle " + devHandle.ToString());
                return ((WaveAudio)this.waveInAudioDevices[devHandle]).StopWaveAudioRecord();
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// This function allows the user to query if a record operation is still running.
        /// </summary>
        /// <param name="devHandle">handle to the input used for recording</param>
        /// <returns>true if the record operation has finished; false if the record operation is still running</returns>
        public bool WaveAudioRecordDone(int devHandle)
        {
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name + " Operation with input handle " + devHandle.ToString());
                return ((WaveAudio)this.waveInAudioDevices[devHandle]).WaveIODone();
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// This function allows the user to query if a device is still playing a file.
        /// </summary>
        /// <param name="devHandle">handle of the output used to playout audio</param>
        /// <returns>true if the device has finished playing the file; false if the device is still playing the file</returns>
        public bool WaveAudioPlayDone(int devHandle)
        {
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name + " Operation with input handle " + devHandle.ToString());
                return ((WaveAudio)this.waveOutAudioDevices[devHandle]).WaveIODone();
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// This function is used to open an audio output.
        /// </summary>
        /// <param name="audioParams">
        /// Hashtable containing the audio output's playout mode. The hashtable required entries are:
        /// "device_type": type of input used for recording, allowed values are "analog", "digital" or "midi". 
        /// "device_id": represents the number associated with the type that will be used for playout if device_type is present, or the id associated with the input used for recording in which case has to be a value between 0 and whatever is returned by GetWaveInDevices - 1
        /// "ext_param_size": size of the audio outputs extended parameters, currently only 0 is supported
        /// "avg_bytes_per_sec": average audio recording rate in bytes per seconds
        /// "channels": number of channels in the recorded signal 1 for mono, 2 for stereo);
        /// "samples_per_sec": sampling rate
        /// "bits_per_sample": number of bits per audio sample;
        /// "format_tag": recorded audio format, currently only 1 (for linear format) is supported </param>
        /// <returns>a handle that can be used to control the audio output</returns>
        public int OpenWaveOutAudioDevice(Hashtable audioParams)
        {
            Hashtable localParams = (Hashtable)audioParams.Clone();
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name + " Operation:");
                WaveAudio audioDevice = new WaveAudio();
                if (localParams.ContainsKey("device_type"))
                {
                    localParams["device_id"] = int.Parse(((string[])this.outputDevices[(string)localParams["device_type"]])[(int)localParams["device_id"]]);
                }
                foreach (DictionaryEntry ioParam in localParams)
                {
                    LogInfo(ioParam.Key.ToString() + " = " + ioParam.Value.ToString());
                }
                audioDevice.OpenWaveOutDevice(localParams);
                waveOutAudioDevices.Add(audioDevice);
                LogInfo("output handle: "+(waveOutAudioDevices.Count - 1).ToString()); 
                return waveOutAudioDevices.Count - 1;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// This function is used to release control of an audio input.
        /// </summary>
        /// <param name="devHandle">handle of the input acquire with OpenWaveInAudioDevice </param>
        public void CloseWaveInDevice(int devHandle)
        {
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name + " operation with input handle "+devHandle.ToString());
                WaveAudio audioDevice = (WaveAudio)this.waveInAudioDevices[devHandle];
                audioDevice.CloseWaveInDevice();
                this.waveInAudioDevices[devHandle] = null;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// This function is used to release control of an audio output.
        /// </summary>
        /// <param name="devHandle">handle of the output acquire with OpenWaveOutAudioDevice </param>
        public void CloseWaveOutDevice(int devHandle)
        {
            try
            {
                LogInfo(System.Reflection.MethodInfo.GetCurrentMethod().Name + " operation with output handle " + devHandle.ToString());
                WaveAudio audioDevice = (WaveAudio)this.waveOutAudioDevices[devHandle];
                audioDevice.CloseWaveOutDevice();
                this.waveOutAudioDevices[devHandle] = null;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        /// <summary>
        /// This function returns the capabilities of the audio input specified
        /// </summary>
        /// <param name="deviceID">id associated with the input, has to be a value between 0 and whatever is returned by GetWaveOutDevices - 1</param>
        /// <returns>A Hashtable containing the output's capabilities. The hashtable keys are:
        /// "manufacturer_id", "product_id", "driver_version", "formats", and "name". MMSystem.h is required to understand the values.
        /// </returns>
        public Hashtable GetWaveInDeviceCapabilities(uint deviceID)
        {
            return (new WaveAudio().GetWaveInDevCapabilities(deviceID));
        }

        /// <summary>
        /// This function returns the capabilities of the audio output specified
        /// </summary>
        /// <param name="deviceID">id associated with the output , has to be a value between 0 and whatever is returned by GetWaveOutDevices - 1</param>
        /// <returns>A Hashtable containing the output's capabilities. The hashtable keys are:
        /// "manufacturer_id", "product_id", "driver_version", "formats", and "name". MMSystem.h is required to understand the values.
        /// </returns>
        public Hashtable GetWaveOutDeviceCapabilities(uint deviceID)
        {
            return (new WaveAudio().GetWaveOutDevCapabilities(deviceID));
        }

        /// <summary>
        /// This function returns the number of audio inputs available in the system
        /// </summary>
        /// <returns>the number of audio inputs available in the system</returns>
        public uint GetWaveInDevices()
        {
            return (new WaveAudio().GetWaveInDevices());
        }

        /// <summary>
        /// This function returns the number of audio outputs available in the system
        /// </summary>
        /// <returns>the number of audio outputs available in the system</returns>
        public uint GetWaveOutDevices()
        {
            return (new WaveAudio().GetWaveOutDevices());
        }

        /// <summary>
        /// This function is used to start the event logger
        /// </summary>
        /// <param name="logPath">path of the file were the logged events are stored</param>
        public void StartLogger(string logPath)
        {
            this.audioCardLogger = new AudioCardLogger(this.ToString(), logPath);
        }

        /* 
         This function is used to stop the event logger
         */
        public void StopLogger()
        {
            if (this.audioCardLogger != null) this.audioCardLogger.CloseLogger();
        }

        /** 
         * This function is used to log information events.
         * info: string containing the information to be logged
         */
        private void LogInfo(string info)
        {
            if (this.audioCardLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(audioCardLogger.LogInfo));
                logThread.Start(info);
            }
        }

        /*
         * This function is used to log error event
         * error: string containing error information to be logged
         */
        private void LogError(string error)
        {
            if (this.audioCardLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(audioCardLogger.LogError));
                logThread.Start(error);
            }
        }

        /*
         * This function is used to log warning events
         * warning: string containing warning information to be logged
         */
        private void LogWarning(string warning)
        {
            if (this.audioCardLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(audioCardLogger.LogWarning));
                logThread.Start(warning);
            }
        }
    }
}
