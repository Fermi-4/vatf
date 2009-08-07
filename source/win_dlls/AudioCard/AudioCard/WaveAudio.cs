using System;
using System.Collections.Generic;
using System.Collections;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.IO;

namespace TeHandlers
{
    /// <summary>
    /// This class allows the user to control an Audio card (play, record, etc.). For simultaneous play and record the user 
    /// must instantiate two objects of this class, one for playout and one for recording.
    /// </summary>
    class WaveAudio
    {
        #region Class Variables
        private UInt32 waveHandle;         /* handle of an audio IO device */
        private string waveFile;           /* path of the file were the pcm data will be recorded */
        private ArrayList audioDataStream = new ArrayList();  /* Collection containing all the data recorded */
        private Thread waveThread; /* thread used to send audio data blocks to the audio devices */
        #endregion

        #region Class Constants 
        private const int AUDIO_DATA_LENGTH = 80000;  /* length of an audio data block in bytes */
        private const int AUDIO_BUFFER_LENGTH = 5;    /* length of the buffer containing audio data blocks */
        private const int NAME_LENGTH = 32;           /* length of name strings */
        private const uint MM_WIM_OPEN = 0x3BE;          /* waveform input */
        private const uint MM_WIM_CLOSE = 0x3BF;
        private const uint MM_WIM_DATA = 0x3C0;
        private const uint MM_WOM_OPEN = 0x3BB;           /* waveform output */
        private const uint MM_WOM_CLOSE = 0x3BC;
        private const uint MM_WOM_DONE = 0x3BD;
        private const uint MM_NO_ERROR = 0;
        private const int ERROR_BUFFER_LENGTH = 256;   /* length of the string used to display error message */
        private const uint WHDR_DONE = 0x00000001;  /* done bit */
        private const uint WHDR_PREPARED = 0x00000002;  /* set if this header has been prepared */
        private const uint WHDR_BEGINLOOP = 0x00000004;  /* loop start block */
        private const uint WHDR_ENDLOOP = 0x00000008;  /* loop end block */
        private const uint WHDR_INQUEUE = 0x00000010;
         
        private const uint WAVE_MAPPED = 0x0004;             /* audio IO operation modes */
        private const uint CALLBACK_FUNCTION = 0x00030000;
        private const uint CALLBACK_NULL = 0x00000000;
        /* types for wType field in MMTIME struct */
        private const UInt16 TIME_MS    =     0x0001;  /* time in milliseconds */
        private const UInt16 TIME_SAMPLES =   0x0002;  /* number of wave samples */
        private const UInt16 TIME_BYTES   =   0x0004;  /* current byte offset */
        private const UInt16 TIME_SMPTE   =   0x0008;  /* SMPTE time */
        private const UInt16 TIME_MIDI    =   0x0010;  /* MIDI time */
        private const UInt16 TIME_TICKS = 0x0020;  /* Ticks within MIDI stream */

        #endregion

        #region Windows Multimedia Library Functions
        /*This section contains all the function imported from the window multimedia library. For more information on these functions
         go to http://msdn2.microsoft.com/en-us/library/ms713771.aspx
         **/

        #region Wave In Functions
        /// <summary>
        /// This function return the number of audio inputs that can be used for recording
        /// </summary>
        /// <returns>The number of audio inputs present in the system</returns>
        [DllImport("winmm.dll")]
        private static extern uint waveInGetNumDevs();

        /// <summary>
        /// This functions returns the audio input error message associated with a given audio input error number.
        /// </summary>
        /// <param name="mmrError">The error number returned by an audio input function</param>
        /// <param name="pszText">pointer to the string that will contain the error message</param>
        /// <param name="cchText">length of the string that will contain the error message</param>
        /// <returns></returns>
        [DllImport("winmm.dll")]
        private static extern uint waveInGetErrorText(uint mmrError, IntPtr pszText, uint cchText); 

        /// <summary>
        /// This function is used for openning an audio input to operate in a specific recording mode. 
        /// </summary>
        /// <param name="phwi">pointer to handle of the audio input</param>
        /// <param name="uDeviceID">id associated with the audio input to be controlled, has to be a value between 0 and 
        /// whatever is returned by waveInGetNumDevs() - 1</param>
        /// <param name="pwfx">pointer to a data structured containing the recording mode</param>
        /// <param name="dwCallback">pointer to the callback function used to process the messages returned by the audio device</param>
        /// <param name="dwInstance">user data</param>
        /// <param name="fdwOpen">bitmask specifying the operational mode of the audio device</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInOpen(ref UInt32 phwi, uint uDeviceID, WaveFormatEx pwfx, IntPtr dwCallback, IntPtr dwInstance, UInt32 fdwOpen);

        /// <summary>
        /// This function closes the audio input.
        /// </summary>
        /// <param name="phwi">the handled obtained with waveInOpen function</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInClose(UInt32 phwi);

        /// <summary>
        /// This functions is used to obtain the capabalities of an audio input
        /// </summary>
        /// <param name="phwi">ID associated with the audio input, has to be a value between 0 and 
        /// whatever is returned by waveInGetNumDevs() - 1</param>
        /// <param name="pwic"> pointer to a WaveInCaps struct were the device capabilities are stored. Requires looking at MMSystem.h
        /// to process the data structure</param>
        /// <param name="cbwic">length in bytes of pwic</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInGetDevCaps(UInt32 phwi, WaveInCaps pwic, UInt32 cbwic);

        /// <summary>
        /// This functions is used to send data blocks to the audio device. These data blocks are used by the device to store the recorded data.
        /// </summary>
        /// <param name="hwi">the handled obtained with waveInOpen function</param>
        /// <param name="pwh">pointer to a WaveHdr struct were the data blocks are contained</param>
        /// <param name="cbwh">size of the WaveHdr struct</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInAddBuffer(UInt32 hwi, WaveHdr pwh, UInt32 cbwh);

        /// <summary>
        /// This function is used to stop the audio recording process.
        /// </summary>
        /// <param name="hwi">the handled obtained with waveInOpen function </param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInReset(UInt32 hwi);

        /// <summary>
        /// This function is used to tell the audio device to start recording
        /// </summary>
        /// <param name="hwi">the handled obtained with waveInOpen function</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInStart(UInt32 hwi);

        /// <summary>
        /// This function is used to paused the recording process
        /// </summary>
        /// <param name="hwi">the handled obtained with waveInOpen function</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInStop(UInt32 hwi);

        /// <summary>
        /// This function is used to prepare and audio data block, so that in can be used for recording
        /// </summary>
        /// <param name="hwi">the handled obtained with waveInOpen function</param>
        /// <param name="pwh">pointer to a WaveHdr struct were the data blocks are contained</param>
        /// <param name="cbwh">size of the WaveHdr struct</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInPrepareHeader(UInt32 hwi, WaveHdr pwh, UInt32 cbwh);

        /// <summary>
        /// This function is used to signal the device to unlock an audio data block.
        /// </summary>
        /// <param name="hwi">the handled obtained with waveInOpen function</param>
        /// <param name="pwh">pointer to the WaveHdr struct that will be unlocked</param>
        /// <param name="cbwh">size of the WaveHdr struct</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInUnprepareHeader(UInt32 hwi, WaveHdr pwh, UInt32 cbwh);


        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveInGetPosition(UInt32 hwi, MMTime lpmmt, UInt32 cbmmt);
  
        #endregion

        #region Wave Out Functions
        /// <summary>
        /// This function returns the number of audio outputs that can be used for playout
        /// </summary>
        /// <returns>The number of audio outputs present in the system</returns>
        [DllImport("winmm.dll")]
        private static extern uint waveOutGetNumDevs();

        /// <summary>
        /// This function is used for openning an audio output to operate in a specific playout mode. 
        /// </summary>
        /// <param name="phwi">pointer to handle of the audio output</param>
        /// <param name="uDeviceID">id associated with the audio output to be controlled, has to be a value between 0 and 
        /// whatever is returned by waveOutGetNumDevs() - 1</param>
        /// <param name="pwfx">pointer to a data structured containing the playout mode</param>
        /// <param name="dwCallback">pointer to the callback function used to process the messages returned by the audio device</param>
        /// <param name="dwInstance">user data</param>
        /// <param name="fdwOpen">bitmask specifying the operational mode of the audio device</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutOpen(ref UInt32 phwo, uint uDeviceID, WaveFormatEx pwfx, IntPtr dwCallback, IntPtr dwInstance, UInt32 fdwOpen);

        /// <summary>
        /// This function closes the audio output.
        /// </summary>
        /// <param name="phwi">the handled obtained with waveOutOpen function</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutClose(UInt32 hwo);

        /// <summary>
        /// This functions is used to obtain the capabalities of an audio output
        /// </summary>
        /// <param name="phwi">ID associated with the audio output, has to be a value between 0 and 
        /// whatever is returned by waveOutGetNumDevs() - 1</param>
        /// <param name="pwic"> pointer to a WaveOutCaps struct were the device capabilities are stored. Requires looking at MMSystem.h
        /// to process the data structure</param>
        /// <param name="cbwic">length in bytes of pwic</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutGetDevCaps(UInt32 hwo, WaveOutCaps pwoc, UInt32 cbwoc);

        /// <summary>
        /// This functions returns the audio output error message associated with a given audio output error number.
        /// </summary>
        /// <param name="mmrError">The error number returned by an audio output function</param>
        /// <param name="pszText">pointer to the string that will contain the error message</param>
        /// <param name="cchText">length of the string that will contain the error message</param>
        /// <returns></returns>
        [DllImport("winmm.dll")]
        private static extern uint waveOutGetErrorText(uint mmrError, IntPtr pszText, uint cchText);

        /// <summary>
        /// This function returns the pitch multiplier number setting
        /// </summary>
        /// <param name="hwo">the handled obtained with waveOutOpen function</param>
        /// <param name="pdwPitch">pointer to uint were the pitch setting will be stored, 0xFFFF is the max</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutGetPitch(UInt32 hwo, ref UInt32 pdwPitch);

        /// <summary>
        /// This function returns the playback rate setting
        /// </summary>
        /// <param name="hwo">the handled obtained with waveOutOpen function</param>
        /// <param name="pdwPitch">pointer to uint were the playback rate setting will be stored, 0xFFFF is the max</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutGetPlaybackRate(UInt32 hwo, ref UInt32 pdwRate);

        /// <summary>
        /// This function returns the volume setting
        /// </summary>
        /// <param name="hwo">the handled obtained with waveOutOpen function</param>
        /// <param name="pdwPitch">pointer to uint were the volume setting will be stored, 0xFFFF is the max</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutGetVolume(UInt32 hwo, ref UInt32 pdwVolume);

        /// <summary>
        /// This function is used to paused the audio playout
        /// </summary>
        /// <param name="hwo">the handled obtained with waveOutOpen function</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutPause(UInt32 hwo);

        /// <summary>
        /// This function is used to prepare an audio data block, so that in can be used for playout
        /// </summary>
        /// <param name="hwi">the handled obtained with waveOutOpen function</param>
        /// <param name="pwh">pointer to a WaveHdr struct were the data blocks are contained</param>
        /// <param name="cbwh">size of the WaveHdr struct</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutPrepareHeader(UInt32 hwo, WaveHdr pwh, UInt32 cbwh);

        /// <summary>
        /// This function is used to stop the audio playout process.
        /// </summary>
        /// <param name="hwi">the handled obtained with waveOutOpen function </param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutReset(UInt32 hwo);

        /// <summary>
        /// This function is used to resume a playout process that has been paused.
        /// </summary>
        /// <param name="hwo">the handled obtained with waveOutOpen function</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutRestart(UInt32 hwo);

        /// <summary>
        /// This function is used to set the pitch for a given audio output
        /// </summary>
        /// <param name="hwo">the handled obtained with waveOutOpen function</param>
        /// <param name="dwPitch">pitch setting value, between 0 and 0xFFFF</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutSetPitch(UInt32 hwo, UInt32 dwPitch);

        /// <summary>
        /// This function is used to set the playback rate for a given audio output
        /// </summary>
        /// <param name="hwo">the handled obtained with waveOutOpen function</param>
        /// <param name="dwPitch">playback rate setting, value between 0 and 0xFFFF</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutSetPlaybackRate(UInt32 hwo, UInt32 dwRate);

        /// <summary>
        /// This function is used to set the volume for a given audio output
        /// </summary>
        /// <param name="hwo">the handled obtained with waveOutOpen function</param>
        /// <param name="dwPitch">volume setting, value between 0 and 0xFFFF</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutSetVolume(UInt32 hwo, UInt32 dwVolume);

        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutUnprepareHeader(UInt32 hwo, WaveHdr pwh, UInt32 cbwh);

        /// <summary>
        /// This function is used to signal the device to unlock an audio data block.
        /// </summary>
        /// <param name="hwi">the handled obtained with waveOutOpen function</param>
        /// <param name="pwh">pointer to the WaveHdr struct that will be unlocked</param>
        /// <param name="cbwh">size of the WaveHdr struct</param>
        /// <returns>0 if no error, an error number otherwise</returns>
        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutWrite(UInt32 hwo, WaveHdr pwh, UInt32 cbwh);

        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint waveOutGetPosition(UInt32 hwo, MMTime lpmmt, UInt32 cbmmt);
        #endregion
        #endregion

        #region Windows Multimedia Data Structures

        /// <summary>
        /// This structure is used to set an IO to particular playout/recording mode
        /// </summary>
        [StructLayout(LayoutKind.Explicit, Size = 18, CharSet = CharSet.Auto)]
        private class WaveFormatEx
        {
            [FieldOffset(0)]
            public UInt16 wFormatTag;
            [FieldOffset(2)]
            public UInt16 nChannels;
            [FieldOffset(4)]
            public UInt32 nSamplesPerSec;
            [FieldOffset(8)]
            public UInt32 nAvgBytesPerSec;
            [FieldOffset(12)]
            public UInt16 nBlockAlign;
            [FieldOffset(14)]
            public UInt16 wBitsPerSample;
            [FieldOffset(16)]
            public UInt16 cbSize;

        }

        [StructLayout(LayoutKind.Explicit, Size = 8, CharSet = CharSet.Auto)]
        private class AudioGainClass
        {
            [FieldOffset(0)]
            public UInt16 dwPriority;
            [FieldOffset(4)]
            public UInt16 dwRelativeGain;
        }

        [StructLayout(LayoutKind.Explicit, Size = 8, CharSet = CharSet.Auto)]
        private class StreamProps
        {
            [FieldOffset(0)]
            public UInt16 dwClassId;
            [FieldOffset(4)]
            public UInt16 dwFlags;
        }

        /// <summary>
        /// Data structure used to manipulate audio data blocks
        /// </summary>
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
        private class WaveHdr : IDisposable
        {

            public IntPtr lpData;
            public UInt32 bufferLength;
            public UInt32 dwBytesRecorded;
            public UInt32 dwUser;
            public UInt32 dwFlags;
            public UInt32 dwLoops;
            public IntPtr lpNext;
            public UInt32 reserved;

            public WaveHdr(uint dataSize)
            {
                lpData = Marshal.AllocHGlobal((int)dataSize);
                bufferLength = dataSize;
                dwBytesRecorded = 0;
                dwFlags = 0;
            }

            public void Dispose()
            {
                Marshal.FreeHGlobal(lpData);
            }
            
        }

        /// <summary>
        /// Structure used to obtained an audio input's capabilities
        /// </summary>
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        private class WaveInCaps
        {
            public UInt16 wMid;
            public UInt16 wPid;
            public UInt16 vDriverVersion;
            public IntPtr szPname;
            public UInt32 dwFormats;
            public UInt16 wChannels;
            public UInt16 wReserved1;
        }

        /// <summary>
        /// Structure used to obtained an audio output's capabilities
        /// </summary>
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        private class WaveOutCaps
        {
            public UInt16 wMid;
            public UInt16 wPid;
            public UInt16 vDriverVersion;
            public IntPtr szPname;
            public UInt32 dwFormats;
            public UInt16 wChannels;
            public UInt16 wReserved1;
            public UInt32 dwSupport;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        private class WaveFormatMidi
        {
            public WaveFormatEx wfx;
            public UInt32 USecPerQuarterNote;
            public UInt32 TicksPerQuarterNote;
        }

        [StructLayout(LayoutKind.Explicit, Size = 8, CharSet = CharSet.Auto)]
        private class WaveFormatMidiMessage
        {
            [FieldOffset(0)]
            UInt32 DeltaTicks;
            [FieldOffset(4)]
            UInt32 MidiMsg;
        }

        [StructLayout(LayoutKind.Explicit, Size = 8, CharSet = CharSet.Auto)]
        private class MMTime { 
            [FieldOffset(0)]
            public UInt32 wType; 
            [FieldOffset(4)]
            public UInt32 ms; 
            [FieldOffset(4)]
            public UInt32 sample;
            [FieldOffset(4)]
            public UInt32 cb;
            [FieldOffset(4)]
            public UInt32 ticks;
            [FieldOffset(4)]
            public Smpte smpte;
            [FieldOffset(4)]
            public SongPtrPos midi; 
        }

        [StructLayout(LayoutKind.Explicit, Size = 8, CharSet = CharSet.Auto)]
        private class Smpte {
            [FieldOffset(0)]
            public Byte hour; 
            [FieldOffset(1)]
            public Byte min;
            [FieldOffset(2)]
            public Byte sec;
            [FieldOffset(3)]
            public Byte frame;
            [FieldOffset(4)]
            public Byte fps;
            [FieldOffset(5)]
            public Byte dummy;
            [FieldOffset(6)]
            public IntPtr pad; 
        }

        [StructLayout(LayoutKind.Explicit, Size = 4, CharSet = CharSet.Auto)]
        private class SongPtrPos
        {
            [FieldOffset(0)]
            public UInt32 songptrpos;  
        }

        #endregion

        #region Public Class Functions
        
        /// <summary>
        /// Constructor of the class.
        /// </summary>
        public WaveAudio()
        {
        }

        /// <summary>
        /// This function allows the user to close an audio Input
        /// </summary>
        public void CloseWaveInDevice()
        {
            CheckMMInResult(waveInClose(this.waveHandle));
        }

        /// <summary>
        /// This function alllos the user to obtain control of an audio input.
        /// </summary>
        /// <param name="audioParams">Hashtable containing the audio input's recording mode. The hashtable required entries are:
        /// "device_id": id associated with the output that will be used for playout, has to be a value between 0 and whatever is returned by GetWaveInDevices - 1
        /// "ext_param_size": size of the audio inputs extended parameters, currently only 0 is supported
        /// "avg_bytes_per_sec": average audio recording rate in bytes per seconds
         ///"channels": number of channels in the recorded signal 1 for mono, 2 for stereo);
         /// "samples_per_sec": sampling rate
         /// "bits_per_sample": number of bits per audio sample;
         /// "format_tag": recorded audio format, currently only 1 (for linear format) is supported 
        /// </param>
        public void OpenWaveInDevice(Hashtable audioParams)
        {
            WaveFormatEx waveFormat = new WaveFormatEx();
            waveFormat.cbSize = (UInt16)((int)audioParams["ext_param_size"]);
            waveFormat.nAvgBytesPerSec = (UInt32)((int)audioParams["avg_bytes_per_sec"]);
            waveFormat.nBlockAlign = (UInt16)((int)audioParams["channels"] * (int)audioParams["bits_per_sample"] / 8);
            waveFormat.nChannels = (UInt16)((int)audioParams["channels"]);
            waveFormat.nSamplesPerSec = (UInt32)((int)audioParams["samples_per_sec"]);
            waveFormat.wBitsPerSample = (UInt16)((int)audioParams["bits_per_sample"]);
            waveFormat.wFormatTag = (UInt16)((int)audioParams["format_tag"]);
            CheckMMInResult(waveInOpen(ref this.waveHandle, (uint)((int)audioParams["device_id"]), waveFormat, IntPtr.Zero, IntPtr.Zero, CALLBACK_NULL));
        }

        /// <summary>
        /// This function alllows the user to obtain control of an audio output.
        /// </summary>
        /// <param name="audioParams">Hashtable containing the audio output's playout mode. The hashtable required entries are:
        /// "device_id": id associated with the output that will be used for playout, has to be a value between 0 and whatever is returned by GetWaveOutDevices - 1
        /// "ext_param_size": size of the audio outputs extended parameters, currently only 0 is supported
        /// "avg_bytes_per_sec": average audio recording rate in bytes per seconds
        ///"channels": number of channels in the recorded signal 1 for mono, 2 for stereo);
        /// "samples_per_sec": sampling rate
        /// "bits_per_sample": number of bits per audio sample;
        /// "format_tag": recorded audio format, currently only 1 (for linear format) is supported 
        /// </param>
        public void OpenWaveOutDevice(Hashtable audioParams)
        {
            WaveFormatEx waveFormat = new WaveFormatEx();
            waveFormat.cbSize = (UInt16)((int)audioParams["ext_param_size"]);
            waveFormat.nAvgBytesPerSec = (UInt32)((int)audioParams["avg_bytes_per_sec"]);
            waveFormat.nBlockAlign = (UInt16)((int)audioParams["channels"] * (int)audioParams["bits_per_sample"] / 8);
            waveFormat.nChannels = (UInt16)((int)audioParams["channels"]);
            waveFormat.nSamplesPerSec = (UInt32)((int)audioParams["samples_per_sec"]);
            waveFormat.wBitsPerSample = (UInt16)((int)audioParams["bits_per_sample"]);
            waveFormat.wFormatTag = (UInt16)((int)audioParams["format_tag"]);
            CheckMMOutResult(waveOutOpen(ref this.waveHandle, (uint)((int)audioParams["device_id"]), waveFormat, IntPtr.Zero, IntPtr.Zero, CALLBACK_NULL));
        }

        /// <summary>
        /// This function closes the audio output opened with OpenWave output
        /// </summary>
        public void CloseWaveOutDevice()
        {
            CheckMMOutResult(waveOutClose(this.waveHandle));
        }

        /// <summary>
        /// This function returns the number of audio outputs available in the system
        /// </summary>
        /// <returns>the number of audio outputs available in the system</returns>
        public uint GetWaveOutDevices()
        {
            return waveOutGetNumDevs();
        }

        /// <summary>
        /// This function returns the number of audio inputs available in the system
        /// </summary>
        /// <returns>the number of audio inputs available in the system</returns>
        public uint GetWaveInDevices()
        {
            return waveInGetNumDevs();
        }

        /// <summary>
        /// This function returns the capabilities of the audio input specified
        /// </summary>
        /// <param name="deviceID">id associated with the input, has to be a value between 0 and whatever is returned by GetWaveOutDevices - 1</param>
        /// <returns>A Hashtable containing the output's capabilities. The hashtable keys are:
        /// "manufacturer_id", "product_id", "driver_version", "formats", and "name". MMSystem.h is required to understand the values.
        /// </returns>
        public Hashtable GetWaveInDevCapabilities(uint deviceID)
        {
            WaveInCaps devCaps = new WaveInCaps();
            devCaps.szPname = Marshal.AllocHGlobal(NAME_LENGTH);
            Hashtable caps = new Hashtable();
            CheckMMInResult(waveInGetDevCaps(deviceID, devCaps,(uint) Marshal.SizeOf(devCaps)));
            caps["manufacturer_id"] = devCaps.wMid;
            caps["product_id"] = devCaps.wPid;
            caps["driver_version"] = devCaps.vDriverVersion;
            caps["formats"] = devCaps.dwFormats;
            caps["name"] = Marshal.PtrToStringAuto(devCaps.szPname);

            return caps;
        }

        /// <summary>
        /// This function returns the capabilities of the audio output specified
        /// </summary>
        /// <param name="deviceID">id associated with the output , has to be a value between 0 and whatever is returned by GetWaveOutDevices - 1</param>
        /// <returns>A Hashtable containing the output's capabilities. The hashtable keys are:
        /// "manufacturer_id", "product_id", "driver_version", "formats", and "name". MMSystem.h is required to understand the values.
        /// </returns>
        public Hashtable GetWaveOutDevCapabilities(uint deviceID)
        {
            WaveOutCaps devCaps = new WaveOutCaps();
            devCaps.szPname = Marshal.AllocHGlobal(NAME_LENGTH);
            Hashtable caps = new Hashtable();
            CheckMMOutResult(waveOutGetDevCaps(deviceID, devCaps, (uint)Marshal.SizeOf(devCaps)));
            caps["manufacturer_id"] = devCaps.wMid;
            caps["product_id"] = devCaps.wPid;
            caps["driver_version"] = devCaps.vDriverVersion;
            caps["formats"] = devCaps.dwFormats;
            caps["name"] = Marshal.PtrToStringAuto(devCaps.szPname);
            caps["support"] = devCaps.dwSupport;
            return caps;
        }

        /// <summary>
        /// This function is used to start recording audio
        /// </summary>
        /// <param name="audioData">Hashtable containing the playout parameter. The keys are:
        /// "audio_file": file path containing the audio data that will be played out</param>
        public void RecordWaveAudio(Hashtable audioData)
        {
            this.waveFile = (string)audioData["audio_file"];
            waveThread = new Thread(new ThreadStart(GetWaveInHdrs));
            waveThread.Start();
            CheckMMInResult(waveInStart(this.waveHandle));
        }

        /// <summary>
        /// This function is used to end the recording process.
        /// </summary>
        /// <returns>the number of audio data bytes recorded</returns>
        public uint StopWaveAudioRecord()
        {
            uint bytesRecorded = 0;
            waveThread.Abort();
            waveThread.Join();
            FileStream audioFile = File.Open(this.waveFile, FileMode.Create);
            foreach (byte[] audioData in this.audioDataStream)
            {
                bytesRecorded += (uint)audioData.Length;
                audioFile.Write(audioData, 0, audioData.Length);
            }
            audioFile.Close();
            this.audioDataStream.Clear();
            return bytesRecorded;
        }

        /// <summary>
        /// This function is used to playout an audio file
        /// </summary>
        /// <param name="audioParams">Hashtable containing the playout parameter. The keys are:
        /// "audio_file": file path containing the audio data that will be played out</param>
        public void PlayWaveAudio(Hashtable audioParams)
        {
            waveThread = new Thread(new ParameterizedThreadStart(GetWaveOutHdrs));
            waveThread.Start(audioParams);
        }

        /// <summary>
        /// This function is used to pause the audio playout process 
        /// </summary>
        public void PauseWaveAudioPlay()
        {
            CheckMMOutResult(waveOutPause(this.waveHandle));
        }

        /// <summary>
        /// This function is used to resume an audio playout that has been paused 
        /// </summary>
        public void ResumeWaveAudioPlay()
        {
            CheckMMOutResult(waveOutRestart(this.waveHandle));
        }

        /// <summary>
        /// This functions is used to end the audio playout process
        /// </summary>
        public void StopWaveAudioPlay()
        {
            waveThread.Abort();
            waveThread.Join();
        }

        /// <summary>
        /// This function allows the user to query the status of a wave IO operation
        /// </summary>
        /// <returns>true is the IO operation has completed;otherwise it returns false</returns>
        public bool WaveIODone()
        {
            if (this.waveThread != null)
            {
                return !this.waveThread.IsAlive;
            }
            return true;
        }

        #endregion

        #region Private Class Functions

        #region WaveIn Functions
        /* Function used to handled the audio buffers used in recording */
        private void GetWaveInHdrs()
        {
            int lastDataBlock = 0;
            int firstDataBlock = 0;
            WaveHdr[] audioBuffer = new WaveHdr[AUDIO_BUFFER_LENGTH];  /* buffer of audio data blocks used to record or play audio */
            GCHandle[] bufferHandles = new GCHandle[AUDIO_BUFFER_LENGTH];
            try
            {
                while (true)
                {
                    if (lastDataBlock - firstDataBlock < AUDIO_BUFFER_LENGTH)
                    {
                        audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH] = new WaveHdr(AUDIO_DATA_LENGTH);
                        bufferHandles[lastDataBlock % AUDIO_BUFFER_LENGTH] = GCHandle.Alloc(audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH], GCHandleType.Pinned);
                        CheckMMInResult(waveInPrepareHeader(this.waveHandle, audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH], (uint)Marshal.SizeOf(audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH])));
                        CheckMMInResult(waveInAddBuffer(this.waveHandle, audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH], (uint)Marshal.SizeOf(audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH])));
                        lastDataBlock++;
                    }
                    if ((audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwFlags & WHDR_DONE) != 0)
                    {
                        if (audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwBytesRecorded > 0)
                        {
                            byte[] capturedData = new byte[audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwBytesRecorded];
                            Marshal.Copy(audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].lpData, capturedData, 0, (int)audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwBytesRecorded);
                            this.audioDataStream.Add(capturedData);
                        }
                        CheckMMInResult(waveInUnprepareHeader(this.waveHandle, audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH], (uint)Marshal.SizeOf(audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH])));
                        audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].Dispose();
                        bufferHandles[firstDataBlock % AUDIO_BUFFER_LENGTH].Free();
                        firstDataBlock++;
                    }
                    if ((audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwFlags & WHDR_DONE) == 0 && lastDataBlock - firstDataBlock >= AUDIO_BUFFER_LENGTH)
                    {
                        Thread.Sleep(1000);
                    }
                }
            }
            catch (ThreadAbortException)
            {
                CheckMMInResult(waveInReset(this.waveHandle));
                while (firstDataBlock < lastDataBlock)
                {
                    while ((audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwFlags & WHDR_DONE) == 0)
                    {
                        CheckMMInResult(waveInReset(this.waveHandle));
                        Thread.Sleep(100);
                    }
                    if (audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwBytesRecorded > 0)
                    {
                        byte[] capturedData = new byte[audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwBytesRecorded];
                        Marshal.Copy(audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].lpData, capturedData, 0, (int)audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwBytesRecorded);
                        this.audioDataStream.Add(capturedData);
                    }
                    CheckMMInResult(waveInUnprepareHeader(this.waveHandle, audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH], (uint)Marshal.SizeOf(audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH])));
                    audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].Dispose();
                    bufferHandles[firstDataBlock % AUDIO_BUFFER_LENGTH].Free();
                    firstDataBlock++;
                }
            }

        }

        /*Function used to obtain an error message associated with an error number, and generate an exception with the message*/
        private void CheckMMInResult(uint result)
        {
            if (result != MM_NO_ERROR)
            {
                IntPtr aBuffer = Marshal.AllocCoTaskMem(ERROR_BUFFER_LENGTH);
                waveInGetErrorText(result, aBuffer, ERROR_BUFFER_LENGTH);
                throw new Exception(Marshal.PtrToStringAnsi(aBuffer));
            }

        }
        #endregion

        #region WaveOut Functions
        /*Function used to manage the buffers associated with the audio playout process*/
        private void GetWaveOutHdrs(object fileInfo)
        {
            Hashtable audioInfo = (Hashtable)fileInfo;
            FileStream audioFile = File.Open((string)audioInfo["audio_file"], FileMode.Open);
            byte[] audioDataStream = new byte[audioFile.Length];
            audioFile.Read(audioDataStream, 0, (int)Math.Min(int.MaxValue, audioFile.Length));
            int currentIndex = 0;
            int lastDataBlock = 0;
            int firstDataBlock = 0;
            WaveHdr[] audioBuffer = new WaveHdr[AUDIO_BUFFER_LENGTH];  /* buffer of audio data blocks used to record or play audio */
            GCHandle[] bufferHandles = new GCHandle[AUDIO_BUFFER_LENGTH];
            try
            {
                while (currentIndex < audioFile.Length || firstDataBlock != lastDataBlock)
                {
                    if (lastDataBlock - firstDataBlock < AUDIO_BUFFER_LENGTH && currentIndex < audioFile.Length)
                    {
                        audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH] = new WaveHdr((uint)Math.Min(AUDIO_DATA_LENGTH, (int) audioFile.Length - currentIndex));
                        bufferHandles[lastDataBlock % AUDIO_BUFFER_LENGTH] = GCHandle.Alloc(audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH], GCHandleType.Pinned);
                        Marshal.Copy(audioDataStream, currentIndex, audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH].lpData, (int)Math.Min(AUDIO_DATA_LENGTH, audioFile.Length - currentIndex));
                        currentIndex += (int)Math.Min(AUDIO_DATA_LENGTH, audioFile.Length - currentIndex);
                        CheckMMOutResult(waveOutPrepareHeader(this.waveHandle, audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH], (uint)Marshal.SizeOf(audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH])));
                        CheckMMOutResult(waveOutWrite(this.waveHandle, audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH], (uint)Marshal.SizeOf(audioBuffer[lastDataBlock % AUDIO_BUFFER_LENGTH])));
                        lastDataBlock++;
                    }
                    if ((audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwFlags & WHDR_DONE) != 0)
                    {
                        CheckMMOutResult(waveOutUnprepareHeader(this.waveHandle, audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH], (uint)Marshal.SizeOf(audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH])));
                        audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].Dispose();
                        bufferHandles[firstDataBlock % AUDIO_BUFFER_LENGTH].Free();
                        firstDataBlock++;
                    }
                    if (currentIndex >= audioFile.Length || (lastDataBlock - firstDataBlock >= AUDIO_BUFFER_LENGTH && (audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwFlags & WHDR_DONE) == 0))
                    {
                        Thread.Sleep(1000);
                    }
                }
            }
            catch (ThreadAbortException)
            {
            }
            finally
            {

                CheckMMOutResult(waveOutReset(this.waveHandle));
                while (firstDataBlock < lastDataBlock)
                {
                    while ((audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].dwFlags & WHDR_DONE) == 0)
                    {
                        CheckMMOutResult(waveOutReset(this.waveHandle));
                        Thread.Sleep(100);
                    }
                    CheckMMOutResult(waveOutUnprepareHeader(this.waveHandle, audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH], (uint)Marshal.SizeOf(audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH])));
                    audioBuffer[firstDataBlock % AUDIO_BUFFER_LENGTH].Dispose();
                    bufferHandles[firstDataBlock % AUDIO_BUFFER_LENGTH].Free();
                    firstDataBlock++;
                }
                audioFile.Close();
            }

        }

        /*Function used to obtain an error message associated with an error number, and generate an exception with the message*/
        private void CheckMMOutResult(uint result)
        {
            if (result != MM_NO_ERROR)
            {
                IntPtr aBuffer = Marshal.AllocCoTaskMem(ERROR_BUFFER_LENGTH);
                waveOutGetErrorText(result, aBuffer, ERROR_BUFFER_LENGTH);
                throw new Exception(Marshal.PtrToStringAnsi(aBuffer));
            }

        }

        #endregion
        #endregion


    }
}
