using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
using System.ComponentModel;

namespace Ti.Atf.Ted.Drivers
{
    public class MessageReceivedEventArgs : EventArgs
    {
        private readonly Message _message;
        public MessageReceivedEventArgs(Message message) { _message = message; }
        public Message Message { get { return _message; } }
    }

    public static class MessageEvents
    {
        private static object _lock = new object();
        private static MessageWindow _window;
        private static IntPtr _windowHandle;
        private static SynchronizationContext _context;

        public static event EventHandler<MessageReceivedEventArgs> MessageReceived;

        public static void WatchMessage(int message)
        {
            EnsureInitialized();
            _window.RegisterEventForMessage(message);
        }

        public static IntPtr WindowHandle
        {
            get
            {
                EnsureInitialized();
                return _windowHandle;
            }
        }

        private static void EnsureInitialized()
        {
            lock (_lock)
            {
                if (_window == null)
                {
                    _context = AsyncOperationManager.SynchronizationContext;
                    using (ManualResetEvent mre = new ManualResetEvent(false))
                    {
                        Thread t = new Thread((ThreadStart)delegate
                        {
                            _window = new MessageWindow();
                            _windowHandle = _window.Handle;
                            mre.Set();
                            Application.Run();
                        });
                        t.Name = "MessageEvents message loop";
                        t.IsBackground = true;
                        t.Start();

                        mre.WaitOne();
                    }
                }
            }
        }

        private class MessageWindow : Form
        {
            private ReaderWriterLock _lock = new ReaderWriterLock();
            private Dictionary<int, bool> _messageSet = new Dictionary<int, bool>();

            public void RegisterEventForMessage(int messageID)
            {
                _lock.AcquireWriterLock(Timeout.Infinite);
                _messageSet[messageID] = true;
                _lock.ReleaseWriterLock();
            }

            protected override void WndProc(ref Message m)
            {
                _lock.AcquireReaderLock(Timeout.Infinite);
                bool handleMessage = _messageSet.ContainsKey(m.Msg);
                _lock.ReleaseReaderLock();

                if (handleMessage)
                {
                    MessageEvents._context.Post(delegate(object state)
                    {
                        EventHandler<MessageReceivedEventArgs> handler = MessageEvents.MessageReceived;
                        if (handler != null) handler(null, new MessageReceivedEventArgs((Message)state));
                    }, m);
                }

                base.WndProc(ref m);
            }
        }
    }

    public class BaseMMController
    {
        /*==========================================================================
         *
         *  mmsystem.h -- Include file for Multimedia API's
         *
         *  Version 4.00
         *
         *  Copyright (C) 1992-1998 Microsoft Corporation.  All Rights Reserved.
         *
         *--------------------------------------------------------------------------
         *
         *  Define:         Prevent inclusion of:
         *  --------------  --------------------------------------------------------
         *  MMNODRV         Installable driver support
         *  MMNOSOUND       Sound support
         *  MMNOWAVE        Waveform support
         *  MMNOMIDI        MIDI support
         *  MMNOAUX         Auxiliary audio support
         *  MMNOMIXER       Mixer support
         *  MMNOTIMER       Timer support
         *  MMNOJOY         Joystick support
         *  MMNOMCI         MCI support
         *  MMNOMMIO        Multimedia file I/O support
         *  MMNOMMSYSTEM    General MMSYSTEM functions
         *
         *==========================================================================
         */


        /****************************************************************************

                            General constants and data types

        ****************************************************************************/


            /* general constants */
            public const uint MAXPNAMELEN   =   32;     /* max product name length (including NULL) */
            public const uint MAXERRORLENGTH =  256;    /* max error text length (including NULL) */
            public const uint MAX_JOYSTICKOEMVXDNAME = 260; /* max oem vxd name length (including NULL) */
            public const uint MM_MICROSOFT         =   1;   /* Microsoft Corporation */
            public const uint MM_MIDI_MAPPER       =   1;   /* MIDI Mapper */
            public const uint MM_WAVE_MAPPER       =   2;   /* Wave Mapper */
            public const uint MM_SNDBLST_MIDIOUT   =   3;   /* Sound Blaster MIDI output port */
            public const uint MM_SNDBLST_MIDIIN    =   4;   /* Sound Blaster MIDI input port */
            public const uint MM_SNDBLST_SYNTH     =   5;   /* Sound Blaster internal synthesizer */
            public const uint MM_SNDBLST_WAVEOUT   =   6;   /* Sound Blaster waveform output */
            public const uint MM_SNDBLST_WAVEIN    =   7;   /* Sound Blaster waveform input */
            public const uint MM_ADLIB             =   9;   /* Ad Lib-compatible synthesizer */
            public const uint MM_MPU401_MIDIOUT    =  10;   /* MPU401-compatible MIDI output port */
            public const uint MM_MPU401_MIDIIN     =  11;  /* MPU401-compatible MIDI input port */
            public const uint MM_PC_JOYSTICK       =  12;   /* Joystick adapter */



        /* MMTIME data structure */
        [StructLayout(LayoutKind.Sequential)]
        public struct mmtime_tag
        {
            public uint wType;      /* indicates the contents of the union */

            [ StructLayout(LayoutKind.Explicit) ]
            public struct u
            {
                [ FieldOffset(0) ] public uint       ms;         /* milliseconds */
                [ FieldOffset(0) ] public uint       sample;     /* samples */
                [ FieldOffset(0) ] public uint       cb;         /* byte count */
                [ FieldOffset(0) ] public uint       ticks;      /* ticks in MIDI stream */

                /* SMPTE */
                [StructLayout(LayoutKind.Sequential)]
                public struct smpte
                {
                    public byte    hour;       /* hours */
                    public byte    min;        /* minutes */
                    public byte    sec;        /* seconds */
                    public byte    frame;      /* frames  */
                    public byte    fps;        /* frames per second */
                    public byte    dummy;      /* pad */
                    public byte[]  pad;
                };

                /* MIDI */
                [StructLayout(LayoutKind.Sequential)]
                public struct midi
                {
                    public uint songptrpos;   /* song pointer position */
                };
            };
        };

        /* types for wType field in MMTIME public struct */
        public const uint TIME_MS     =    0x0001;  /* time in milliseconds */
        public const uint TIME_SAMPLES =   0x0002;  /* number of wave samples */
        public const uint TIME_byteS   =   0x0004;  /* current byte offset */
        public const uint TIME_SMPTE   =   0x0008;  /* SMPTE time */
        public const uint TIME_MIDI    =   0x0010;  /* MIDI time */
        public const uint TIME_TICKS   =   0x0020;  /* Ticks within MIDI stream */

        /****************************************************************************

                            Multimedia Extensions Window Messages

        ****************************************************************************/

        public const ushort MM_JOY1MOVE     =    0x3A0;           /* joystick */
        public const ushort MM_JOY2MOVE     =    0x3A1;
        public const ushort MM_JOY1ZMOVE    =    0x3A2;
        public const ushort MM_JOY2ZMOVE    =    0x3A3;
        public const ushort MM_JOY1BUTTONDOWN =  0x3B5;
        public const ushort MM_JOY2BUTTONDOWN =  0x3B6;
        public const ushort MM_JOY1BUTTONUP   =  0x3B7;
        public const ushort MM_JOY2BUTTONUP   =  0x3B8;

        public const ushort MM_MCINOTIFY     =    0x3B9;           /* MCI */

        public const ushort MM_WOM_OPEN     =    0x3BB;          /* waveform output */
        public const ushort MM_WOM_CLOSE    =    0x3BC;
        public const ushort MM_WOM_DONE     =    0x3BD;

        public const ushort MM_WIM_OPEN    =     0x3BE;           /* waveform input */
        public const ushort MM_WIM_CLOSE   =     0x3BF;
        public const ushort MM_WIM_DATA    =     0x3C0;

        public const ushort MM_MIM_OPEN    =     0x3C1;           /* MIDI input */
        public const ushort MM_MIM_CLOSE   =     0x3C2;
        public const ushort MM_MIM_DATA    =     0x3C3;
        public const ushort MM_MIM_LONGDATA  =   0x3C4;
        public const ushort MM_MIM_ERROR    =    0x3C5;
        public const ushort MM_MIM_LONGERROR  =  0x3C6;

        public const ushort MM_MOM_OPEN    =     0x3C7;          /* MIDI output */
        public const ushort MM_MOM_CLOSE   =     0x3C8;
        public const ushort MM_MOM_DONE    =     0x3C9;

        public const ushort MM_DRVM_OPEN   =    0x3D0;           /* installable drivers */
        public const ushort MM_DRVM_CLOSE  =    0x3D1;
        public const ushort MM_DRVM_DATA   =    0x3D2;
        public const ushort MM_DRVM_ERROR   =   0x3D3;

        /* these are used by msacm.h */
        public const ushort MM_STREAM_OPEN   =   0x3D4;
        public const ushort MM_STREAM_CLOSE  =   0x3D5;
        public const ushort MM_STREAM_DONE   =   0x3D6;
        public const ushort MM_STREAM_ERROR  =   0x3D7;

        public const ushort MM_MOM_POSITIONCB  =  0x3CA;           /* Callback for MEVT_POSITIONCB */

        public const ushort MM_MCISIGNAL  =      0x3CB;

        public const ushort MM_MIM_MOREDATA   =   0x3CC;          /* MIM_DONE w/ pending events */
        public const ushort MM_MIXM_LINE_CHANGE   =   0x3D0;       /* mixer line change notify */
        public const ushort MM_MIXM_CONTROL_CHANGE  = 0x3D1;       /* mixer control change notify */


        /****************************************************************************

                        String resource number bases (internal use)

        ****************************************************************************/

        public const uint MMSYSERR_BASE  =        0;
        public const uint WAVERR_BASE       =     32;
        public const uint MIDIERR_BASE      =    64;
        public const uint TIMERR_BASE       =     96;
        public const uint JOYERR_BASE       =     160;
        public const uint MCIERR_BASE       =     256;
        public const uint MIXERR_BASE       =     1024;

        public const uint MCI_STRING_OFFSET =     512;
        public const uint MCI_VD_OFFSET     =     1024;
        public const uint MCI_CD_OFFSET     =     1088;
        public const uint MCI_WAVE_OFFSET   =     1152;
        public const uint MCI_SEQ_OFFSET    =     1216;

        /****************************************************************************

                                General error return values

        ****************************************************************************/

        /* general error return values */
        public const uint MMSYSERR_NOERROR   =   0;                    /* no error */
        public const uint MMSYSERR_ERROR     =   (MMSYSERR_BASE + 1);  /* unspecified error */
        public const uint MMSYSERR_BADDEVICEID =  (MMSYSERR_BASE + 2);  /* device ID out of range */
        public const uint MMSYSERR_NOTENABLED  = (MMSYSERR_BASE + 3);  /* driver failed enable */
        public const uint MMSYSERR_ALLOCATED   = (MMSYSERR_BASE + 4);  /* device already allocated */
        public const uint MMSYSERR_INVALHANDLE = (MMSYSERR_BASE + 5);  /* device handle is invalid */
        public const uint MMSYSERR_NODRIVER    = (MMSYSERR_BASE + 6);  /* no device driver present */
        public const uint MMSYSERR_NOMEM       = (MMSYSERR_BASE + 7);  /* memory allocation error */
        public const uint MMSYSERR_NOTSUPPORTED = (MMSYSERR_BASE + 8);  /* function isn't supported */
        public const uint MMSYSERR_BADERRNUM    = (MMSYSERR_BASE + 9);  /* error value out of range */
        public const uint MMSYSERR_INVALFLAG    = (MMSYSERR_BASE + 10); /* invalid flag passed */
        public const uint MMSYSERR_INVALPARAM   = (MMSYSERR_BASE + 11); /* invalid parameter passed */
        public const uint MMSYSERR_HANDLEBUSY   = (MMSYSERR_BASE + 12); /* handle being used */
                                                           /* simultaneously on another */
                                                           /* thread (eg callback) */
        public const uint MMSYSERR_INVALIDALIAS = (MMSYSERR_BASE + 13); /* specified alias not found */
        public const uint MMSYSERR_BADDB       = (MMSYSERR_BASE + 14); /* bad registry database */
        public const uint MMSYSERR_KEYNOTFOUND = (MMSYSERR_BASE + 15); /* registry key not found */
        public const uint MMSYSERR_READERROR   = (MMSYSERR_BASE + 16); /* registry read error */
        public const uint MMSYSERR_WRITEERROR  = (MMSYSERR_BASE + 17); /* registry write error */
        public const uint MMSYSERR_DELETEERROR = (MMSYSERR_BASE + 18); /* registry delete error */
        public const uint MMSYSERR_VALNOTFOUND = (MMSYSERR_BASE + 19); /* registry value not found */
        public const uint MMSYSERR_NODRIVERCB  = (MMSYSERR_BASE + 20); /* driver does not call DriverCallback */
        public const uint MMSYSERR_MOREDATA    = (MMSYSERR_BASE + 21); /* more data to be returned */
        public const uint MMSYSERR_LASTERROR   = (MMSYSERR_BASE + 21); /* last error in range */

        /****************************************************************************

                                Installable driver support

        ****************************************************************************/
        [StructLayout(LayoutKind.Sequential)]
        public struct DRVCONFIGINFOEX {
            public uint dwDCISize;
            public StringBuilder lpszDCISectionName;
            public StringBuilder lpszDCIAliasName;
            public uint dnDevNode;
        };

        /* Driver messages */
        public const uint DRV_LOAD            =    0x0001;
        public const uint DRV_ENABLE          =    0x0002;
        public const uint DRV_OPEN            =    0x0003;
        public const uint DRV_CLOSE           =    0x0004;
        public const uint DRV_DISABLE         =    0x0005;
        public const uint DRV_FREE            =    0x0006;
        public const uint DRV_CONFIGURE       =    0x0007;
        public const uint DRV_QUERYCONFIGURE  =    0x0008;
        public const uint DRV_INSTALL         =    0x0009;
        public const uint DRV_REMOVE          =    0x000A;
        public const uint DRV_EXITSESSION     =    0x000B;
        public const uint DRV_POWER           =    0x000F;
        public const uint DRV_RESERVED        =    0x0800;
        public const uint DRV_USER            =    0x4000;


        [StructLayout(LayoutKind.Sequential)]
        public struct tagDRVCONFIGINFO {
            public uint dwDCISize;
            public StringBuilder lpszDCISectionName;
            public StringBuilder lpszDCIAliasName;
        };

        /* Supported return values for DRV_CONFIGURE message */
        public const uint DRVCNF_CANCEL =           0x0000;
        public const uint DRVCNF_OK          =     0x0001;
        public const uint DRVCNF_RESTART     =     0x0002;

        public const uint DRV_CANCEL         =    DRVCNF_CANCEL;
        public const uint DRV_OK             =    DRVCNF_OK;
        public const uint DRV_RESTART        =    DRVCNF_RESTART;

        public const uint DRV_MCI_FIRST      =    DRV_RESERVED;
        public const uint DRV_MCI_LAST       =    (DRV_RESERVED + 0xFFF);

        /****************************************************************************

                                  Driver callback support

        ****************************************************************************/

        /* flags used with waveOutOpen(), waveInOpen(), midiInOpen(), and */
        /* midiOutOpen() to specify the type of the dwCallback parameter. */

        public const ulong CALLBACK_TYPEMASK  = 0x00070000L;    /* callback type mask */
        public const ulong CALLBACK_NULL      = 0x00000000L;    /* no callback */
        public const ulong CALLBACK_WINDOW    = 0x00010000L;    /* dwCallback is a HWND */
        public const ulong CALLBACK_TASK      = 0x00020000L;    /* dwCallback is a HTASK */
        public const ulong CALLBACK_FUNCTION  = 0x00030000L;    /* dwCallback is a FARPROC */

        public const ulong CALLBACK_THREAD    = (CALLBACK_TASK);/* thread ID replaces 16 bit task */
        public const ulong CALLBACK_EVENT     = 0x00050000L;    /* dwCallback is an EVENT Handle */


        public const uint SND_SYNC       =     0x0000;  /* play synchronously (default) */
        public const uint SND_ASYNC      =     0x0001;  /* play asynchronously */
        public const uint SND_NODEFAULT  =     0x0002;  /* silence (!default) if sound not found */
        public const uint SND_MEMORY     =     0x0004;  /* pszSound points to a memory file */
        public const uint SND_LOOP       =     0x0008;  /* loop the sound until next sndPlaySound */
        public const uint SND_NOSTOP     =     0x0010;  /* don't stop any currently playing sound */

        public const ulong SND_NOWAIT   =   0x00002000L; /* don't wait if the driver is busy */
        public const ulong SND_ALIAS    =   0x00010000L; /* name is a registry alias */
        public const ulong SND_ALIAS_ID  =  0x00110000L; /* alias is a predefined ID */
        public const ulong  SND_FILENAME  =  0x00020000L; /* name is file name */
        public const ulong SND_RESOURCE  =  0x00040004L; /* name is resource name or atom */
        public const uint SND_PURGE      =     0x0040;  /* purge non-static events for task */
        public const uint SND_APPLICATION  =   0x0080;  /* look for application specific association */
        public const uint SND_ALIAS_START = 0;           /* alias base */

        /****************************************************************************

                                Waveform audio support

        ****************************************************************************/

        /* waveform audio error return values */
        public const uint WAVERR_BADFORMAT    =  (WAVERR_BASE + 0);    /* unsupported wave format */
        public const uint WAVERR_STILLPLAYING =  (WAVERR_BASE + 1);    /* still something playing */
        public const uint WAVERR_UNPREPARED   =  (WAVERR_BASE + 2);    /* header not prepared */
        public const uint WAVERR_SYNC         =  (WAVERR_BASE + 3);    /* device is synchronous */
        public const uint WAVERR_LASTERROR    =  (WAVERR_BASE + 3);    /* last error in range */


        /* wave callback messages */
        public const ushort WOM_OPEN   =     MM_WOM_OPEN;
        public const ushort WOM_CLOSE  =     MM_WOM_CLOSE;
        public const ushort WOM_DONE   =     MM_WOM_DONE;
        public const ushort WIM_OPEN   =     MM_WIM_OPEN;
        public const ushort WIM_CLOSE  =     MM_WIM_CLOSE;
        public const ushort WIM_DATA   =     MM_WIM_DATA;

        public const uint WAVE_MAPPER = unchecked((uint)-1);

        /* flags for dwFlags parameter in waveOutOpen() and waveInOpen() */
        public const  uint WAVE_FORMAT_QUERY    =     0x0001;
        public const  uint WAVE_ALLOWSYNC       =     0x0002;
        public const  uint WAVE_MAPPED          =     0x0004;
        public const  uint WAVE_FORMAT_DIRECT   =     0x0008;
        public const  uint WAVE_FORMAT_DIRECT_QUERY = (WAVE_FORMAT_QUERY | WAVE_FORMAT_DIRECT);

        /* wave data block header */
        [StructLayout(LayoutKind.Sequential)]
        public struct wavehdr_tag {
            public StringBuilder lpData;                 /* pointer to locked data buffer */
            public uint dwBufferLength;         /* length of data buffer */
            public uint dwBytesRecorded;        /* used for input only */
            public UIntPtr dwUser;                 /* for client's use */
            public uint dwFlags;                /* assorted flags (see defines) */
            public uint dwLoops;                /* loop control counter */
            public object lpNext;     /* reserved for driver */
            public UIntPtr reserved;               /* reserved for driver */
        };// WAVEHDR, *PWAVEHDR, NEAR *NPWAVEHDR, FAR *LPWAVEHDR;

        /* flags for dwFlags field of WAVEHDR */
        public const ulong WHDR_DONE       =    0x00000001;  /* done bit */
        public const ulong WHDR_PREPARED   =    0x00000002;  /* set if this header has been prepared */
        public const ulong WHDR_BEGINLOOP  =    0x00000004;  /* loop start block */
        public const ulong WHDR_ENDLOOP    =    0x00000008;  /* loop end block */
        public const ulong WHDR_INQUEUE    =    0x00000010;  /* reserved for driver */

        /* waveform output device capabilities structure */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagWAVEOUTCAPSA {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public uint dwFormats;             /* formats supported */
            public ushort wChannels;             /* number of sources supported */
            public ushort wReserved1;            /* packing */
            public uint dwSupport;             /* functionality supported by driver */
        };// WAVEOUTCAPSA, *PWAVEOUTCAPSA, *NPWAVEOUTCAPSA, *LPWAVEOUTCAPSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagWAVEOUTCAPSW {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public uint dwFormats;             /* formats supported */
            public ushort wChannels;             /* number of sources supported */
            public ushort wReserved1;            /* packing */
            public uint dwSupport;             /* functionality supported by driver */
        };// WAVEOUTCAPSW, *PWAVEOUTCAPSW, *NPWAVEOUTCAPSW, *LPWAVEOUTCAPSW;

        [StructLayout(LayoutKind.Sequential)]
        public struct tagWAVEOUTCAPS2A {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public uint dwFormats;             /* formats supported */
            public ushort wChannels;             /* number of sources supported */
            public ushort wReserved1;            /* packing */
            public uint dwSupport;             /* functionality supported by driver */
            public string ManufacturerGuid;      /* for extensible MID mapping */
            public string ProductGuid;           /* for extensible PID mapping */
            public string NameGuid;              /* for name lookup in registry */
        };// WAVEOUTCAPS2A, *PWAVEOUTCAPS2A, *NPWAVEOUTCAPS2A, *LPWAVEOUTCAPS2A;

        [StructLayout(LayoutKind.Sequential)]
        public struct tagWAVEOUTCAPS2W {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public uint dwFormats;             /* formats supported */
            public ushort wChannels;             /* number of sources supported */
            public ushort wReserved1;            /* packing */
            public uint dwSupport;             /* functionality supported by driver */
            public string ManufacturerGuid;      /* for extensible MID mapping */
            public string ProductGuid;           /* for extensible PID mapping */
            public string NameGuid;              /* for name lookup in registry */
        };// WAVEOUTCAPS2W, *PWAVEOUTCAPS2W, *NPWAVEOUTCAPS2W, *LPWAVEOUTCAPS2W;

        [StructLayout(LayoutKind.Sequential)]
        public struct waveoutcaps_tag {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;        /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public uint dwFormats;             /* formats supported */
            public ushort wChannels;             /* number of sources supported */
            public uint dwSupport;             /* functionality supported by driver */
        };// WAVEOUTCAPS, *PWAVEOUTCAPS, NEAR *NPWAVEOUTCAPS, FAR *LPWAVEOUTCAPS;


        /* flags for dwSupport field of WAVEOUTCAPS */
        public const uint WAVECAPS_PITCH     =     0x0001;   /* supports pitch control */
        public const uint WAVECAPS_PLAYBACKRATE  = 0x0002;   /* supports playback rate control */
        public const uint WAVECAPS_VOLUME        = 0x0004;   /* supports volume control */
        public const uint WAVECAPS_LRVOLUME      = 0x0008;   /* separate left-right volume control */
        public const uint WAVECAPS_SYNC          = 0x0010;
        public const uint WAVECAPS_SAMPLEACCURATE = 0x0020;


        [StructLayout(LayoutKind.Sequential)]
        public struct tagWAVEINCAPSA {
            public ushort wMid;                    /* manufacturer ID */
            public ushort wPid;                    /* product ID */
            public uint vDriverVersion;        /* version of the driver */
            public string szPname;    /* product name (NULL terminated string) */
            public uint dwFormats;               /* formats supported */
            public ushort wChannels;               /* number of channels supported */
            public ushort wReserved1;              /* structure packing */
        }; //WAVEINCAPSA, *PWAVEINCAPSA, *NPWAVEINCAPSA, *LPWAVEINCAPSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagWAVEINCAPSW {
            public ushort wMid;                    /* manufacturer ID */
            public ushort wPid;                    /* product ID */
            public uint vDriverVersion;        /* version of the driver */
            public string szPname;    /* product name (NULL terminated string) */
            public uint dwFormats;               /* formats supported */
            public ushort wChannels;               /* number of channels supported */
            public ushort wReserved1;              /* structure packing */
        };// WAVEINCAPSW, *PWAVEINCAPSW, *NPWAVEINCAPSW, *LPWAVEINCAPSW;

        [StructLayout(LayoutKind.Sequential)]
        public struct tagWAVEINCAPS2A {
            public ushort wMid;                    /* manufacturer ID */
            public ushort wPid;                    /* product ID */
            public uint vDriverVersion;        /* version of the driver */
            public string szPname;    /* product name (NULL terminated string) */
            public uint dwFormats;               /* formats supported */
            public ushort wChannels;               /* number of channels supported */
            public ushort wReserved1;              /* structure packing */
            public string ManufacturerGuid;        /* for extensible MID mapping */
            public string ProductGuid;             /* for extensible PID mapping */
            public string NameGuid;                /* for name lookup in registry */
        };// WAVEINCAPS2A, *PWAVEINCAPS2A, *NPWAVEINCAPS2A, *LPWAVEINCAPS2A;

        [StructLayout(LayoutKind.Sequential)]
        public struct tagWAVEINCAPS2W {
            public ushort wMid;                    /* manufacturer ID */
            public ushort wPid;                    /* product ID */
            public uint vDriverVersion;        /* version of the driver */
            public string szPname;    /* product name (NULL terminated string) */
            public uint dwFormats;               /* formats supported */
            public ushort wChannels;               /* number of channels supported */
            public ushort wReserved1;              /* structure packing */
            public string ManufacturerGuid;        /* for extensible MID mapping */
            public string ProductGuid;             /* for extensible PID mapping */
            public string NameGuid;                /* for name lookup in registry */
        };// WAVEINCAPS2W, *PWAVEINCAPS2W, *NPWAVEINCAPS2W, *LPWAVEINCAPS2W;

        [StructLayout(LayoutKind.Sequential)]
        public struct waveincaps_tag {
            public ushort wMid;                    /* manufacturer ID */
            public ushort wPid;                    /* product ID */
            public uint vDriverVersion;          /* version of the driver */
            public string szPname;    /* product name (NULL terminated string) */
            public uint dwFormats;               /* formats supported */
            public ushort wChannels;               /* number of channels supported */
        };// WAVEINCAPS, *PWAVEINCAPS, NEAR *NPWAVEINCAPS, FAR *LPWAVEINCAPS;

        /* defines for dwFormat field of WAVEINCAPS and WAVEOUTCAPS */
        public const ulong WAVE_INVALIDFORMAT     = 0x00000000;       /* invalid format */
        public const ulong WAVE_FORMAT_1M08       = 0x00000001;       /* 11.025 kHz, Mono,   8-bit  */
        public const ulong WAVE_FORMAT_1S08       = 0x00000002;       /* 11.025 kHz, Stereo, 8-bit  */
        public const ulong WAVE_FORMAT_1M16       = 0x00000004;       /* 11.025 kHz, Mono,   16-bit */
        public const ulong WAVE_FORMAT_1S16       = 0x00000008;       /* 11.025 kHz, Stereo, 16-bit */
        public const ulong WAVE_FORMAT_2M08       = 0x00000010;       /* 22.05  kHz, Mono,   8-bit  */
        public const ulong WAVE_FORMAT_2S08       = 0x00000020;       /* 22.05  kHz, Stereo, 8-bit  */
        public const ulong WAVE_FORMAT_2M16       = 0x00000040;       /* 22.05  kHz, Mono,   16-bit */
        public const ulong WAVE_FORMAT_2S16       = 0x00000080;       /* 22.05  kHz, Stereo, 16-bit */
        public const ulong WAVE_FORMAT_4M08       = 0x00000100;       /* 44.1   kHz, Mono,   8-bit  */
        public const ulong WAVE_FORMAT_4S08       = 0x00000200;       /* 44.1   kHz, Stereo, 8-bit  */
        public const ulong WAVE_FORMAT_4M16       = 0x00000400;       /* 44.1   kHz, Mono,   16-bit */
        public const ulong WAVE_FORMAT_4S16       = 0x00000800;       /* 44.1   kHz, Stereo, 16-bit */

        public const ulong WAVE_FORMAT_44M08      = 0x00000100;       /* 44.1   kHz, Mono,   8-bit  */
        public const ulong WAVE_FORMAT_44S08      = 0x00000200;       /* 44.1   kHz, Stereo, 8-bit  */
        public const ulong WAVE_FORMAT_44M16      = 0x00000400;       /* 44.1   kHz, Mono,   16-bit */
        public const ulong WAVE_FORMAT_44S16      = 0x00000800;       /* 44.1   kHz, Stereo, 16-bit */
        public const ulong WAVE_FORMAT_48M08      = 0x00001000;       /* 48     kHz, Mono,   8-bit  */
        public const ulong WAVE_FORMAT_48S08      = 0x00002000;       /* 48     kHz, Stereo, 8-bit  */
        public const ulong WAVE_FORMAT_48M16      = 0x00004000;       /* 48     kHz, Mono,   16-bit */
        public const ulong WAVE_FORMAT_48S16      = 0x00008000;       /* 48     kHz, Stereo, 16-bit */
        public const ulong WAVE_FORMAT_96M08      = 0x00010000;       /* 96     kHz, Mono,   8-bit  */
        public const ulong WAVE_FORMAT_96S08      = 0x00020000;       /* 96     kHz, Stereo, 8-bit  */
        public const ulong WAVE_FORMAT_96M16      = 0x00040000;       /* 96     kHz, Mono,   16-bit */
        public const ulong WAVE_FORMAT_96S16      = 0x00080000;       /* 96     kHz, Stereo, 16-bit */

        /* OLD general waveform format structure (information common to all formats) */
        [StructLayout(LayoutKind.Sequential)]
        public struct waveformat_tag {
            public ushort wFormatTag;        /* format type */
            public ushort nChannels;         /* number of channels (i.e. mono, stereo, etc.) */
            public uint nSamplesPerSec;    /* sample rate */
            public uint nAvgBytesPerSec;   /* for buffer estimation */
            public ushort nBlockAlign;       /* block size of data */
        }; // WAVEFORMAT, *PWAVEFORMAT, NEAR *NPWAVEFORMAT, FAR *LPWAVEFORMAT;

        /* flags for wFormatTag field of WAVEFORMAT */
        public const int WAVE_FORMAT_PCM   =   1;


        /* specific waveform format structure for PCM data */
        [StructLayout(LayoutKind.Sequential)]
        public struct pcmwaveformat_tag {
            public waveformat_tag wf;
            public ushort wBitsPerSample;
        };// PCMWAVEFORMAT, *PPCMWAVEFORMAT, NEAR *NPPCMWAVEFORMAT, FAR *LPPCMWAVEFORMAT;

        /*
         *  extended waveform format structure used for all non-PCM formats. this
         *  structure is common to all non-PCM formats.
         */
        [StructLayout(LayoutKind.Sequential)]
        public struct tWAVEFORMATEX
        {
            public ushort wFormatTag;         /* format type */
            public ushort nChannels;          /* number of channels (i.e. mono, stereo...) */
            public uint nSamplesPerSec;     /* sample rate */
            public uint nAvgBytesPerSec;    /* for buffer estimation */
            public ushort nBlockAlign;        /* block size of data */
            public ushort wBitsPerSample;     /* number of bits per sample of mono data */
            public ushort cbSize;             /* the count in bytes of the size of */
                                            /* extra information (after cbSize) */
        };// WAVEFORMATEX, *PWAVEFORMATEX, NEAR *NPWAVEFORMATEX, FAR *LPWAVEFORMATEX;


        /****************************************************************************

                                    MIDI audio support

        ****************************************************************************/

        /* MIDI error return values */
        public const uint MIDIERR_UNPREPARED    = (MIDIERR_BASE + 0);   /* header not prepared */
        public const uint MIDIERR_STILLPLAYING  = (MIDIERR_BASE + 1);   /* still something playing */
        public const uint MIDIERR_NOMAP         = (MIDIERR_BASE + 2);   /* no configured instruments */
        public const uint MIDIERR_NOTREADY      = (MIDIERR_BASE + 3);   /* hardware is still busy */
        public const uint MIDIERR_NODEVICE      = (MIDIERR_BASE + 4);   /* port no longer connected */
        public const uint MIDIERR_INVALIDSETUP  = (MIDIERR_BASE + 5);   /* invalid MIF */
        public const uint MIDIERR_BADOPENMODE   = (MIDIERR_BASE + 6);   /* operation unsupported w/ open mode */
        public const uint MIDIERR_DONT_CONTINUE = (MIDIERR_BASE + 7);   /* thru device 'eating' a message */
        public const uint MIDIERR_LASTERROR     = (MIDIERR_BASE + 7);   /* last error in range */

        /* MIDI callback messages */
        public const ushort MIM_OPEN     =   MM_MIM_OPEN;
        public const ushort MIM_CLOSE    =   MM_MIM_CLOSE;
        public const ushort MIM_DATA     =   MM_MIM_DATA;
        public const ushort MIM_LONGDATA =   MM_MIM_LONGDATA;
        public const ushort MIM_ERROR    =   MM_MIM_ERROR;
        public const ushort MIM_LONGERROR =  MM_MIM_LONGERROR;
        public const ushort MOM_OPEN      =  MM_MOM_OPEN;
        public const ushort MOM_CLOSE     =  MM_MOM_CLOSE;
        public const ushort MOM_DONE      =  MM_MOM_DONE;

        public const ushort MIM_MOREDATA    =  MM_MIM_MOREDATA;
        public const ushort MOM_POSITIONCB  =  MM_MOM_POSITIONCB;

        /* device ID for MIDI mapper */
        public const uint MIDIMAPPER = unchecked((uint)-1);
        public const uint MIDI_MAPPER = unchecked((uint)-1);

        /* flags for dwFlags parm of midiInOpen() */
        public const ulong MIDI_IO_STATUS     =  0x00000020L;


        /* flags for wFlags parm of midiOutCachePatches(), midiOutCacheDrumPatches() */
        public const int MIDI_CACHE_ALL      = 1;
        public const int MIDI_CACHE_BESTFIT  = 2;
        public const int MIDI_CACHE_QUERY    = 3;
        public const int MIDI_UNCACHE        = 4;

        /* MIDI output device capabilities structure */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIDIOUTCAPSA {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public ushort wTechnology;           /* type of device */
            public ushort wVoices;               /* # of voices (internal synth only) */
            public ushort wNotes;                /* max # of notes (internal synth only) */
            public ushort wChannelMask;          /* channels used (internal synth only) */
            public uint dwSupport;             /* functionality supported by driver */
        };// MIDIOUTCAPSA, *PMIDIOUTCAPSA, *NPMIDIOUTCAPSA, *LPMIDIOUTCAPSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIDIOUTCAPSW {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public ushort wTechnology;           /* type of device */
            public ushort wVoices;               /* # of voices (internal synth only) */
            public ushort wNotes;                /* max # of notes (internal synth only) */
            public ushort wChannelMask;          /* channels used (internal synth only) */
            public uint dwSupport;             /* functionality supported by driver */
        };// MIDIOUTCAPSW, *PMIDIOUTCAPSW, *NPMIDIOUTCAPSW, *LPMIDIOUTCAPSW;

        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIDIOUTCAPS2A {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public ushort wTechnology;           /* type of device */
            public ushort wVoices;               /* # of voices (internal synth only) */
            public ushort wNotes;                /* max # of notes (internal synth only) */
            public ushort wChannelMask;          /* channels used (internal synth only) */
            public uint dwSupport;             /* functionality supported by driver */
            public string ManufacturerGuid;      /* for extensible MID mapping */
            public string ProductGuid;           /* for extensible PID mapping */
            public string NameGuid;              /* for name lookup in registry */
        };// MIDIOUTCAPS2A, *PMIDIOUTCAPS2A, *NPMIDIOUTCAPS2A, *LPMIDIOUTCAPS2A;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIDIOUTCAPS2W {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public ushort wTechnology;           /* type of device */
            public ushort wVoices;               /* # of voices (internal synth only) */
            public ushort wNotes;                /* max # of notes (internal synth only) */
            public ushort wChannelMask;          /* channels used (internal synth only) */
            public uint dwSupport;             /* functionality supported by driver */
            public string ManufacturerGuid;      /* for extensible MID mapping */
            public string ProductGuid;           /* for extensible PID mapping */
            public string NameGuid;              /* for name lookup in registry */
        };// MIDIOUTCAPS2W, *PMIDIOUTCAPS2W, *NPMIDIOUTCAPS2W, *LPMIDIOUTCAPS2W;

        [StructLayout(LayoutKind.Sequential)]
        public struct midioutcaps_tag {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;        /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public ushort wTechnology;           /* type of device */
            public ushort wVoices;               /* # of voices (internal synth only) */
            public ushort wNotes;                /* max # of notes (internal synth only) */
            public ushort wChannelMask;          /* channels used (internal synth only) */
            public uint dwSupport;             /* functionality supported by driver */
        };// MIDIOUTCAPS, *PMIDIOUTCAPS, NEAR *NPMIDIOUTCAPS, FAR *LPMIDIOUTCAPS;

        /* flags for wTechnology field of MIDIOUTCAPS structure */
        public const int MOD_MIDIPORT  =  1;  /* output port */
        public const int MOD_SYNTH     =  2;  /* generic internal synth */
        public const int MOD_SQSYNTH   =  3;  /* square wave internal synth */
        public const int MOD_FMSYNTH   =  4;  /* FM internal synth */
        public const int MOD_MAPPER    =  5;  /* MIDI mapper */
        public const int MOD_WAVETABLE  = 6;  /* hardware wavetable synth */
        public const int MOD_SWSYNTH    = 7;  /* software synth */

        /* flags for dwSupport field of MIDIOUTCAPS structure */
        public const uint MIDICAPS_VOLUME      =    0x0001;  /* supports volume control */
        public const uint MIDICAPS_LRVOLUME    =    0x0002;  /* separate left-right volume control */
        public const uint MIDICAPS_CACHE       =    0x0004;
        public const uint MIDICAPS_STREAM          = 0x0008;  /* driver supports midiStreamOut directly */

        /* MIDI input device capabilities structure */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIDIINCAPSA {
            public ushort wMid;                   /* manufacturer ID */
            public ushort wPid;                   /* product ID */
            public uint vDriverVersion;         /* version of the driver */
            public string szPname;   /* product name (NULL terminated string) */
            public uint dwSupport;             /* functionality supported by driver */
        };// MIDIINCAPSA, *PMIDIINCAPSA, *NPMIDIINCAPSA, *LPMIDIINCAPSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIDIINCAPSW {
            public ushort wMid;                   /* manufacturer ID */
            public ushort wPid;                   /* product ID */
            public uint vDriverVersion;         /* version of the driver */
            public string szPname;   /* product name (NULL terminated string) */
            public uint dwSupport;             /* functionality supported by driver */
        };// MIDIINCAPSW, *PMIDIINCAPSW, *NPMIDIINCAPSW, *LPMIDIINCAPSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIDIINCAPS2A {
            public ushort wMid;                   /* manufacturer ID */
            public ushort wPid;                   /* product ID */
            public uint vDriverVersion;         /* version of the driver */
            public string szPname;   /* product name (NULL terminated string) */
            public uint dwSupport;              /* functionality supported by driver */
            public string ManufacturerGuid;       /* for extensible MID mapping */
            public string ProductGuid;            /* for extensible PID mapping */
            public string NameGuid;               /* for name lookup in registry */
        };// MIDIINCAPS2A, *PMIDIINCAPS2A, *NPMIDIINCAPS2A, *LPMIDIINCAPS2A;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIDIINCAPS2W {
            public ushort wMid;                   /* manufacturer ID */
            public ushort wPid;                   /* product ID */
            public uint vDriverVersion;         /* version of the driver */
            public string szPname;   /* product name (NULL terminated string) */
            public uint dwSupport;              /* functionality supported by driver */
            public string ManufacturerGuid;       /* for extensible MID mapping */
            public string ProductGuid;            /* for extensible PID mapping */
            public string NameGuid;               /* for name lookup in registry */
        };// MIDIINCAPS2W, *PMIDIINCAPS2W, *NPMIDIINCAPS2W, *LPMIDIINCAPS2W;
        [StructLayout(LayoutKind.Sequential)]
        public struct midiincaps_tag {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;        /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public uint dwSupport;             /* functionality supported by driver */

        };// MIDIINCAPS, *PMIDIINCAPS, NEAR *NPMIDIINCAPS, FAR *LPMIDIINCAPS;


        /* MIDI data block header */
        [StructLayout(LayoutKind.Sequential)]
        public struct midihdr_tag {
            public StringBuilder lpData;               /* pointer to locked data block */
            public uint dwBufferLength;       /* length of data in data block */
            public uint dwBytesRecorded;      /* used for input only */
            public UIntPtr dwUser;               /* for client's use */
            public uint dwFlags;              /* assorted flags (see defines) */
            public object lpNext;   /* reserved for driver */
            public UIntPtr reserved;             /* reserved for driver */
            public uint dwOffset;             /* Callback offset into buffer */
            public UIntPtr[] dwReserved;        /* Reserved for MMSYSTEM */
        };// MIDIHDR, *PMIDIHDR, NEAR *NPMIDIHDR, FAR *LPMIDIHDR;

        [StructLayout(LayoutKind.Sequential)]
        public struct midievent_tag
        {
            public uint dwDeltaTime;          /* Ticks since last event */
            public uint dwStreamID;           /* Reserved; must be zero */
            public uint dwEvent;              /* Event type and parameters */
            public uint[] dwParms;           /* Parameters if this is a long event */
        };// MIDIEVENT;
        [StructLayout(LayoutKind.Sequential)]
        public struct midistrmbuffver_tag
        {
            public uint dwVersion;                  /* Stream buffer format version */
            public uint dwMid;                      /* Manufacturer ID as defined in MMREG.H */
            public uint dwOEMVersion;               /* Manufacturer version for custom ext */
        };// MIDISTRMBUFFVER;

        /* flags for dwFlags field of MIDIHDR structure */
        public const ulong MHDR_DONE      = 0x00000001;       /* done bit */
        public const ulong MHDR_PREPARED  = 0x00000002;       /* set if header prepared */
        public const ulong MHDR_INQUEUE   = 0x00000004;       /* reserved for driver */
        public const ulong MHDR_ISSTRM    = 0x00000008;       /* Buffer is stream buffer */
        /* */
        /* Type codes which go in the high byte of the event uint of a stream buffer */
        /* */
        /* Type codes 00-7F contain parameters within the low 24 bits */
        /* Type codes 80-FF contain a length of their parameter in the low 24 */
        /* bits, followed by their parameter data in the buffer. The event */
        /* uint contains the exact byte length; the parm data itself must be */
        /* padded to be an even multiple of 4 bytes long. */
        /* */

        public const ulong MEVT_F_SHORT        = 0x00000000L;
        public const ulong MEVT_F_LONG         = 0x80000000L;
        public const ulong MEVT_F_CALLBACK     = 0x40000000L;

        public const byte MEVT_SHORTMSG   =    0x00;    /* parm = shortmsg for midiOutShortMsg */
        public const byte MEVT_TEMPO      =    0x01;    /* parm = new tempo in microsec/qn     */
        public const byte MEVT_NOP        =    0x02;    /* parm = unused; does nothing         */

        /* 0x04-0x7F reserved */

        public const byte MEVT_LONGMSG   =     0x80;    /* parm = bytes to send verbatim       */
        public const byte MEVT_COMMENT   =     0x82;    /* parm = comment data                 */
        public const byte MEVT_uint      =  0x84;    /* parm = MIDISTRMBUFFVER public struct       */

        /* 0x81-0xFF reserved */

        public const byte MIDISTRM_ERROR     = unchecked((byte)-2);

        /* */
        /* Structures and defines for midiStreamProperty */
        /* */
        public const ulong MIDIPROP_SET      =  0x80000000L;
        public const ulong MIDIPROP_GET      =  0x40000000L;

        /* These are intentionally both non-zero so the app cannot accidentally */
        /* leave the operation off and happen to appear to work due to default */
        /* action. */

        public const ulong MIDIPROP_TIMEDIV  =  0x00000001L;
        public const ulong MIDIPROP_TEMPO    =  0x00000002L;
        [StructLayout(LayoutKind.Sequential)]
        public struct midiproptimediv_tag
        {
            public uint cbStruct;
            public uint dwTimeDiv;
        };// MIDIPROPTIMEDIV, FAR *LPMIDIPROPTIMEDIV;
        [StructLayout(LayoutKind.Sequential)]
        public struct midiproptempo_tag
        {
            public uint cbStruct;
            public uint dwTempo;
        };// MIDIPROPTEMPO, FAR *LPMIDIPROPTEMPO;

        /****************************************************************************

                                Auxiliary audio support

        ****************************************************************************/

        /* device ID for aux device mapper */
        public const uint AUX_MAPPER   =  unchecked((uint)-1);


        /* Auxiliary audio device capabilities structure */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagAUXCAPSA {
            public ushort wMid;                /* manufacturer ID */
            public ushort wPid;                /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;/* product name (NULL terminated string) */
            public ushort wTechnology;         /* type of device */
            public ushort wReserved1;          /* padding */
            public uint dwSupport;           /* functionality supported by driver */
        };// AUXCAPSA, *PAUXCAPSA, *NPAUXCAPSA, *LPAUXCAPSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagAUXCAPSW {
            public ushort wMid;                /* manufacturer ID */
            public ushort wPid;                /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;/* product name (NULL terminated string) */
            public ushort wTechnology;         /* type of device */
            public ushort wReserved1;          /* padding */
            public uint dwSupport;           /* functionality supported by driver */
        };// AUXCAPSW, *PAUXCAPSW, *NPAUXCAPSW, *LPAUXCAPSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagAUXCAPS2A {
            public ushort wMid;                /* manufacturer ID */
            public ushort wPid;                /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;/* product name (NULL terminated string) */
            public ushort wTechnology;         /* type of device */
            public ushort wReserved1;          /* padding */
            public uint dwSupport;           /* functionality supported by driver */
            public string ManufacturerGuid;    /* for extensible MID mapping */
            public string ProductGuid;         /* for extensible PID mapping */
            public string NameGuid;            /* for name lookup in registry */
        };// AUXCAPS2A, *PAUXCAPS2A, *NPAUXCAPS2A, *LPAUXCAPS2A;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagAUXCAPS2W {
            public ushort wMid;                /* manufacturer ID */
            public ushort wPid;                /* product ID */
            public uint vDriverVersion;      /* version of the driver */
            public string szPname;/* product name (NULL terminated string) */
            public ushort wTechnology;         /* type of device */
            public ushort wReserved1;          /* padding */
            public uint dwSupport;           /* functionality supported by driver */
            public string ManufacturerGuid;    /* for extensible MID mapping */
            public string ProductGuid;         /* for extensible PID mapping */
            public string NameGuid;            /* for name lookup in registry */
        };// AUXCAPS2W, *PAUXCAPS2W, *NPAUXCAPS2W, *LPAUXCAPS2W;

        [StructLayout(LayoutKind.Sequential)]
        public struct auxcaps_tag {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public uint vDriverVersion;        /* version of the driver */
            public string szPname;  /* product name (NULL terminated string) */
            public ushort wTechnology;           /* type of device */
            public uint dwSupport;             /* functionality supported by driver */
        };// AUXCAPS, *PAUXCAPS, NEAR *NPAUXCAPS, FAR *LPAUXCAPS;

        /* flags for wTechnology field in AUXCAPS structure */
        public const uint AUXCAPS_CDAUDIO  =  1;       /* audio from internal CD-ROM drive */
        public const uint AUXCAPS_AUXIN    =  2;       /* audio from auxiliary input jacks */

        /* flags for dwSupport field in AUXCAPS structure */
        public const uint AUXCAPS_VOLUME    =      0x0001;  /* supports volume control */
        public const uint AUXCAPS_LRVOLUME  =      0x0002;  /* separate left-right volume control */

        /****************************************************************************

                                    Mixer Support

        ****************************************************************************/

        public const uint MIXER_SHORT_NAME_CHARS  = 16;
        public const uint MIXER_LONG_NAME_CHARS   = 64;

        /* */
        /*  MMRESULT error return values specific to the mixer API */
        /* */
        /* */
        public const uint MIXERR_INVALLINE      =      (MIXERR_BASE + 0);
        public const uint MIXERR_INVALCONTROL   =      (MIXERR_BASE + 1);
        public const uint MIXERR_INVALVALUE     =      (MIXERR_BASE + 2);
        public const uint MIXERR_LASTERROR      =      (MIXERR_BASE + 2);


        public const ulong MIXER_OBJECTF_HANDLE   = 0x80000000L;
        public const ulong MIXER_OBJECTF_MIXER    = 0x00000000L;
        public const ulong MIXER_OBJECTF_HMIXER   = (MIXER_OBJECTF_HANDLE|MIXER_OBJECTF_MIXER);
        public const ulong MIXER_OBJECTF_WAVEOUT  = 0x10000000L;
        public const ulong MIXER_OBJECTF_HWAVEOUT = (MIXER_OBJECTF_HANDLE|MIXER_OBJECTF_WAVEOUT);
        public const ulong MIXER_OBJECTF_WAVEIN   = 0x20000000L;
        public const ulong MIXER_OBJECTF_HWAVEIN  = (MIXER_OBJECTF_HANDLE|MIXER_OBJECTF_WAVEIN);
        public const ulong MIXER_OBJECTF_MIDIOUT  = 0x30000000L;
        public const ulong MIXER_OBJECTF_HMIDIOUT = (MIXER_OBJECTF_HANDLE|MIXER_OBJECTF_MIDIOUT);
        public const ulong MIXER_OBJECTF_MIDIIN   = 0x40000000L;
        public const ulong MIXER_OBJECTF_HMIDIIN  = (MIXER_OBJECTF_HANDLE|MIXER_OBJECTF_MIDIIN);
        public const ulong MIXER_OBJECTF_AUX      = 0x50000000L;

        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERCAPSA {
            public ushort wMid;                   /* manufacturer id */
            public ushort wPid;                   /* product id */
            public uint vDriverVersion;         /* version of the driver */
            public string szPname;   /* product name */
            public uint fdwSupport;             /* misc. support bits */
            public uint cDestinations;          /* count of destinations */
        };// MIXERCAPSA, *PMIXERCAPSA, *LPMIXERCAPSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERCAPSW {
            public ushort wMid;                   /* manufacturer id */
            public ushort wPid;                   /* product id */
            public uint vDriverVersion;         /* version of the driver */
            public string szPname;   /* product name */
            public uint fdwSupport;             /* misc. support bits */
            public uint cDestinations;          /* count of destinations */
        };// MIXERCAPSW, *PMIXERCAPSW, *LPMIXERCAPSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERCAPS2A {
            public ushort wMid;                   /* manufacturer id */
            public ushort wPid;                   /* product id */
            public uint vDriverVersion;         /* version of the driver */
            public string szPname;   /* product name */
            public uint fdwSupport;             /* misc. support bits */
            public uint cDestinations;          /* count of destinations */
            public string ManufacturerGuid;       /* for extensible MID mapping */
            public string ProductGuid;            /* for extensible PID mapping */
            public string NameGuid;               /* for name lookup in registry */
        };// MIXERCAPS2A, *PMIXERCAPS2A, *LPMIXERCAPS2A;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERCAPS2W {
            public ushort wMid;                   /* manufacturer id */
            public ushort wPid;                   /* product id */
            public uint vDriverVersion;         /* version of the driver */
            public string szPname;   /* product name */
            public uint fdwSupport;             /* misc. support bits */
            public uint cDestinations;          /* count of destinations */
            public string ManufacturerGuid;       /* for extensible MID mapping */
            public string ProductGuid;            /* for extensible PID mapping */
            public string NameGuid;               /* for name lookup in registry */
        };// MIXERCAPS2W, *PMIXERCAPS2W, *LPMIXERCAPS2W;

        [StructLayout(LayoutKind.Sequential)]
        public struct tMIXERCAPS {
            public ushort wMid;                   /* manufacturer id */
            public ushort wPid;                   /* product id */
            public uint vDriverVersion;         /* version of the driver */
            public string szPname;   /* product name */
            public uint fdwSupport;             /* misc. support bits */
            public uint cDestinations;          /* count of destinations */
        };// MIXERCAPS, *PMIXERCAPS, FAR *LPMIXERCAPS;


        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERLINEA {
            public uint cbStruct;               /* size of MIXERLINE structure */
            public uint dwDestination;          /* zero based destination index */
            public uint dwSource;               /* zero based source index (if source) */
            public uint dwLineID;               /* unique line id for mixer device */
            public uint fdwLine;                /* state/information about line */
            public UIntPtr dwUser;                 /* driver specific information */
            public uint dwComponentType;        /* component type line connects to */
            public uint cChannels;              /* number of channels line supports */
            public uint cConnections;           /* number of connections [possible] */
            public uint cControls;              /* number of controls at this line */
            public string szShortName;
            public string szName;
            [StructLayout(LayoutKind.Sequential)]
            public struct Target{
                public uint dwType;                 /* MIXERLINE_TARGETTYPE_xxxx */
                public uint dwDeviceID;             /* target device ID of device type */
                public ushort wMid;                   /* of target device */
                public ushort wPid;                   /*      " */
                public uint vDriverVersion;         /*      " */
                public string szPname;   /*      " */
            };
        };// MIXERLINEA, *PMIXERLINEA, *LPMIXERLINEA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERLINEW {
            public uint cbStruct;               /* size of MIXERLINE structure */
            public uint dwDestination;          /* zero based destination index */
            public uint dwSource;               /* zero based source index (if source) */
            public uint dwLineID;               /* unique line id for mixer device */
            public uint fdwLine;                /* state/information about line */
            public UIntPtr dwUser;                 /* driver specific information */
            public uint dwComponentType;        /* component type line connects to */
            public uint cChannels;              /* number of channels line supports */
            public uint cConnections;           /* number of connections [possible] */
            public uint cControls;              /* number of controls at this line */
            public string szShortName;
            public string szName;
            [StructLayout(LayoutKind.Sequential)]
            public struct Target{
                public uint dwType;                 /* MIXERLINE_TARGETTYPE_xxxx */
                public uint dwDeviceID;             /* target device ID of device type */
                public ushort wMid;                   /* of target device */
                public ushort wPid;                   /*      " */
                public uint vDriverVersion;         /*      " */
                public string szPname;   /*      " */
            };
        };// MIXERLINEW, *PMIXERLINEW, *LPMIXERLINEW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tMIXERLINE {
            public uint cbStruct;               /* size of MIXERLINE structure */
            public uint dwDestination;          /* zero based destination index */
            public uint dwSource;               /* zero based source index (if source) */
            public uint dwLineID;               /* unique line id for mixer device */
            public uint fdwLine;                /* state/information about line */
            public uint dwUser;                 /* driver specific information */
            public uint dwComponentType;        /* component type line connects to */
            public uint cChannels;              /* number of channels line supports */
            public uint cConnections;           /* number of connections [possible] */
            public uint cControls;              /* number of controls at this line */
            public string szShortName;
            public string szName;
            [StructLayout(LayoutKind.Sequential)]
            public struct Target{
                public uint dwType;                 /* MIXERLINE_TARGETTYPE_xxxx */
                public uint dwDeviceID;             /* target device ID of device type */
                public ushort wMid;                   /* of target device */
                public ushort wPid;                   /*      " */
                public uint vDriverVersion;         /*      " */
                public string szPname;   /*      " */
            };
        };// MIXERLINE, *PMIXERLINE, FAR *LPMIXERLINE;

        /* */
        /*  MIXERLINE.fdwLine */
        /* */
        /* */
        public const ulong MIXERLINE_LINEF_ACTIVE         =     0x00000001L;
        public const ulong MIXERLINE_LINEF_DISCONNECTED   =     0x00008000L;
        public const ulong MIXERLINE_LINEF_SOURCE         =     0x80000000L;


        /* */
        /*  MIXERLINE.dwComponentType */
        /* */
        /*  component types for destinations and sources */
        /* */
        /* */
        public const ulong MIXERLINE_COMPONENTTYPE_DST_FIRST       = 0x00000000L;
        public const ulong MIXERLINE_COMPONENTTYPE_DST_UNDEFINED   = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 0);
        public const ulong MIXERLINE_COMPONENTTYPE_DST_DIGITAL     = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 1);
        public const ulong MIXERLINE_COMPONENTTYPE_DST_LINE        = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 2);
        public const ulong MIXERLINE_COMPONENTTYPE_DST_MONITOR     = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 3);
        public const ulong MIXERLINE_COMPONENTTYPE_DST_SPEAKERS    = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 4);
        public const ulong MIXERLINE_COMPONENTTYPE_DST_HEADPHONES  = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 5);
        public const ulong MIXERLINE_COMPONENTTYPE_DST_TELEPHONE   = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 6);
        public const ulong MIXERLINE_COMPONENTTYPE_DST_WAVEIN      = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 7);
        public const ulong MIXERLINE_COMPONENTTYPE_DST_VOICEIN     = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 8);
        public const ulong MIXERLINE_COMPONENTTYPE_DST_LAST        = (MIXERLINE_COMPONENTTYPE_DST_FIRST + 8);

        public const ulong MIXERLINE_COMPONENTTYPE_SRC_FIRST       = 0x00001000L;
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_UNDEFINED   = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 0);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_DIGITAL     = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 1);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_LINE        = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 2);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_MICROPHONE  = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 3);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_SYNTHESIZER = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 4);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_COMPACTDISC = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 5);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_TELEPHONE   = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 6);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_PCSPEAKER   = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 7);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_WAVEOUT     = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 8);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_AUXILIARY   = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 9);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_ANALOG      = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 10);
        public const ulong MIXERLINE_COMPONENTTYPE_SRC_LAST        = (MIXERLINE_COMPONENTTYPE_SRC_FIRST + 10);


        /* */
        /*  MIXERLINE.Target.dwType */
        /* */
        /* */
        public const uint MIXERLINE_TARGETTYPE_UNDEFINED    =  0;
        public const uint MIXERLINE_TARGETTYPE_WAVEOUT      =  1;
        public const uint MIXERLINE_TARGETTYPE_WAVEIN       =  2;
        public const uint MIXERLINE_TARGETTYPE_MIDIOUT      =  3;
        public const uint MIXERLINE_TARGETTYPE_MIDIIN       =  4;
        public const uint MIXERLINE_TARGETTYPE_AUX          =  5;

        public const ulong MIXER_GETLINEINFOF_DESTINATION    =  0x00000000L;
        public const ulong MIXER_GETLINEINFOF_SOURCE         =  0x00000001L;
        public const ulong MIXER_GETLINEINFOF_LINEID         =  0x00000002L;
        public const ulong MIXER_GETLINEINFOF_COMPONENTTYPE  =  0x00000003L;
        public const ulong MIXER_GETLINEINFOF_TARGETTYPE     =  0x00000004L;

        public const ulong MIXER_GETLINEINFOF_QUERYMASK      =  0x0000000FL;

        /* */
        /*  MIXERCONTROL */
        /* */
        /* */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERCONTROLA {
            public uint cbStruct;           /* size in bytes of MIXERCONTROL */
            public uint dwControlID;        /* unique control id for mixer device */
            public uint dwControlType;      /* MIXERCONTROL_CONTROLTYPE_xxx */
            public uint fdwControl;         /* MIXERCONTROL_CONTROLF_xxx */
            public uint cMultipleItems;     /* if MIXERCONTROL_CONTROLF_MULTIPLE set */
            public string szShortName;
            public string szName;
            [StructLayout(LayoutKind.Explicit)]
            struct Bounds{
                public struct Min{
                    public long lMinimum;           /* signed minimum for this control */
                    public long lMaximum;           /* signed maximum for this control */
                };
                public struct Max{
                    public uint dwMinimum;          /* unsigned minimum for this control */
                    public uint dwMaximum;          /* unsigned maximum for this control */
                };
                [FieldOffset(0)] uint[] dwReserved;
            } ;
            [StructLayout(LayoutKind.Explicit)]
            struct Metrics{
                [FieldOffset(0)]
                public uint cSteps;             /* # of steps between min & max */
                [FieldOffset(0)]
                public uint cbCustomData;       /* size in bytes of custom data */
                [FieldOffset(0)]
                public uint[] dwReserved;      /* !!! needed? we have cbStruct.... */
            };
        };// MIXERCONTROLA, *PMIXERCONTROLA, *LPMIXERCONTROLA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERCONTROLW {
            public uint cbStruct;           /* size in bytes of MIXERCONTROL */
            public uint dwControlID;        /* unique control id for mixer device */
            public uint dwControlType;      /* MIXERCONTROL_CONTROLTYPE_xxx */
            public uint fdwControl;         /* MIXERCONTROL_CONTROLF_xxx */
            public uint cMultipleItems;     /* if MIXERCONTROL_CONTROLF_MULTIPLE set */
            public string szShortName;
            public string szName;
            [StructLayout(LayoutKind.Explicit)]
            struct Bounds{
                public struct Min{
                    public long lMinimum;           /* signed minimum for this control */
                    public long lMaximum;           /* signed maximum for this control */
                };
                public struct Max{
                    public uint dwMinimum;          /* unsigned minimum for this control */
                    public uint dwMaximum;          /* unsigned maximum for this control */
                };
                [FieldOffset(0)] uint[] dwReserved;
            } ;
            [StructLayout(LayoutKind.Explicit)]
            struct Metrics{
                [FieldOffset(0)]
                public uint cSteps;             /* # of steps between min & max */
                [FieldOffset(0)]
                public uint cbCustomData;       /* size in bytes of custom data */
                [FieldOffset(0)]
                public uint[] dwReserved;      /* !!! needed? we have cbStruct.... */
            };
        };// MIXERCONTROLW, *PMIXERCONTROLW, *LPMIXERCONTROLW;

        [StructLayout(LayoutKind.Sequential)]
        public struct tMIXERCONTROL {
            public uint cbStruct;           /* size in bytes of MIXERCONTROL */
            public uint dwControlID;        /* unique control id for mixer device */
            public uint dwControlType;      /* MIXERCONTROL_CONTROLTYPE_xxx */
            public uint fdwControl;         /* MIXERCONTROL_CONTROLF_xxx */
            public uint cMultipleItems;     /* if MIXERCONTROL_CONTROLF_MULTIPLE set */
            public string szShortName;
            public string szName;
            [StructLayout(LayoutKind.Explicit)]
            struct Bounds{
                public struct Min{
                    public long lMinimum;           /* signed minimum for this control */
                    public long lMaximum;           /* signed maximum for this control */
                };
                public struct Max{
                    public uint dwMinimum;          /* unsigned minimum for this control */
                    public uint dwMaximum;          /* unsigned maximum for this control */
                };
                [FieldOffset(0)]
                public uint[] dwReserved;
            } ;
            [StructLayout(LayoutKind.Explicit)]
            struct Metrics{
                [FieldOffset(0)]
                public uint cSteps;             /* # of steps between min & max */
                [FieldOffset(0)]
                public uint cbCustomData;       /* size in bytes of custom data */
                [FieldOffset(0)]
                public uint[] dwReserved;      /* !!! needed? we have cbStruct.... */
            };
        };// MIXERCONTROL, *PMIXERCONTROL, FAR *LPMIXERCONTROL;


        /* */
        /*  MIXERCONTROL.fdwControl */
        /* */
        /* */
        public const ulong MIXERCONTROL_CONTROLF_UNIFORM  = 0x00000001L;
        public const ulong MIXERCONTROL_CONTROLF_MULTIPLE = 0x00000002L;
        public const ulong MIXERCONTROL_CONTROLF_DISABLED = 0x80000000L;


        /* */
        /*  MIXERCONTROL_CONTROLTYPE_xxx building block defines */
        /* */
        /* */
        public const ulong MIXERCONTROL_CT_CLASS_MASK         = 0xF0000000L;
        public const ulong MIXERCONTROL_CT_CLASS_CUSTOM       = 0x00000000L;
        public const ulong MIXERCONTROL_CT_CLASS_METER        = 0x10000000L;
        public const ulong MIXERCONTROL_CT_CLASS_SWITCH       = 0x20000000L;
        public const ulong MIXERCONTROL_CT_CLASS_NUMBER       = 0x30000000L;
        public const ulong MIXERCONTROL_CT_CLASS_SLIDER       = 0x40000000L;
        public const ulong MIXERCONTROL_CT_CLASS_FADER        = 0x50000000L;
        public const ulong MIXERCONTROL_CT_CLASS_TIME         = 0x60000000L;
        public const ulong MIXERCONTROL_CT_CLASS_LIST         = 0x70000000L;


        public const ulong MIXERCONTROL_CT_SUBCLASS_MASK      = 0x0F000000L;

        public const ulong MIXERCONTROL_CT_SC_SWITCH_BOOLEAN  = 0x00000000L;
        public const ulong MIXERCONTROL_CT_SC_SWITCH_BUTTON   = 0x01000000L;

        public const ulong MIXERCONTROL_CT_SC_METER_POLLED    = 0x00000000L;
                
        public const ulong MIXERCONTROL_CT_SC_TIME_MICROSECS  = 0x00000000L;
        public const ulong MIXERCONTROL_CT_SC_TIME_MILLISECS  = 0x01000000L;

        public const ulong MIXERCONTROL_CT_SC_LIST_SINGLE     = 0x00000000L;
        public const ulong MIXERCONTROL_CT_SC_LIST_MULTIPLE   = 0x01000000L;


        public const ulong MIXERCONTROL_CT_UNITS_MASK         = 0x00FF0000L;
        public const ulong MIXERCONTROL_CT_UNITS_CUSTOM       = 0x00000000L;
        public const ulong MIXERCONTROL_CT_UNITS_BOOLEAN      = 0x00010000L;
        public const ulong MIXERCONTROL_CT_UNITS_SIGNED       = 0x00020000L;
        public const ulong MIXERCONTROL_CT_UNITS_UNSIGNED     = 0x00030000L;
        public const ulong MIXERCONTROL_CT_UNITS_DECIBELS     = 0x00040000L;/* in 10ths */
        public const ulong MIXERCONTROL_CT_UNITS_PERCENT      = 0x00050000L; /* in 10ths */


        /* */
        /*  Commonly used control types for specifying MIXERCONTROL.dwControlType */
        /* */

        public const ulong MIXERCONTROL_CONTROLTYPE_CUSTOM         = (MIXERCONTROL_CT_CLASS_CUSTOM | MIXERCONTROL_CT_UNITS_CUSTOM);
        public const ulong MIXERCONTROL_CONTROLTYPE_BOOLEANMETER   = (MIXERCONTROL_CT_CLASS_METER | MIXERCONTROL_CT_SC_METER_POLLED | MIXERCONTROL_CT_UNITS_BOOLEAN);
        public const ulong MIXERCONTROL_CONTROLTYPE_SIGNEDMETER    = (MIXERCONTROL_CT_CLASS_METER | MIXERCONTROL_CT_SC_METER_POLLED | MIXERCONTROL_CT_UNITS_SIGNED);
        public const ulong MIXERCONTROL_CONTROLTYPE_PEAKMETER      = (MIXERCONTROL_CONTROLTYPE_SIGNEDMETER + 1);
        public const ulong MIXERCONTROL_CONTROLTYPE_UNSIGNEDMETER  = (MIXERCONTROL_CT_CLASS_METER | MIXERCONTROL_CT_SC_METER_POLLED | MIXERCONTROL_CT_UNITS_UNSIGNED);
        public const ulong MIXERCONTROL_CONTROLTYPE_BOOLEAN        = (MIXERCONTROL_CT_CLASS_SWITCH | MIXERCONTROL_CT_SC_SWITCH_BOOLEAN | MIXERCONTROL_CT_UNITS_BOOLEAN);
        public const ulong MIXERCONTROL_CONTROLTYPE_ONOFF          = (MIXERCONTROL_CONTROLTYPE_BOOLEAN + 1);
        public const ulong MIXERCONTROL_CONTROLTYPE_MUTE           = (MIXERCONTROL_CONTROLTYPE_BOOLEAN + 2);
        public const ulong MIXERCONTROL_CONTROLTYPE_MONO           = (MIXERCONTROL_CONTROLTYPE_BOOLEAN + 3);
        public const ulong MIXERCONTROL_CONTROLTYPE_LOUDNESS       = (MIXERCONTROL_CONTROLTYPE_BOOLEAN + 4);
        public const ulong MIXERCONTROL_CONTROLTYPE_STEREOENH      = (MIXERCONTROL_CONTROLTYPE_BOOLEAN + 5);
        public const ulong MIXERCONTROL_CONTROLTYPE_BASS_BOOST     = (MIXERCONTROL_CONTROLTYPE_BOOLEAN + 0x00002277);
        public const ulong MIXERCONTROL_CONTROLTYPE_BUTTON         = (MIXERCONTROL_CT_CLASS_SWITCH | MIXERCONTROL_CT_SC_SWITCH_BUTTON | MIXERCONTROL_CT_UNITS_BOOLEAN);
        public const ulong MIXERCONTROL_CONTROLTYPE_DECIBELS       = (MIXERCONTROL_CT_CLASS_NUMBER | MIXERCONTROL_CT_UNITS_DECIBELS);
        public const ulong MIXERCONTROL_CONTROLTYPE_SIGNED         = (MIXERCONTROL_CT_CLASS_NUMBER | MIXERCONTROL_CT_UNITS_SIGNED);
        public const ulong MIXERCONTROL_CONTROLTYPE_UNSIGNED       = (MIXERCONTROL_CT_CLASS_NUMBER | MIXERCONTROL_CT_UNITS_UNSIGNED);
        public const ulong MIXERCONTROL_CONTROLTYPE_PERCENT        = (MIXERCONTROL_CT_CLASS_NUMBER | MIXERCONTROL_CT_UNITS_PERCENT);
        public const ulong MIXERCONTROL_CONTROLTYPE_SLIDER         = (MIXERCONTROL_CT_CLASS_SLIDER | MIXERCONTROL_CT_UNITS_SIGNED);
        public const ulong MIXERCONTROL_CONTROLTYPE_PAN            = (MIXERCONTROL_CONTROLTYPE_SLIDER + 1);
        public const ulong MIXERCONTROL_CONTROLTYPE_QSOUNDPAN      = (MIXERCONTROL_CONTROLTYPE_SLIDER + 2);
        public const ulong MIXERCONTROL_CONTROLTYPE_FADER          = (MIXERCONTROL_CT_CLASS_FADER | MIXERCONTROL_CT_UNITS_UNSIGNED);
        public const ulong MIXERCONTROL_CONTROLTYPE_VOLUME         = (MIXERCONTROL_CONTROLTYPE_FADER + 1);
        public const ulong MIXERCONTROL_CONTROLTYPE_BASS           = (MIXERCONTROL_CONTROLTYPE_FADER + 2);
        public const ulong MIXERCONTROL_CONTROLTYPE_TREBLE         = (MIXERCONTROL_CONTROLTYPE_FADER + 3);
        public const ulong MIXERCONTROL_CONTROLTYPE_EQUALIZER      = (MIXERCONTROL_CONTROLTYPE_FADER + 4);
        public const ulong MIXERCONTROL_CONTROLTYPE_SINGLESELECT   = (MIXERCONTROL_CT_CLASS_LIST | MIXERCONTROL_CT_SC_LIST_SINGLE | MIXERCONTROL_CT_UNITS_BOOLEAN);
        public const ulong MIXERCONTROL_CONTROLTYPE_MUX            = (MIXERCONTROL_CONTROLTYPE_SINGLESELECT + 1);
        public const ulong MIXERCONTROL_CONTROLTYPE_MULTIPLESELECT = (MIXERCONTROL_CT_CLASS_LIST | MIXERCONTROL_CT_SC_LIST_MULTIPLE | MIXERCONTROL_CT_UNITS_BOOLEAN);
        public const ulong MIXERCONTROL_CONTROLTYPE_MIXER          = (MIXERCONTROL_CONTROLTYPE_MULTIPLESELECT + 1);
        public const ulong MIXERCONTROL_CONTROLTYPE_MICROTIME      = (MIXERCONTROL_CT_CLASS_TIME | MIXERCONTROL_CT_SC_TIME_MICROSECS | MIXERCONTROL_CT_UNITS_UNSIGNED);
        public const ulong MIXERCONTROL_CONTROLTYPE_MILLITIME      = (MIXERCONTROL_CT_CLASS_TIME | MIXERCONTROL_CT_SC_TIME_MILLISECS | MIXERCONTROL_CT_UNITS_UNSIGNED);

        /* */
        /*  MIXERLINECONTROLS */
        /* */

        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERLINECONTROLSA {
            public uint cbStruct;       /* size in bytes of MIXERLINECONTROLS */
            public uint dwLineID;       /* line id (from MIXERLINE.dwLineID) */
            [StructLayout(LayoutKind.Explicit)]
            public struct Info
            {
                [FieldOffset(0)]
                public uint dwControlID;    /* MIXER_GETLINECONTROLSF_ONEBYID */
                [FieldOffset(0)]
                public uint dwControlType;  /* MIXER_GETLINECONTROLSF_ONEBYTYPE */
            };
            public uint cControls;      /* count of controls pmxctrl points to */
            public uint cbmxctrl;       /* size in bytes of _one_ MIXERCONTROL */
            tagMIXERCONTROLA pamxctrl;       /* pointer to first MIXERCONTROL array */
        };// MIXERLINECONTROLSA, *PMIXERLINECONTROLSA, *LPMIXERLINECONTROLSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERLINECONTROLSW {
            public uint cbStruct;       /* size in bytes of MIXERLINECONTROLS */
            public uint dwLineID;       /* line id (from MIXERLINE.dwLineID) */
            [StructLayout(LayoutKind.Explicit)]
            public struct Info
            {
                [FieldOffset(0)]
                public uint dwControlID;    /* MIXER_GETLINECONTROLSF_ONEBYID */
                [FieldOffset(0)]
                public uint dwControlType;  /* MIXER_GETLINECONTROLSF_ONEBYTYPE */
            };
            public uint cControls;      /* count of controls pmxctrl points to */
            public uint cbmxctrl;       /* size in bytes of _one_ MIXERCONTROL */
            tagMIXERCONTROLW pamxctrl;       /* pointer to first MIXERCONTROL array */
        };// MIXERLINECONTROLSW, *PMIXERLINECONTROLSW, *LPMIXERLINECONTROLSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tMIXERLINECONTROLS {
            public uint cbStruct;       /* size in bytes of MIXERLINECONTROLS */
            public uint dwLineID;       /* line id (from MIXERLINE.dwLineID) */
            [StructLayout(LayoutKind.Explicit)]
            public struct Info
            {
                [FieldOffset(0)]
                public uint dwControlID;    /* MIXER_GETLINECONTROLSF_ONEBYID */
                [FieldOffset(0)]
                public uint dwControlType;  /* MIXER_GETLINECONTROLSF_ONEBYTYPE */
            };
            public uint cControls;      /* count of controls pmxctrl points to */
            public uint cbmxctrl;       /* size in bytes of _one_ MIXERCONTROL */
            public tMIXERCONTROL pamxctrl;       /* pointer to first MIXERCONTROL array */
        };// MIXERLINECONTROLS, *PMIXERLINECONTROLS, FAR *LPMIXERLINECONTROLS;

        public const ulong MIXER_GETLINECONTROLSF_ALL         = 0x00000000L;
        public const ulong MIXER_GETLINECONTROLSF_ONEBYID     = 0x00000001L;
        public const ulong MIXER_GETLINECONTROLSF_ONEBYTYPE   = 0x00000002L;

        public const ulong MIXER_GETLINECONTROLSF_QUERYMASK   = 0x0000000FL;

        [StructLayout(LayoutKind.Sequential)]
        public struct tMIXERCONTROLDETAILS {
            public uint cbStruct;       /* size in bytes of MIXERCONTROLDETAILS */
            public uint dwControlID;    /* control id to get/set details on */
            public uint cChannels;      /* number of channels in paDetails array */
            [StructLayout(LayoutKind.Explicit)]
            struct Details{
                [FieldOffset(0)]
                public object hwndOwner;      /* for MIXER_SETCONTROLDETAILSF_CUSTOM */
                [FieldOffset(0)]
                public uint cMultipleItems; /* if _MULTIPLE, the number of items per channel */
            };
            public uint cbDetails;      /* size of _one_ details_XX public struct */
            public object paDetails;      /* pointer to array of details_XX structs */
        };// MIXERCONTROLDETAILS, *PMIXERCONTROLDETAILS, FAR *LPMIXERCONTROLDETAILS;


        /* */
        /*  MIXER_GETCONTROLDETAILSF_LISTTEXT */
        /* */
        /* */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERCONTROLDETAILS_LISTTEXTA {
            public uint dwParam1;
            public uint dwParam2;
            public string szName;
        };// MIXERCONTROLDETAILS_LISTTEXTA, *PMIXERCONTROLDETAILS_LISTTEXTA, *LPMIXERCONTROLDETAILS_LISTTEXTA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMIXERCONTROLDETAILS_LISTTEXTW {
            public uint dwParam1;
            public uint dwParam2;
            public string szName;
        };// MIXERCONTROLDETAILS_LISTTEXTW, *PMIXERCONTROLDETAILS_LISTTEXTW, *LPMIXERCONTROLDETAILS_LISTTEXTW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tMIXERCONTROLDETAILS_LISTTEXT {
            public uint dwParam1;
            public uint dwParam2;
            public string szName;
        };// MIXERCONTROLDETAILS_LISTTEXT, *PMIXERCONTROLDETAILS_LISTTEXT, FAR *LPMIXERCONTROLDETAILS_LISTTEXT;

        /* */
        /*  MIXER_GETCONTROLDETAILSF_VALUE */
        /* */
        /* */
        [StructLayout(LayoutKind.Sequential)]
        public struct tMIXERCONTROLDETAILS_BOOLEAN {
            public long fValue;
        };//       MIXERCONTROLDETAILS_BOOLEAN,*PMIXERCONTROLDETAILS_BOOLEAN,FAR *LPMIXERCONTROLDETAILS_BOOLEAN;
        [StructLayout(LayoutKind.Sequential)]
        public struct tMIXERCONTROLDETAILS_SIGNED {
            public long lValue;
        };//MIXERCONTROLDETAILS_SIGNED, *PMIXERCONTROLDETAILS_SIGNED,FAR *LPMIXERCONTROLDETAILS_SIGNED;

        [StructLayout(LayoutKind.Sequential)]
        public struct tMIXERCONTROLDETAILS_UNSIGNED {
            public uint dwValue;
        };//MIXERCONTROLDETAILS_UNSIGNED, *PMIXERCONTROLDETAILS_UNSIGNED, FAR *LPMIXERCONTROLDETAILS_UNSIGNED;

        public const ulong MIXER_GETCONTROLDETAILSF_VALUE      = 0x00000000L;
        public const ulong MIXER_GETCONTROLDETAILSF_LISTTEXT   = 0x00000001L;

        public const ulong MIXER_GETCONTROLDETAILSF_QUERYMASK  = 0x0000000FL;

        public const ulong MIXER_SETCONTROLDETAILSF_VALUE  =     0x00000000L;
        public const ulong MIXER_SETCONTROLDETAILSF_CUSTOM  =   0x00000001L;

        public const ulong MIXER_SETCONTROLDETAILSF_QUERYMASK = 0x0000000FL;

        /****************************************************************************

                                    Timer support

        ****************************************************************************/

        /* timer error return values */
        public const uint TIMERR_NOERROR      =  (0);                  /* no error */
        public const uint TIMERR_NOCANDO      =  (TIMERR_BASE+1);      /* request not completed */
        public const uint TIMERR_STRUCT       =  (TIMERR_BASE+33);     /* time public struct size */

        /* flags for fuEvent parameter of timeSetEvent() function */
        public const uint TIME_ONESHOT   =  0x0000;   /* program timer for single event */
        public const uint TIME_PERIODIC  =  0x0001;   /* program for continuous periodic event */

        public const uint TIME_CALLBACK_FUNCTION    =  0x0000;  /* callback is function */
        public const uint TIME_CALLBACK_EVENT_SET   =  0x0010;  /* callback is event - use SetEvent */
        public const uint TIME_CALLBACK_EVENT_PULSE =  0x0020;  /* callback is event - use PulseEvent */

        public const uint TIME_KILL_SYNCHRONOUS   = 0x0100;  /* This flag prevents the event from occurring */
                                                /* after the user calls timeKillEvent() to */
                                                /* destroy it. */

        /* timer device capabilities data structure */
        [StructLayout(LayoutKind.Sequential)]
        public struct timecaps_tag {
            public uint wPeriodMin;     /* minimum period supported  */
            public uint wPeriodMax;     /* maximum period supported  */
        };// TIMECAPS, *PTIMECAPS, NEAR *NPTIMECAPS, FAR *LPTIMECAPS;

        /****************************************************************************

                                    Joystick support

        ****************************************************************************/

        /* joystick error return values */
        public const uint JOYERR_NOERROR      =  (0);                  /* no error */
        public const uint JOYERR_PARMS        =  (JOYERR_BASE+5);      /* bad parameters */
        public const uint JOYERR_NOCANDO      =  (JOYERR_BASE+6);      /* request not completed */
        public const uint JOYERR_UNPLUGGED    =  (JOYERR_BASE+7);      /* joystick is unplugged */

        /* constants used with JOYINFO and JOYINFOEX structures and MM_JOY* messages */
        public const uint JOY_BUTTON1         = 0x0001;
        public const uint JOY_BUTTON2       =  0x0002;
        public const uint JOY_BUTTON3       =   0x0004;
        public const uint JOY_BUTTON4       =   0x0008;
        public const uint JOY_BUTTON1CHG    =  0x0100;
        public const uint JOY_BUTTON2CHG    =  0x0200;
        public const uint JOY_BUTTON3CHG    =  0x0400;
        public const uint JOY_BUTTON4CHG    =  0x0800;

        /* constants used with JOYINFOEX */
        public const ulong JOY_BUTTON5       =  0x00000010L;
        public const ulong JOY_BUTTON6       =  0x00000020L;
        public const ulong JOY_BUTTON7       =  0x00000040L;
        public const ulong JOY_BUTTON8       =  0x00000080L;
        public const ulong JOY_BUTTON9       =  0x00000100L;
        public const ulong JOY_BUTTON10      =  0x00000200L;
        public const ulong JOY_BUTTON11      =  0x00000400L;
        public const ulong JOY_BUTTON12      =  0x00000800L;
        public const ulong JOY_BUTTON13      =  0x00001000L;
        public const ulong JOY_BUTTON14      =  0x00002000L;
        public const ulong JOY_BUTTON15      =  0x00004000L;
        public const ulong JOY_BUTTON16      =  0x00008000L;
        public const ulong JOY_BUTTON17      =  0x00010000L;
        public const ulong JOY_BUTTON18      =  0x00020000L;
        public const ulong JOY_BUTTON19      =  0x00040000L;
        public const ulong JOY_BUTTON20      =  0x00080000L;
        public const ulong JOY_BUTTON21      =  0x00100000L;
        public const ulong JOY_BUTTON22      =  0x00200000L;
        public const ulong JOY_BUTTON23      =  0x00400000L;
        public const ulong JOY_BUTTON24      = 0x00800000L;
        public const ulong JOY_BUTTON25      = 0x01000000L;
        public const ulong JOY_BUTTON26      =  0x02000000L;
        public const ulong JOY_BUTTON27      =  0x04000000L;
        public const ulong JOY_BUTTON28      =  0x08000000L;
        public const ulong JOY_BUTTON29      =  0x10000000L;
        public const ulong JOY_BUTTON30      =  0x20000000L;
        public const ulong JOY_BUTTON31      =  0x40000000L;
        public const ulong JOY_BUTTON32      =  0x80000000L;
        /* co;nstants used with JOYINFOEX structure */
        public const uint JOY_POVCENTERED    =    unchecked((uint)-1);
        public const uint JOY_POVFORWARD     =     0;
        public const uint JOY_POVRIGHT       =     9000;
        public const uint JOY_POVBACKWARD    =     18000;
        public const uint JOY_POVLEFT        =     27000;

        public const ulong JOY_RETURNX       =      0x00000001L;
        public const ulong JOY_RETURNY       =      0x00000002L;
        public const ulong JOY_RETURNZ       =      0x00000004L;
        public const ulong JOY_RETURNR       =      0x00000008L;
        public const ulong JOY_RETURNU       =      0x00000010L;    /* axis 5 */
        public const ulong JOY_RETURNV       =      0x00000020L;     /* axis 6 */
        public const ulong JOY_RETURNPOV     =      0x00000040L;
        public const ulong JOY_RETURNBUTTONS  =     0x00000080L;
        public const ulong JOY_RETURNRAWDATA  =     0x00000100L;
        public const ulong JOY_RETURNPOVCTS   =     0x00000200L;
        public const ulong JOY_RETURNCENTERED  =    0x00000400L;
        public const ulong JOY_USEDEADZONE     =    0x00000800L;
        public const ulong JOY_RETURNALL       =    (JOY_RETURNX | JOY_RETURNY | JOY_RETURNZ | JOY_RETURNR | JOY_RETURNU | JOY_RETURNV | JOY_RETURNPOV | JOY_RETURNBUTTONS);
        public const ulong JOY_CAL_READALWAYS   =   0x00010000L;
        public const ulong JOY_CAL_READXYONLY   =   0x00020000L;
        public const ulong JOY_CAL_READ3        =   0x00040000L;
        public const ulong JOY_CAL_READ4        =   0x00080000L;
        public const ulong JOY_CAL_READXONLY    =   0x00100000L;
        public const ulong JOY_CAL_READYONLY    =   0x00200000L;
        public const ulong JOY_CAL_READ5        =   0x00400000L;
        public const ulong JOY_CAL_READ6        =   0x00800000L;
        public const ulong JOY_CAL_READZONLY    =  0x01000000L;
        public const ulong JOY_CAL_READRONLY    =   0x02000000L;
        public const ulong JOY_CAL_READUONLY    =   0x04000000L;
        public const ulong JOY_CAL_READVONLY    =   0x08000000L;

        /* joystick ID constants */
        public const uint JOYSTICKID1     =    0;
        public const uint JOYSTICKID2     =    1;

        /* joystick driver capabilites */
        public const uint JOYCAPS_HASZ     =       0x0001;
        public const uint JOYCAPS_HASR     =       0x0002;
        public const uint JOYCAPS_HASU     =       0x0004;
        public const uint JOYCAPS_HASV     =       0x0008;
        public const uint JOYCAPS_HASPOV   =       0x0010;
        public const uint JOYCAPS_POV4DIR   =      0x0020;
        public const uint JOYCAPS_POVCTS    =      0x0040;



        /* joystick device capabilities data structure */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagJOYCAPSA {
            public ushort wMid;                /* manufacturer ID */
            public ushort wPid;                /* product ID */
            public string szPname;/* product name (NULL terminated string) */
            public uint wXmin;               /* minimum x position value */
            public uint wXmax;               /* maximum x position value */
            public uint wYmin;               /* minimum y position value */
            public uint wYmax;               /* maximum y position value */
            public uint wZmin;               /* minimum z position value */
            public uint wZmax;               /* maximum z position value */
            public uint wNumButtons;         /* number of buttons */
            public uint wPeriodMin;          /* minimum message period when captured */
            public uint wPeriodMax;          /* maximum message period when captured */
            public uint wRmin;               /* minimum r position value */
            public uint wRmax;               /* maximum r position value */
            public uint wUmin;               /* minimum u (5th axis) position value */
            public uint wUmax;               /* maximum u (5th axis) position value */
            public uint wVmin;               /* minimum v (6th axis) position value */
            public uint wVmax;               /* maximum v (6th axis) position value */
            public uint wCaps;               /* joystick capabilites */
            public uint wMaxAxes;            /* maximum number of axes supported */
            public uint wNumAxes;            /* number of axes in use */
            public uint wMaxButtons;         /* maximum number of buttons supported */
            public string szRegKey;/* registry key */
            public string szOEMVxD; /* OEM VxD in use */

        };// JOYCAPSA, *PJOYCAPSA, *NPJOYCAPSA, *LPJOYCAPSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagJOYCAPSW {
            public ushort wMid;                /* manufacturer ID */
            public ushort wPid;                /* product ID */
            public string szPname;/* product name (NULL terminated string) */
            public uint wXmin;               /* minimum x position value */
            public uint wXmax;               /* maximum x position value */
            public uint wYmin;               /* minimum y position value */
            public uint wYmax;               /* maximum y position value */
            public uint wZmin;               /* minimum z position value */
            public uint wZmax;               /* maximum z position value */
            public uint wNumButtons;         /* number of buttons */
            public uint wPeriodMin;          /* minimum message period when captured */
            public uint wPeriodMax;          /* maximum message period when captured */
            public uint wRmin;               /* minimum r position value */
            public uint wRmax;               /* maximum r position value */
            public uint wUmin;               /* minimum u (5th axis) position value */
            public uint wUmax;               /* maximum u (5th axis) position value */
            public uint wVmin;               /* minimum v (6th axis) position value */
            public uint wVmax;               /* maximum v (6th axis) position value */
            public uint wCaps;               /* joystick capabilites */
            public uint wMaxAxes;            /* maximum number of axes supported */
            public uint wNumAxes;            /* number of axes in use */
            public uint wMaxButtons;         /* maximum number of buttons supported */
            public string szRegKey;/* registry key */
            public string szOEMVxD; /* OEM VxD in use */
        };// JOYCAPSW, *PJOYCAPSW, *NPJOYCAPSW, *LPJOYCAPSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagJOYCAPS2A {
            public ushort wMid;                /* manufacturer ID */
            public ushort wPid;                /* product ID */
            public string szPname;/* product name (NULL terminated string) */
            public uint wXmin;               /* minimum x position value */
            public uint wXmax;               /* maximum x position value */
            public uint wYmin;               /* minimum y position value */
            public uint wYmax;               /* maximum y position value */
            public uint wZmin;               /* minimum z position value */
            public uint wZmax;               /* maximum z position value */
            public uint wNumButtons;         /* number of buttons */
            public uint wPeriodMin;          /* minimum message period when captured */
            public uint wPeriodMax;          /* maximum message period when captured */
            public uint wRmin;               /* minimum r position value */
            public uint wRmax;               /* maximum r position value */
            public uint wUmin;               /* minimum u (5th axis) position value */
            public uint wUmax;               /* maximum u (5th axis) position value */
            public uint wVmin;               /* minimum v (6th axis) position value */
            public uint wVmax;               /* maximum v (6th axis) position value */
            public uint wCaps;               /* joystick capabilites */
            public uint wMaxAxes;            /* maximum number of axes supported */
            public uint wNumAxes;            /* number of axes in use */
            public uint wMaxButtons;         /* maximum number of buttons supported */
            public string szRegKey;/* registry key */
            public string szOEMVxD; /* OEM VxD in use */
            public string ManufacturerGuid;    /* for extensible MID mapping */
            public string ProductGuid;         /* for extensible PID mapping */
            public string NameGuid;            /* for name lookup in registry */
        };// JOYCAPS2A, *PJOYCAPS2A, *NPJOYCAPS2A, *LPJOYCAPS2A;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagJOYCAPS2W {
            public ushort wMid;                /* manufacturer ID */
            public ushort wPid;                /* product ID */
            public string szPname;/* product name (NULL terminated string) */
            public uint wXmin;               /* minimum x position value */
            public uint wXmax;               /* maximum x position value */
            public uint wYmin;               /* minimum y position value */
            public uint wYmax;               /* maximum y position value */
            public uint wZmin;               /* minimum z position value */
            public uint wZmax;               /* maximum z position value */
            public uint wNumButtons;         /* number of buttons */
            public uint wPeriodMin;          /* minimum message period when captured */
            public uint wPeriodMax;          /* maximum message period when captured */
            public uint wRmin;               /* minimum r position value */
            public uint wRmax;               /* maximum r position value */
            public uint wUmin;               /* minimum u (5th axis) position value */
            public uint wUmax;               /* maximum u (5th axis) position value */
            public uint wVmin;               /* minimum v (6th axis) position value */
            public uint wVmax;               /* maximum v (6th axis) position value */
            public uint wCaps;               /* joystick capabilites */
            public uint wMaxAxes;            /* maximum number of axes supported */
            public uint wNumAxes;            /* number of axes in use */
            public uint wMaxButtons;         /* maximum number of buttons supported */
            public string szRegKey;/* registry key */
            public string szOEMVxD; /* OEM VxD in use */
            public string ManufacturerGuid;    /* for extensible MID mapping */
            public string ProductGuid;         /* for extensible PID mapping */
            public string NameGuid;            /* for name lookup in registry */
        };// JOYCAPS2W, *PJOYCAPS2W, *NPJOYCAPS2W, *LPJOYCAPS2W;
        [StructLayout(LayoutKind.Sequential)]
        public struct joycaps_tag {
            public ushort wMid;                  /* manufacturer ID */
            public ushort wPid;                  /* product ID */
            public string szPname;  /* product name (NULL terminated string) */
            public uint wXmin;                 /* minimum x position value */
            public uint wXmax;                 /* maximum x position value */
            public uint wYmin;                 /* minimum y position value */
            public uint wYmax;                 /* maximum y position value */
            public uint wZmin;                 /* minimum z position value */
            public uint wZmax;                 /* maximum z position value */
            public uint wNumButtons;           /* number of buttons */
            public uint wPeriodMin;            /* minimum message period when captured */
            public uint wPeriodMax;            /* maximum message period when captured */
            public uint wRmin;                 /* minimum r position value */
            public uint wRmax;                 /* maximum r position value */
            public uint wUmin;                 /* minimum u (5th axis) position value */
            public uint wUmax;                 /* maximum u (5th axis) position value */
            public uint wVmin;                 /* minimum v (6th axis) position value */
            public uint wVmax;                 /* maximum v (6th axis) position value */
            public uint wCaps;                 /* joystick capabilites */
            public uint wMaxAxes;              /* maximum number of axes supported */
            public uint wNumAxes;              /* number of axes in use */
            public uint wMaxButtons;           /* maximum number of buttons supported */
            public string szRegKey; /* registry key */
            public string szOEMVxD; /* OEM VxD in use */
        };// JOYCAPS, *PJOYCAPS, NEAR *NPJOYCAPS, FAR *LPJOYCAPS;



        /* joystick information data structure */
        [StructLayout(LayoutKind.Sequential)]
        public struct joyinfo_tag {
            public uint wXpos;                 /* x position */
            public uint wYpos;                 /* y position */
            public uint wZpos;                 /* z position */
            public uint wButtons;              /* button states */
        };// JOYINFO, *PJOYINFO, NEAR *NPJOYINFO, FAR *LPJOYINFO;

        [StructLayout(LayoutKind.Sequential)]
        public struct joyinfoex_tag {
            public uint dwSize;                /* size of structure */
            public uint dwFlags;               /* flags to indicate what to return */
            public uint dwXpos;                /* x position */
            public uint dwYpos;                /* y position */
            public uint dwZpos;                /* z position */
            public uint dwRpos;                /* rudder/4th axis position */
            public uint dwUpos;                /* 5th axis position */
            public uint dwVpos;                /* 6th axis position */
            public uint dwButtons;             /* button states */
            public uint dwButtonNumber;        /* current button number pressed */
            public uint dwPOV;                 /* point of view state */
            public uint dwReserved1;           /* reserved for communication between winmm & driver */
            public uint dwReserved2;           /* reserved for future expansion */
        };// JOYINFOEX, *PJOYINFOEX, NEAR *NPJOYINFOEX, FAR *LPJOYINFOEX;


        /****************************************************************************

                                Multimedia File I/O support

        ****************************************************************************/

        /* MMIO error return values */
        public const uint MMIOERR_BASE              =  256;
        public const uint MMIOERR_FILENOTFOUND      =  (MMIOERR_BASE + 1);  /* file not found */
        public const uint MMIOERR_OUTOFMEMORY       =  (MMIOERR_BASE + 2);  /* out of memory */
        public const uint MMIOERR_CANNOTOPEN        =  (MMIOERR_BASE + 3);  /* cannot open */
        public const uint MMIOERR_CANNOTCLOSE       =  (MMIOERR_BASE + 4);  /* cannot close */
        public const uint MMIOERR_CANNOTREAD        =  (MMIOERR_BASE + 5);  /* cannot read */
        public const uint MMIOERR_CANNOTWRITE       =  (MMIOERR_BASE + 6);  /* cannot write */
        public const uint MMIOERR_CANNOTSEEK        =  (MMIOERR_BASE + 7);  /* cannot seek */
        public const uint MMIOERR_CANNOTEXPAND      =  (MMIOERR_BASE + 8);  /* cannot expand file */
        public const uint MMIOERR_CHUNKNOTFOUND     =  (MMIOERR_BASE + 9);  /* chunk not found */
        public const uint MMIOERR_UNBUFFERED        =  (MMIOERR_BASE + 10); /*  */
        public const uint MMIOERR_PATHNOTFOUND      =  (MMIOERR_BASE + 11); /* path incorrect */
        public const uint MMIOERR_ACCESSDENIED      =  (MMIOERR_BASE + 12); /* file was protected */
        public const uint MMIOERR_SHARINGVIOLATION  =  (MMIOERR_BASE + 13); /* file in use */
        public const uint MMIOERR_NETWORKERROR      =  (MMIOERR_BASE + 14); /* network not responding */
        public const uint MMIOERR_TOOMANYOPENFILES  =  (MMIOERR_BASE + 15); /* no more file handles  */
        public const uint MMIOERR_INVALIDFILE       =  (MMIOERR_BASE + 16); /* default error file error */

        /* MMIO constants */
        public const string CFSEPstring   =    "+";             /* compound file name separator string. */

        /* general MMIO information data structure */
        [StructLayout(LayoutKind.Sequential)]
        public struct _MMIOINFO
        {
                /* general fields */
            public uint dwFlags;        /* general status flags */
            public uint fccIOProc;      /* pointer to I/O procedure */
               public  object pIOProc;        /* pointer to I/O procedure */
               public  uint            wErrorRet;      /* place for error to be returned */
               public long htask;          /* alternate local task */

                /* fields maintained by MMIO functions during buffered I/O */
               public long cchBuffer;      /* size of I/O buffer (or 0L) */
               public string pchBuffer;      /* start of I/O buffer (or NULL) */
               public string pchNext;        /* pointer to next byte to read/write */
               public string pchEndRead;     /* pointer to last valid byte to read */
               public string pchEndWrite;    /* pointer to last byte to write */
               public long lBufOffset;     /* disk offset of start of buffer */

                /* fields maintained by I/O procedure */
               public long lDiskOffset;    /* disk offset of next read or write */
               public uint[] adwInfo;     /* data specific to type of MMIOPROC */

                /* other fields maintained by MMIO */
               public uint dwReserved1;    /* reserved for MMIO use */
               public uint dwReserved2;    /* reserved for MMIO use */
               public uint hmmio;          /* handle to open file */
        };// MMIOINFO, *PMMIOINFO, NEAR *NPMMIOINFO, FAR *LPMMIOINFO;
        [StructLayout(LayoutKind.Sequential)]
        public struct _MMCKINFO
        {
            public uint ckid;           /* chunk ID */
            public uint cksize;         /* chunk size */
            public uint fccType;        /* form type or list type */
            public uint dwDataOffset;   /* offset of data portion of chunk */
            public uint dwFlags;        /* flags used by MMIO functions */
        };// MMCKINFO, *PMMCKINFO, NEAR *NPMMCKINFO, FAR *LPMMCKINFO;

        /* bit field masks */
        public const ulong MMIO_RWMODE    = 0x00000003;      /* open file for reading/writing/both */
        public const ulong MMIO_SHAREMODE = 0x00000070;      /* file sharing mode number */

        /* constants for dwFlags field of MMIOINFO */
        public const ulong MMIO_CREATE    = 0x00001000;      /* create new file (or truncate file) */
        public const ulong MMIO_PARSE     = 0x00000100;      /* parse new file returning path */
        public const ulong MMIO_DELETE    = 0x00000200;      /* create new file (or truncate file) */
        public const ulong MMIO_EXIST     = 0x00004000;      /* checks for existence of file */
        public const ulong MMIO_ALLOCBUF  = 0x00010000;      /* mmioOpen() should allocate a buffer */
        public const ulong MMIO_GETTEMP   = 0x00020000;      /* mmioOpen() should retrieve temp name */

        public const ulong MMIO_DIRTY     = 0x10000000;      /* I/O buffer is dirty */


        /* read/write mode numbers (bit field MMIO_RWMODE) */
        public const ulong MMIO_READ      = 0x00000000;      /* open file for reading only */
        public const ulong MMIO_WRITE     = 0x00000001;      /* open file for writing only */
        public const ulong MMIO_READWRITE = 0x00000002;      /* open file for reading and writing */

        /* share mode numbers (bit field MMIO_SHAREMODE) */
        public const ulong MMIO_COMPAT    = 0x00000000;      /* compatibility mode */
        public const ulong MMIO_EXCLUSIVE = 0x00000010;      /* exclusive-access mode */
        public const ulong MMIO_DENYWRITE = 0x00000020;      /* deny writing to other processes */
        public const ulong MMIO_DENYREAD  = 0x00000030;      /* deny reading to other processes */
        public const ulong MMIO_DENYNONE  = 0x00000040;      /* deny nothing to other processes */

        /* various MMIO flags */
        public const uint MMIO_FHOPEN           =  0x0010;  /* mmioClose: keep file handle open */
        public const uint MMIO_EMPTYBUF         =  0x0010;  /* mmioFlush: empty the I/O buffer */
        public const uint MMIO_TOUPPER          =  0x0010;  /* mmioStringToFOURCC: to u-case */
        public const ulong MMIO_INSTALLPROC  =  0x00010000;  /* mmioInstallIOProc: install MMIOProc */
        public const ulong MMIO_GLOBALPROC   =  0x10000000;  /* mmioInstallIOProc: install globally */
        public const ulong MMIO_REMOVEPROC   =  0x00020000;  /* mmioInstallIOProc: remove MMIOProc */
        public const ulong MMIO_UNICODEPROC  =  0x01000000;  /* mmioInstallIOProc: Unicode MMIOProc */
        public const ulong MMIO_FINDPROC     =  0x00040000;  /* mmioInstallIOProc: find an MMIOProc */
        public const uint MMIO_FINDCHUNK         = 0x0010;  /* mmioDescend: find a chunk by ID */
        public const uint MMIO_FINDRIFF         =  0x0020;  /* mmioDescend: find a LIST chunk */
        public const uint MMIO_FINDLIST         =  0x0040;  /* mmioDescend: find a RIFF chunk */
        public const uint MMIO_CREATERIFF       =  0x0020;  /* mmioCreateChunk: make a LIST chunk */
        public const uint MMIO_CREATELIST       =  0x0040;  /* mmioCreateChunk: make a RIFF chunk */


        /* message numbers for MMIOPROC I/O procedure functions */
        public const ulong MMIOM_READ    =  MMIO_READ;       /* read */
        public const ulong MMIOM_WRITE   = MMIO_WRITE;       /* write */
        public const uint MMIOM_SEEK    =          2;      /* seek to a new position in file */
        public const uint MMIOM_OPEN    =          3;       /* open file */
        public const uint MMIOM_CLOSE   =          4;       /* close file */
        public const uint MMIOM_WRITEFLUSH   =     5;       /* write and flush */

        public const uint MMIOM_RENAME       =     6;       /* rename specified file */

        public const uint MMIOM_USER       =  0x8000;       /* beginning of user-defined messages */

        /* flags for mmioSeek() */
        public const uint SEEK_SET      =  0;               /* seek to an absolute position */
        public const uint SEEK_CUR      =  1;               /* seek relative to current position */
        public const uint SEEK_END      =  2;               /* seek relative to end of file */

        /* other constants */
        public const uint MMIO_DEFAULTBUFFER  =    8192;    /* default buffer size */

        /****************************************************************************

                                    MCI support

        ****************************************************************************/

        /* MCI error return values */
        public const uint MCIERR_INVALID_DEVICE_ID    =    (MCIERR_BASE + 1);
        public const uint MCIERR_UNRECOGNIZED_KEYushort =  (MCIERR_BASE + 3);
        public const uint MCIERR_UNRECOGNIZED_COMMAND   =  (MCIERR_BASE + 5);
        public const uint MCIERR_HARDWARE               =  (MCIERR_BASE + 6);
        public const uint MCIERR_INVALID_DEVICE_NAME    =  (MCIERR_BASE + 7);
        public const uint MCIERR_OUT_OF_MEMORY          =  (MCIERR_BASE + 8);
        public const uint MCIERR_DEVICE_OPEN            =  (MCIERR_BASE + 9);
        public const uint MCIERR_CANNOT_LOAD_DRIVER     =  (MCIERR_BASE + 10);
        public const uint MCIERR_MISSING_COMMAND_STRING =  (MCIERR_BASE + 11);
        public const uint MCIERR_PARAM_OVERFLOW         =  (MCIERR_BASE + 12);
        public const uint MCIERR_MISSING_STRING_ARGUMENT = (MCIERR_BASE + 13);
        public const uint MCIERR_BAD_INTEGER             = (MCIERR_BASE + 14);
        public const uint MCIERR_PARSER_INTERNAL         = (MCIERR_BASE + 15);
        public const uint MCIERR_DRIVER_INTERNAL         = (MCIERR_BASE + 16);
        public const uint MCIERR_MISSING_PARAMETER       = (MCIERR_BASE + 17);
        public const uint MCIERR_UNSUPPORTED_FUNCTION    = (MCIERR_BASE + 18);
        public const uint MCIERR_FILE_NOT_FOUND          = (MCIERR_BASE + 19);
        public const uint MCIERR_DEVICE_NOT_READY        = (MCIERR_BASE + 20);
        public const uint MCIERR_INTERNAL                = (MCIERR_BASE + 21);
        public const uint MCIERR_DRIVER                  = (MCIERR_BASE + 22);
        public const uint MCIERR_CANNOT_USE_ALL          = (MCIERR_BASE + 23);
        public const uint MCIERR_MULTIPLE                = (MCIERR_BASE + 24);
        public const uint MCIERR_EXTENSION_NOT_FOUND     = (MCIERR_BASE + 25);
        public const uint MCIERR_OUTOFRANGE              = (MCIERR_BASE + 26);
        public const uint MCIERR_FLAGS_NOT_COMPATIBLE    = (MCIERR_BASE + 28);
        public const uint MCIERR_FILE_NOT_SAVED          = (MCIERR_BASE + 30);
        public const uint MCIERR_DEVICE_TYPE_REQUIRED    = (MCIERR_BASE + 31);
        public const uint MCIERR_DEVICE_LOCKED           = (MCIERR_BASE + 32);
        public const uint MCIERR_DUPLICATE_ALIAS         = (MCIERR_BASE + 33);
        public const uint MCIERR_BAD_CONSTANT            = (MCIERR_BASE + 34);
        public const uint MCIERR_MUST_USE_SHAREABLE      = (MCIERR_BASE + 35);
        public const uint MCIERR_MISSING_DEVICE_NAME     = (MCIERR_BASE + 36);
        public const uint MCIERR_BAD_TIME_FORMAT         = (MCIERR_BASE + 37);
        public const uint MCIERR_NO_CLOSING_QUOTE        = (MCIERR_BASE + 38);
        public const uint MCIERR_DUPLICATE_FLAGS         = (MCIERR_BASE + 39);
        public const uint MCIERR_INVALID_FILE            = (MCIERR_BASE + 40);
        public const uint MCIERR_NULL_PARAMETER_BLOCK    = (MCIERR_BASE + 41);
        public const uint MCIERR_UNNAMED_RESOURCE        = (MCIERR_BASE + 42);
        public const uint MCIERR_NEW_REQUIRES_ALIAS      = (MCIERR_BASE + 43);
        public const uint MCIERR_NOTIFY_ON_AUTO_OPEN     = (MCIERR_BASE + 44);
        public const uint MCIERR_NO_ELEMENT_ALLOWED      = (MCIERR_BASE + 45);
        public const uint MCIERR_NONAPPLICABLE_FUNCTION  = (MCIERR_BASE + 46);
        public const uint MCIERR_ILLEGAL_FOR_AUTO_OPEN   = (MCIERR_BASE + 47);
        public const uint MCIERR_FILENAME_REQUIRED       = (MCIERR_BASE + 48);
        public const uint MCIERR_EXTRA_stringACTERS      =   (MCIERR_BASE + 49);
        public const uint MCIERR_DEVICE_NOT_INSTALLED    = (MCIERR_BASE + 50);
        public const uint MCIERR_GET_CD                  = (MCIERR_BASE + 51);
        public const uint MCIERR_SET_CD                  = (MCIERR_BASE + 52);
        public const uint MCIERR_SET_DRIVE               = (MCIERR_BASE + 53);
        public const uint MCIERR_DEVICE_LENGTH           = (MCIERR_BASE + 54);
        public const uint MCIERR_DEVICE_ORD_LENGTH       = (MCIERR_BASE + 55);
        public const uint MCIERR_NO_INTEGER              = (MCIERR_BASE + 56);
                
        public const uint MCIERR_WAVE_OUTPUTSINUSE       = (MCIERR_BASE + 64);
        public const uint MCIERR_WAVE_SETOUTPUTINUSE     = (MCIERR_BASE + 65);
        public const uint MCIERR_WAVE_INPUTSINUSE        = (MCIERR_BASE + 66);
        public const uint MCIERR_WAVE_SETINPUTINUSE      = (MCIERR_BASE + 67);
        public const uint MCIERR_WAVE_OUTPUTUNSPECIFIED  = (MCIERR_BASE + 68);
        public const uint MCIERR_WAVE_INPUTUNSPECIFIED   = (MCIERR_BASE + 69);
        public const uint MCIERR_WAVE_OUTPUTSUNSUITABLE  = (MCIERR_BASE + 70);
        public const uint MCIERR_WAVE_SETOUTPUTUNSUITABLE = (MCIERR_BASE + 71);
        public const uint MCIERR_WAVE_INPUTSUNSUITABLE    = (MCIERR_BASE + 72);
        public const uint MCIERR_WAVE_SETINPUTUNSUITABLE = (MCIERR_BASE + 73);
                
        public const uint MCIERR_SEQ_DIV_INCOMPATIBLE    = (MCIERR_BASE + 80);
        public const uint MCIERR_SEQ_PORT_INUSE          = (MCIERR_BASE + 81);
        public const uint MCIERR_SEQ_PORT_NONEXISTENT    = (MCIERR_BASE + 82);
        public const uint MCIERR_SEQ_PORT_MAPNODEVICE    = (MCIERR_BASE + 83);
        public const uint MCIERR_SEQ_PORT_MISCERROR      = (MCIERR_BASE + 84);
        public const uint MCIERR_SEQ_TIMER               = (MCIERR_BASE + 85);
        public const uint MCIERR_SEQ_PORTUNSPECIFIED     = (MCIERR_BASE + 86);
        public const uint MCIERR_SEQ_NOMIDIPRESENT       = (MCIERR_BASE + 87);

        public const uint MCIERR_NO_WINDOW               = (MCIERR_BASE + 90);
        public const uint MCIERR_CREATEWINDOW            = (MCIERR_BASE + 91);
        public const uint MCIERR_FILE_READ               = (MCIERR_BASE + 92);
        public const uint MCIERR_FILE_WRITE              = (MCIERR_BASE + 93);
                
        public const uint MCIERR_NO_IDENTITY            =  (MCIERR_BASE + 94);

        /* all custom device driver errors must be >= than this value */
        public const uint MCIERR_CUSTOM_DRIVER_BASE     =  (MCIERR_BASE + 256);

        public const uint MCI_FIRST                     =  DRV_MCI_FIRST;   /* 0x0800 */
        /* MCI command message identifiers */
        public const uint MCI_OPEN        =                0x0803;
        public const uint MCI_CLOSE       =                0x0804;
        public const uint MCI_ESCAPE      =                0x0805;
        public const uint MCI_PLAY        =                0x0806;
        public const uint MCI_SEEK        =                0x0807;
        public const uint MCI_STOP        =                0x0808;
        public const uint MCI_PAUSE       =                0x0809;
        public const uint MCI_INFO        =                0x080A;
        public const uint MCI_GETDEVCAPS  =                0x080B;
        public const uint MCI_SPIN        =                0x080C;
        public const uint MCI_SET         =                0x080D;
        public const uint MCI_STEP        =                0x080E;
        public const uint MCI_RECORD      =                0x080F;
        public const uint MCI_SYSINFO     =                0x0810;
        public const uint MCI_BREAK       =                0x0811;
        public const uint MCI_SAVE        =                0x0813;
        public const uint MCI_STATUS      =                0x0814;
        public const uint MCI_CUE         =                0x0830;
        public const uint MCI_REALIZE     =                0x0840;
        public const uint MCI_WINDOW      =                0x0841;
        public const uint MCI_PUT         =                0x0842;
        public const uint MCI_WHERE       =                0x0843;
        public const uint MCI_FREEZE      =                0x0844;
        public const uint MCI_UNFREEZE    =                0x0845;
        public const uint MCI_LOAD        =                0x0850;
        public const uint MCI_CUT         =                0x0851;
        public const uint MCI_COPY        =                0x0852;
        public const uint MCI_PASTE       =                0x0853;
        public const uint MCI_UPDATE      =                0x0854;
        public const uint MCI_RESUME      =                0x0855;
        public const uint MCI_DELETE      =                0x0856;


        /* all custom MCI command messages must be >= than this value */
        public const uint MCI_USER_MESSAGES  =            (DRV_MCI_FIRST + 0x400);
        public const uint MCI_LAST           =             0x0FFF;


        /* device ID for "all devices" */
        public const uint MCI_ALL_DEVICE_ID = unchecked((uint)-1);

        /* constants for predefined MCI device types */
        public const uint MCI_DEVTYPE_VCR        =         513; /* (MCI_STRING_OFFSET + 1) */
        public const uint MCI_DEVTYPE_VIDEODISC  =         514; /* (MCI_STRING_OFFSET + 2) */
        public const uint MCI_DEVTYPE_OVERLAY    =         515; /* (MCI_STRING_OFFSET + 3) */
        public const uint MCI_DEVTYPE_CD_AUDIO   =         516; /* (MCI_STRING_OFFSET + 4) */
        public const uint MCI_DEVTYPE_DAT        =         517; /* (MCI_STRING_OFFSET + 5) */
        public const uint MCI_DEVTYPE_SCANNER    =         518; /* (MCI_STRING_OFFSET + 6) */
        public const uint MCI_DEVTYPE_ANIMATION  =         519; /* (MCI_STRING_OFFSET + 7) */
        public const uint MCI_DEVTYPE_DIGITAL_VIDEO  =     520; /* (MCI_STRING_OFFSET + 8) */
        public const uint MCI_DEVTYPE_OTHER          =     521; /* (MCI_STRING_OFFSET + 9) */
        public const uint MCI_DEVTYPE_WAVEFORM_AUDIO  =    522; /* (MCI_STRING_OFFSET + 10) */
        public const uint MCI_DEVTYPE_SEQUENCER       =    523; /* (MCI_STRING_OFFSET + 11) */

        public const uint MCI_DEVTYPE_FIRST        =       MCI_DEVTYPE_VCR;
        public const uint MCI_DEVTYPE_LAST         =       MCI_DEVTYPE_SEQUENCER;

        public const uint MCI_DEVTYPE_FIRST_USER    =      0x1000;
        
        /* return values for 'status mode' command */
        public const uint MCI_MODE_NOT_READY    =          (MCI_STRING_OFFSET + 12);
        public const uint MCI_MODE_STOP         =          (MCI_STRING_OFFSET + 13);
        public const uint MCI_MODE_PLAY         =          (MCI_STRING_OFFSET + 14);
        public const uint MCI_MODE_RECORD       =          (MCI_STRING_OFFSET + 15);
        public const uint MCI_MODE_SEEK         =          (MCI_STRING_OFFSET + 16);
        public const uint MCI_MODE_PAUSE        =          (MCI_STRING_OFFSET + 17);
        public const uint MCI_MODE_OPEN         =          (MCI_STRING_OFFSET + 18);

        /* constants used in 'set time format' and 'status time format' commands */
        public const uint MCI_FORMAT_MILLISECONDS    =     0;
        public const uint MCI_FORMAT_HMS             =     1;
        public const uint MCI_FORMAT_MSF             =     2;
        public const uint MCI_FORMAT_FRAMES          =     3;
        public const uint MCI_FORMAT_SMPTE_24        =     4;
        public const uint MCI_FORMAT_SMPTE_25        =     5;
        public const uint MCI_FORMAT_SMPTE_30        =     6;
        public const uint MCI_FORMAT_SMPTE_30DROP    =     7;
        public const uint MCI_FORMAT_byteS           =     8;
        public const uint MCI_FORMAT_SAMPLES         =     9;
        public const uint MCI_FORMAT_TMSF            =     10;

        /* flags for wParam of MM_MCINOTIFY message */
        public const uint MCI_NOTIFY_SUCCESSFUL     =      0x0001;
        public const uint MCI_NOTIFY_SUPERSEDED     =      0x0002;
        public const uint MCI_NOTIFY_ABORTED        =      0x0004;
        public const uint MCI_NOTIFY_FAILURE        =      0x0008;


        /* common flags for dwFlags parameter of MCI command messages */
        public const long MCI_NOTIFY          =            0x00000001L;
        public const long MCI_WAIT            =            0x00000002L;
        public const long MCI_FROM            =            0x00000004L;
        public const long MCI_TO              =            0x00000008L;
        public const long MCI_TRACK           =            0x00000010L;

        /* flags for dwFlags parameter of MCI_OPEN command message */
        public const long MCI_OPEN_SHAREABLE   =           0x00000100L;
        public const long MCI_OPEN_ELEMENT     =           0x00000200L;
        public const long MCI_OPEN_ALIAS       =           0x00000400L;
        public const long MCI_OPEN_ELEMENT_ID  =           0x00000800L;
        public const long MCI_OPEN_TYPE_ID     =           0x00001000L;
        public const long MCI_OPEN_TYPE        =           0x00002000L;

        /* flags for dwFlags parameter of MCI_SEEK command message */
        public const long MCI_SEEK_TO_START    =           0x00000100L;
        public const long MCI_SEEK_TO_END      =           0x00000200L;

        /* flags for dwFlags parameter of MCI_STATUS command message */
        public const long MCI_STATUS_ITEM      =           0x00000100L;
        public const long MCI_STATUS_START     =           0x00000200L;

        /* flags for dwItem field of the MCI_STATUS_PARMS parameter block */
        public const long MCI_STATUS_LENGTH     =          0x00000001L;
        public const long MCI_STATUS_POSITION    =         0x00000002L;
        public const long MCI_STATUS_NUMBER_OF_TRACKS   =  0x00000003L;
        public const long MCI_STATUS_MODE              =   0x00000004L;
        public const long MCI_STATUS_MEDIA_PRESENT     =   0x00000005L;
        public const long MCI_STATUS_TIME_FORMAT       =   0x00000006L;
        public const long MCI_STATUS_READY             =   0x00000007L;
        public const long MCI_STATUS_CURRENT_TRACK     =   0x00000008L;

        /* flags for dwFlags parameter of MCI_INFO command message */
        public const long MCI_INFO_PRODUCT               = 0x00000100L;
        public const long MCI_INFO_FILE                  = 0x00000200L;
        public const long MCI_INFO_MEDIA_UPC             = 0x00000400L;
        public const long MCI_INFO_MEDIA_IDENTITY        = 0x00000800L;
        public const long MCI_INFO_NAME                  = 0x00001000L;
        public const long MCI_INFO_COPYRIGHT             = 0x00002000L;

        /* flags for dwFlags parameter of MCI_GETDEVCAPS command message */
        public const long MCI_GETDEVCAPS_ITEM            = 0x00000100L;

        /* flags for dwItem field of the MCI_GETDEVCAPS_PARMS parameter block */
        public const long MCI_GETDEVCAPS_CAN_RECORD      = 0x00000001L;
        public const long MCI_GETDEVCAPS_HAS_AUDIO       = 0x00000002L;
        public const long MCI_GETDEVCAPS_HAS_VIDEO       = 0x00000003L;
        public const long MCI_GETDEVCAPS_DEVICE_TYPE     = 0x00000004L;
        public const long MCI_GETDEVCAPS_USES_FILES      = 0x00000005L;
        public const long MCI_GETDEVCAPS_COMPOUND_DEVICE = 0x00000006L;
        public const long MCI_GETDEVCAPS_CAN_EJECT      =  0x00000007L;
        public const long MCI_GETDEVCAPS_CAN_PLAY       =  0x00000008L;
        public const long MCI_GETDEVCAPS_CAN_SAVE       =  0x00000009L;

        /* flags for dwFlags parameter of MCI_SYSINFO command message */
        public const long MCI_SYSINFO_QUANTITY     =       0x00000100L;
        public const long MCI_SYSINFO_OPEN         =       0x00000200L;
        public const long MCI_SYSINFO_NAME         =       0x00000400L;
        public const long MCI_SYSINFO_INSTALLNAME  =       0x00000800L;

        /* flags for dwFlags parameter of MCI_SET command message */
        public const long MCI_SET_DOOR_OPEN         =      0x00000100L;
        public const long MCI_SET_DOOR_CLOSED       =      0x00000200L;
        public const long MCI_SET_TIME_FORMAT       =      0x00000400L;
        public const long MCI_SET_AUDIO             =      0x00000800L;
        public const long MCI_SET_VIDEO             =      0x00001000L;
        public const long MCI_SET_ON                =      0x00002000L;
        public const long MCI_SET_OFF               =      0x00004000L;

        /* flags for dwAudio field of MCI_SET_PARMS or MCI_SEQ_SET_PARMS */
        public const long MCI_SET_AUDIO_ALL         =      0x00000000L;
        public const long MCI_SET_AUDIO_LEFT        =      0x00000001L;
        public const long MCI_SET_AUDIO_RIGHT       =      0x00000002L;

        /* flags for dwFlags parameter of MCI_BREAK command message */
        public const long MCI_BREAK_KEY             =      0x00000100L;
        public const long MCI_BREAK_HWND            =      0x00000200L;
        public const long MCI_BREAK_OFF             =      0x00000400L;

        /* flags for dwFlags parameter of MCI_RECORD command message */
        public const long MCI_RECORD_INSERT         =      0x00000100L;
        public const long MCI_RECORD_OVERWRITE      =      0x00000200L;

        /* flags for dwFlags parameter of MCI_SAVE command message */
        public const long MCI_SAVE_FILE             =      0x00000100L;

        /* flags for dwFlags parameter of MCI_LOAD command message */
        public const long MCI_LOAD_FILE = 0x00000100L;


        /* generic parameter block for MCI command messages with no special parameters */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_GENERIC_PARMS {
            public UInt64   dwCallback;
        };// MCI_GENERIC_PARMS, *PMCI_GENERIC_PARMS, FAR *LPMCI_GENERIC_PARMS;


        /* parameter block for MCI_OPEN command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OPEN_PARMSA {
            public UInt64   dwCallback;
            public uint wDeviceID;
            public StringBuilder     lpstrDeviceType;
            public StringBuilder     lpstrElementName;
            public StringBuilder     lpstrAlias;
        };// MCI_OPEN_PARMSA, *PMCI_OPEN_PARMSA, *LPMCI_OPEN_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OPEN_PARMSW {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
        };// MCI_OPEN_PARMSW, *PMCI_OPEN_PARMSW, *LPMCI_OPEN_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OPEN_PARMS {
            public object dwCallback;
            public uint wDeviceID;
            public ushort wReserved0;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
        };// MCI_OPEN_PARMS, FAR *LPMCI_OPEN_PARMS;

        [StructLayout(LayoutKind.Sequential)]
        public struct MCI_OPEN_PARMS
        {
            public object dwCallback;
            public uint wDeviceID;
            public ushort wReserved0;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
        };// MCI_OPEN_PARMS, FAR *LPMCI_OPEN_PARMS;

        public delegate object mciCallBack(object mciParams);
        /* parameter block for MCI_PLAY command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_PLAY_PARMS {
            public mciCallBack dwCallback;
            public int dwFrom;
            public int dwTo;
        };// MCI_PLAY_PARMS, *PMCI_PLAY_PARMS, FAR *LPMCI_PLAY_PARMS;

        
        /* parameter block for MCI_SEEK command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_SEEK_PARMS {
            public UInt64 dwCallback;
            public uint dwTo;
        };// MCI_SEEK_PARMS, *PMCI_SEEK_PARMS, FAR *LPMCI_SEEK_PARMS;


        /* parameter block for MCI_STATUS command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_STATUS_PARMS {
            public UInt64 dwCallback;
            public UInt64 dwReturn;
            public uint dwItem;
            public uint dwTrack;
        };// MCI_STATUS_PARMS, *PMCI_STATUS_PARMS, FAR * LPMCI_STATUS_PARMS;


        /* parameter block for MCI_INFO command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_INFO_PARMSA {
            public UInt64 dwCallback;
            public StringBuilder lpstrReturn;
            public uint dwRetSize;
        }; //MCI_INFO_PARMSA, * LPMCI_INFO_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_INFO_PARMSW {
            public UInt64 dwCallback;
            public StringBuilder lpstrReturn;
            public uint dwRetSize;
        }; //MCI_INFO_PARMSW, * LPMCI_INFO_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_INFO_PARMS {
            public UInt64 dwCallback;
            public StringBuilder lpstrReturn;
            public uint dwRetSize;
        };// MCI_INFO_PARMS, FAR * LPMCI_INFO_PARMS;

        /* parameter block for MCI_GETDEVCAPS command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_GETDEVCAPS_PARMS {
            public UInt64 dwCallback;
            public uint dwReturn;
            public uint dwItem;
        };// MCI_GETDEVCAPS_PARMS, *PMCI_GETDEVCAPS_PARMS, FAR * LPMCI_GETDEVCAPS_PARMS;


        /* parameter block for MCI_SYSINFO command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_SYSINFO_PARMSA {
            public UInt64 dwCallback;
            public StringBuilder lpstrReturn;
            public uint dwRetSize;
            public uint dwNumber;
            public uint wDeviceType;
        };// MCI_SYSINFO_PARMSA, *PMCI_SYSINFO_PARMSA, * LPMCI_SYSINFO_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_SYSINFO_PARMSW {
            public UInt64 dwCallback;
            public StringBuilder lpstrReturn;
            public uint dwRetSize;
            public uint dwNumber;
            public uint wDeviceType;
        };// MCI_SYSINFO_PARMSW, *PMCI_SYSINFO_PARMSW, * LPMCI_SYSINFO_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_SYSINFO_PARMS {
            public UInt64 dwCallback;
            public StringBuilder lpstrReturn;
            public uint dwRetSize;
            public uint dwNumber;
            public ushort wDeviceType;
            public ushort wReserved0;
        };// MCI_SYSINFO_PARMS, FAR * LPMCI_SYSINFO_PARMS;

        /* parameter block for MCI_SET command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_SET_PARMS {
            public UInt64 dwCallback;
            public uint dwTimeFormat;
            public uint dwAudio;
        };// MCI_SET_PARMS, *PMCI_SET_PARMS, FAR *LPMCI_SET_PARMS;

        /* parameter block for MCI_BREAK command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_BREAK_PARMS {
            public UInt64 dwCallback;
            public int nVirtKey;
            public object hwndBreak;
        };// MCI_BREAK_PARMS, *PMCI_BREAK_PARMS, FAR * LPMCI_BREAK_PARMS;


        /* parameter block for MCI_SAVE command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_SAVE_PARMSA {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
        };// MCI_SAVE_PARMSA, *PMCI_SAVE_PARMSA, * LPMCI_SAVE_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_SAVE_PARMSW {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
        };// MCI_SAVE_PARMSW, *PMCI_SAVE_PARMSW, * LPMCI_SAVE_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_SAVE_PARMS {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
        };// MCI_SAVE_PARMS, FAR * LPMCI_SAVE_PARMS;
        /* parameter block for MCI_LOAD command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_LOAD_PARMSA {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
        };// MCI_LOAD_PARMSA, *PMCI_LOAD_PARMSA, * LPMCI_LOAD_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_LOAD_PARMSW {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
        };// MCI_LOAD_PARMSW, *PMCI_LOAD_PARMSW, * LPMCI_LOAD_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_LOAD_PARMS {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
        };// MCI_LOAD_PARMS, FAR * LPMCI_LOAD_PARMS;

        /* parameter block for MCI_RECORD command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_RECORD_PARMS {
            public UInt64 dwCallback;
            public uint dwFrom;
            public uint dwTo;
        };// MCI_RECORD_PARMS, FAR *LPMCI_RECORD_PARMS;


        /* MCI extensions for videodisc devices */

        /* flag for dwReturn field of MCI_STATUS_PARMS */
        /* MCI_STATUS command, (dwItem == MCI_STATUS_MODE) */
        public const uint MCI_VD_MODE_PARK          =      (MCI_VD_OFFSET + 1);

        /* flag for dwReturn field of MCI_STATUS_PARMS */
        /* MCI_STATUS command, (dwItem == MCI_VD_STATUS_MEDIA_TYPE) */
        public const uint MCI_VD_MEDIA_CLV           =     (MCI_VD_OFFSET + 2);
        public const uint MCI_VD_MEDIA_CAV           =     (MCI_VD_OFFSET + 3);
        public const uint MCI_VD_MEDIA_OTHER         =    (MCI_VD_OFFSET + 4);

        public const uint MCI_VD_FORMAT_TRACK        =     0x4001;

        /* flags for dwFlags parameter of MCI_PLAY command message */
        public const ulong MCI_VD_PLAY_REVERSE       =      0x00010000L;
        public const ulong MCI_VD_PLAY_FAST          =      0x00020000L;
        public const ulong MCI_VD_PLAY_SPEED         =      0x00040000L;
        public const ulong MCI_VD_PLAY_SCAN          =      0x00080000L;
        public const ulong MCI_VD_PLAY_SLOW          =      0x00100000L;

        /* flag for dwFlags parameter of MCI_SEEK command message */
        public const ulong MCI_VD_SEEK_REVERSE       =      0x00010000L;

        /* flags for dwItem field of MCI_STATUS_PARMS parameter block */
        public const ulong MCI_VD_STATUS_SPEED        =     0x00004002L;
        public const ulong MCI_VD_STATUS_FORWARD      =    0x00004003L;
        public const ulong MCI_VD_STATUS_MEDIA_TYPE   =     0x00004004L;
        public const ulong MCI_VD_STATUS_SIDE         =     0x00004005L;
        public const ulong MCI_VD_STATUS_DISC_SIZE    =     0x00004006L;

        /* flags for dwFlags parameter of MCI_GETDEVCAPS command message */
        public const ulong MCI_VD_GETDEVCAPS_CLV      =     0x00010000L;
        public const ulong MCI_VD_GETDEVCAPS_CAV      =     0x00020000L;

        public const ulong MCI_VD_SPIN_UP             =     0x00010000L;
        public const ulong MCI_VD_SPIN_DOWN           =     0x00020000L;

        /* flags for dwItem field of MCI_GETDEVCAPS_PARMS parameter block */
        public const ulong MCI_VD_GETDEVCAPS_CAN_REVERSE  = 0x00004002L;
        public const ulong MCI_VD_GETDEVCAPS_FAST_RATE    = 0x00004003L;
        public const ulong MCI_VD_GETDEVCAPS_SLOW_RATE    = 0x00004004L;
        public const ulong MCI_VD_GETDEVCAPS_NORMAL_RATE  = 0x00004005L;

        /* flags for the dwFlags parameter of MCI_STEP command message */
        public const ulong MCI_VD_STEP_FRAMES            =  0x00010000L;
        public const ulong MCI_VD_STEP_REVERSE           =  0x00020000L;

        /* flag for the MCI_ESCAPE command message */
        public const ulong MCI_VD_ESCAPE_STRING          =  0x00000100L;


        /* parameter block for MCI_PLAY command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_VD_PLAY_PARMS {
            public UInt64 dwCallback;
            public uint dwFrom;
            public uint dwTo;
            public uint dwSpeed;
        };// MCI_VD_PLAY_PARMS, *PMCI_VD_PLAY_PARMS, FAR *LPMCI_VD_PLAY_PARMS;


        /* parameter block for MCI_STEP command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_VD_STEP_PARMS {
            public UInt64 dwCallback;
            public uint dwFrames;
        };// MCI_VD_STEP_PARMS, *PMCI_VD_STEP_PARMS, FAR *LPMCI_VD_STEP_PARMS;


        /* parameter block for MCI_ESCAPE command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_VD_ESCAPE_PARMSA {
            public UInt64 dwCallback;
            public StringBuilder lpstrCommand;
        };// MCI_VD_ESCAPE_PARMSA, *PMCI_VD_ESCAPE_PARMSA, *LPMCI_VD_ESCAPE_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_VD_ESCAPE_PARMSW {
            public UInt64 dwCallback;
            public StringBuilder lpstrCommand;
        };// MCI_VD_ESCAPE_PARMSW, *PMCI_VD_ESCAPE_PARMSW, *LPMCI_VD_ESCAPE_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_VD_ESCAPE_PARMS {
            public UInt64 dwCallback;
            public StringBuilder lpstrCommand;
        };// MCI_VD_ESCAPE_PARMS, FAR *LPMCI_VD_ESCAPE_PARMS;

        /* MCI extensions for CD audio devices */

        /* flags for the dwItem field of the MCI_STATUS_PARMS parameter block */
        public const ulong MCI_CDA_STATUS_TYPE_TRACK   =    0x00004001L;

        /* flags for the dwReturn field of MCI_STATUS_PARMS parameter block */
        /* MCI_STATUS command, (dwItem == MCI_CDA_STATUS_TYPE_TRACK) */
        public const uint MCI_CDA_TRACK_AUDIO        =     (MCI_CD_OFFSET + 0);
        public const uint MCI_CDA_TRACK_OTHER        =     (MCI_CD_OFFSET + 1);

        /* MCI extensions for waveform audio devices */

        public const uint MCI_WAVE_PCM             =       (MCI_WAVE_OFFSET + 0);
        public const uint MCI_WAVE_MAPPER          =       (MCI_WAVE_OFFSET + 1);

        /* flags for the dwFlags parameter of MCI_OPEN command message */
        public const ulong MCI_WAVE_OPEN_BUFFER         =   0x00010000L;

        /* flags for the dwFlags parameter of MCI_SET command message */
        public const ulong MCI_WAVE_SET_FORMATTAG       =   0x00010000L;
        public const ulong MCI_WAVE_SET_CHANNELS        =   0x00020000L;
        public const ulong MCI_WAVE_SET_SAMPLESPERSEC   =   0x00040000L;
        public const ulong MCI_WAVE_SET_AVGbyteSPERSEC  =   0x00080000L;
        public const ulong MCI_WAVE_SET_BLOCKALIGN      =   0x00100000L;
        public const ulong MCI_WAVE_SET_BITSPERSAMPLE   =   0x00200000L;

        /* flags for the dwFlags parameter of MCI_STATUS, MCI_SET command messages */
        public const ulong MCI_WAVE_INPUT               =   0x00400000L;
        public const ulong MCI_WAVE_OUTPUT              =   0x00800000L;

        /* flags for the dwItem field of MCI_STATUS_PARMS parameter block */
        public const ulong MCI_WAVE_STATUS_FORMATTAG    =   0x00004001L;
        public const ulong MCI_WAVE_STATUS_CHANNELS     =   0x00004002L;
        public const ulong MCI_WAVE_STATUS_SAMPLESPERSEC =  0x00004003L;
        public const ulong MCI_WAVE_STATUS_AVGbyteSPERSEC = 0x00004004L;
        public const ulong MCI_WAVE_STATUS_BLOCKALIGN     = 0x00004005L;
        public const ulong MCI_WAVE_STATUS_BITSPERSAMPLE  = 0x00004006L;
        public const ulong MCI_WAVE_STATUS_LEVEL          = 0x00004007L;

        /* flags for the dwFlags parameter of MCI_SET command message */
        public const ulong MCI_WAVE_SET_ANYINPUT         =  0x04000000L;
        public const ulong MCI_WAVE_SET_ANYOUTPUT        =  0x08000000L;

        /* flags for the dwFlags parameter of MCI_GETDEVCAPS command message */
        public const ulong MCI_WAVE_GETDEVCAPS_INPUTS    =  0x00004001L;
        public const ulong MCI_WAVE_GETDEVCAPS_OUTPUTS   =  0x00004002L;


        /* parameter block for MCI_OPEN command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_WAVE_OPEN_PARMSA {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
            public uint dwBufferSeconds;
        };// MCI_WAVE_OPEN_PARMSA, *PMCI_WAVE_OPEN_PARMSA, *LPMCI_WAVE_OPEN_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_WAVE_OPEN_PARMSW {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
            public uint dwBufferSeconds;
        };// MCI_WAVE_OPEN_PARMSW, *PMCI_WAVE_OPEN_PARMSW, *LPMCI_WAVE_OPEN_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_WAVE_OPEN_PARMS {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public ushort wReserved0;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
            public uint dwBufferSeconds;
        };// MCI_WAVE_OPEN_PARMS, FAR *LPMCI_WAVE_OPEN_PARMS;

        /* parameter block for MCI_DELETE command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_WAVE_DELETE_PARMS {
            public UInt64 dwCallback;
            public uint dwFrom;
            public uint dwTo;
        };// MCI_WAVE_DELETE_PARMS, *PMCI_WAVE_DELETE_PARMS, FAR *LPMCI_WAVE_DELETE_PARMS;


        /* parameter block for MCI_SET command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_WAVE_SET_PARMS {
            public UInt64 dwCallback;
            public uint dwTimeFormat;
            public uint dwAudio;
            public uint wInput;
            public uint wOutput;
            public ushort wReserved1;
            public ushort wFormatTag;
            public ushort wReserved2;
            public ushort nChannels;
            public ushort wReserved3;
            public uint nSamplesPerSec;
            public uint nAvgBytesPerSec;
            public ushort nBlockAlign;
            public ushort wReserved4;
            public ushort wBitsPerSample;
            public ushort wReserved5;
        };// MCI_WAVE_SET_PARMS, *PMCI_WAVE_SET_PARMS, FAR * LPMCI_WAVE_SET_PARMS;


        /* MCI extensions for MIDI sequencer devices */

        /* flags for the dwReturn field of MCI_STATUS_PARMS parameter block */
        /* MCI_STATUS command, (dwItem == MCI_SEQ_STATUS_DIVTYPE) */
        public const uint MCI_SEQ_DIV_PPQN      =      (0 + MCI_SEQ_OFFSET);
        public const uint MCI_SEQ_DIV_SMPTE_24  =      (1 + MCI_SEQ_OFFSET);
        public const uint MCI_SEQ_DIV_SMPTE_25  =      (2 + MCI_SEQ_OFFSET);
        public const uint MCI_SEQ_DIV_SMPTE_30DROP =   (3 + MCI_SEQ_OFFSET);
        public const uint MCI_SEQ_DIV_SMPTE_30     =   (4 + MCI_SEQ_OFFSET);

        /* flags for the dwMaster field of MCI_SEQ_SET_PARMS parameter block */
        /* MCI_SET command, (dwFlags == MCI_SEQ_SET_MASTER) */
        public const uint MCI_SEQ_FORMAT_SONGPTR   =   0x4001;
        public const uint MCI_SEQ_FILE             =   0x4002;
        public const uint MCI_SEQ_MIDI             =   0x4003;
        public const uint MCI_SEQ_SMPTE            =   0x4004;
        public const uint MCI_SEQ_NONE             =   65533;
        public const uint MCI_SEQ_MAPPER           =   65535;

        /* flags for the dwItem field of MCI_STATUS_PARMS parameter block */
        public const ulong MCI_SEQ_STATUS_TEMPO     =       0x00004002L;
        public const ulong MCI_SEQ_STATUS_PORT      =      0x00004003L;
        public const ulong MCI_SEQ_STATUS_SLAVE     =       0x00004007L;
        public const ulong MCI_SEQ_STATUS_MASTER    =       0x00004008L;
        public const ulong MCI_SEQ_STATUS_OFFSET    =       0x00004009L;
        public const ulong MCI_SEQ_STATUS_DIVTYPE   =       0x0000400AL;
        public const ulong MCI_SEQ_STATUS_NAME      =       0x0000400BL;
        public const ulong MCI_SEQ_STATUS_COPYRIGHT =       0x0000400CL;

        /* flags for the dwFlags parameter of MCI_SET command message */
        public const ulong MCI_SEQ_SET_TEMPO        =       0x00010000L;
        public const ulong MCI_SEQ_SET_PORT         =       0x00020000L;
        public const ulong MCI_SEQ_SET_SLAVE        =       0x00040000L;
        public const ulong MCI_SEQ_SET_MASTER       =       0x00080000L;
        public const ulong MCI_SEQ_SET_OFFSET       =       0x01000000L;


        /* parameter block for MCI_SET command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_SEQ_SET_PARMS {
            public UInt64 dwCallback;
            public uint dwTimeFormat;
            public uint dwAudio;
            public uint dwTempo;
            public uint dwPort;
            public uint dwSlave;
            public uint dwMaster;
            public uint dwOffset;
        };// MCI_SEQ_SET_PARMS, *PMCI_SEQ_SET_PARMS, FAR * LPMCI_SEQ_SET_PARMS;


        /* MCI extensions for animation devices */

        /* flags for dwFlags parameter of MCI_OPEN command message */
        public const ulong MCI_ANIM_OPEN_WS            =    0x00010000L;
        public const ulong MCI_ANIM_OPEN_PARENT        =    0x00020000L;
        public const ulong MCI_ANIM_OPEN_NOSTATIC      =    0x00040000L;

        /* flags for dwFlags parameter of MCI_PLAY command message */
        public const ulong MCI_ANIM_PLAY_SPEED         =    0x00010000L;
        public const ulong MCI_ANIM_PLAY_REVERSE       =    0x00020000L;
        public const ulong MCI_ANIM_PLAY_FAST          =    0x00040000L;
        public const ulong MCI_ANIM_PLAY_SLOW          =    0x00080000L;
        public const ulong MCI_ANIM_PLAY_SCAN          =    0x00100000L;

        /* flags for dwFlags parameter of MCI_STEP command message */
        public const ulong MCI_ANIM_STEP_REVERSE       =    0x00010000L;
        public const ulong MCI_ANIM_STEP_FRAMES        =    0x00020000L;

        /* flags for dwItem field of MCI_STATUS_PARMS parameter block */
        public const ulong MCI_ANIM_STATUS_SPEED       =    0x00004001L;
        public const ulong MCI_ANIM_STATUS_FORWARD     =    0x00004002L;
        public const ulong MCI_ANIM_STATUS_HWND        =    0x00004003L;
        public const ulong MCI_ANIM_STATUS_HPAL        =    0x00004004L;
        public const ulong MCI_ANIM_STATUS_STRETCH     =    0x00004005L;

        /* flags for the dwFlags parameter of MCI_INFO command message */
        public const ulong MCI_ANIM_INFO_TEXT          =    0x00010000L;

        /* flags for dwItem field of MCI_GETDEVCAPS_PARMS parameter block */
        public const ulong MCI_ANIM_GETDEVCAPS_CAN_REVERSE = 0x00004001L;
        public const ulong MCI_ANIM_GETDEVCAPS_FAST_RATE   = 0x00004002L;
        public const ulong MCI_ANIM_GETDEVCAPS_SLOW_RATE   = 0x00004003L;
        public const ulong MCI_ANIM_GETDEVCAPS_NORMAL_RATE = 0x00004004L;
        public const ulong MCI_ANIM_GETDEVCAPS_PALETTES    = 0x00004006L;
        public const ulong MCI_ANIM_GETDEVCAPS_CAN_STRETCH  = 0x00004007L;
        public const ulong MCI_ANIM_GETDEVCAPS_MAX_WINDOWS = 0x00004008L;

        /* flags for the MCI_REALIZE command message */
        public const ulong MCI_ANIM_REALIZE_NORM      =     0x00010000L;
        public const ulong MCI_ANIM_REALIZE_BKGD      =     0x00020000L;

        /* flags for dwFlags parameter of MCI_WINDOW command message */
        public const ulong MCI_ANIM_WINDOW_HWND       =     0x00010000L;
        public const ulong MCI_ANIM_WINDOW_STATE      =     0x00040000L;
        public const ulong MCI_ANIM_WINDOW_TEXT       =     0x00080000L;
        public const ulong MCI_ANIM_WINDOW_ENABLE_STRETCH  = 0x00100000L;
        public const ulong MCI_ANIM_WINDOW_DISABLE_STRETCH = 0x00200000L;

        /* flags for hWnd field of MCI_ANIM_WINDOW_PARMS parameter block */
        /* MCI_WINDOW command message, (dwFlags == MCI_ANIM_WINDOW_HWND) */
        public const ulong MCI_ANIM_WINDOW_DEFAULT     =    0x00000000L;

        /* flags for dwFlags parameter of MCI_PUT command message */
        public const ulong MCI_ANIM_RECT                =    0x00010000L;
        public const ulong MCI_ANIM_PUT_SOURCE          =   0x00020000L;
        public const ulong MCI_ANIM_PUT_DESTINATION     =   0x00040000L;

        /* flags for dwFlags parameter of MCI_WHERE command message */
        public const ulong MCI_ANIM_WHERE_SOURCE         =   0x00020000L;
        public const ulong MCI_ANIM_WHERE_DESTINATION    =  0x00040000L;

        /* flags for dwFlags parameter of MCI_UPDATE command message */
        public const ulong MCI_ANIM_UPDATE_HDC           =  0x00020000L;


        /* parameter block for MCI_OPEN command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_OPEN_PARMSA {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
            public uint dwStyle;
            public object hWndParent;
        };// MCI_ANIM_OPEN_PARMSA, *PMCI_ANIM_OPEN_PARMSA, *LPMCI_ANIM_OPEN_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_OPEN_PARMSW {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
            public uint dwStyle;
            public object hWndParent;
        };// MCI_ANIM_OPEN_PARMSW, *PMCI_ANIM_OPEN_PARMSW, *LPMCI_ANIM_OPEN_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_OPEN_PARMS {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public ushort wReserved0;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
            public uint dwStyle;
            public object hWndParent;
            public ushort wReserved1;
        };// MCI_ANIM_OPEN_PARMS, FAR *LPMCI_ANIM_OPEN_PARMS;
        /* parameter block for MCI_PLAY command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_PLAY_PARMS {
            public UInt64 dwCallback;
            public uint dwFrom;
            public uint dwTo;
            public uint dwSpeed;
        };// MCI_ANIM_PLAY_PARMS, *PMCI_ANIM_PLAY_PARMS, FAR *LPMCI_ANIM_PLAY_PARMS;


        /* parameter block for MCI_STEP command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_STEP_PARMS {
            public UInt64 dwCallback;
            public uint dwFrames;
        };// MCI_ANIM_STEP_PARMS, *PMCI_ANIM_STEP_PARMS, FAR *LPMCI_ANIM_STEP_PARMS;


        /* parameter block for MCI_WINDOW command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_WINDOW_PARMSA {
            public UInt64 dwCallback;
            public object hWnd;
            public uint nCmdShow;
            public StringBuilder lpstrText;
        };// MCI_ANIM_WINDOW_PARMSA, *PMCI_ANIM_WINDOW_PARMSA, * LPMCI_ANIM_WINDOW_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_WINDOW_PARMSW {
            public UInt64 dwCallback;
            public object hWnd;
            public uint nCmdShow;
            public StringBuilder lpstrText;
        };// MCI_ANIM_WINDOW_PARMSW, *PMCI_ANIM_WINDOW_PARMSW, * LPMCI_ANIM_WINDOW_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_WINDOW_PARMS {
            public UInt64 dwCallback;
            public object hWnd;
            public ushort wReserved1;
            public ushort nCmdShow;
            public ushort wReserved2;
            public StringBuilder lpstrText;
        };// MCI_ANIM_WINDOW_PARMS, FAR * LPMCI_ANIM_WINDOW_PARMS;

        [StructLayout(LayoutKind.Sequential)]
        public struct mmPOINT{
            public long x;
            public long y;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct mmRECT{
            public long left;
            public long top;
            public long right;
            public long bottom; 
        }

        /* parameter block for MCI_PUT, MCI_UPDATE, MCI_WHERE command messages */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_RECT_PARMS {
            public UInt64 dwCallback;
            public mmPOINT ptOffset;
            public mmPOINT ptExtent;
            public mmRECT rc;
        };// MCI_ANIM_RECT_PARMS;
        /* parameter block for MCI_UPDATE PARMS */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_ANIM_UPDATE_PARMS {
            public UInt64 dwCallback;
            public mmRECT rc;
            public object hDC;
        };// MCI_ANIM_UPDATE_PARMS, *PMCI_ANIM_UPDATE_PARMS, FAR * LPMCI_ANIM_UPDATE_PARMS;


        /* MCI extensions for video overlay devices */

        /* flags for dwFlags parameter of MCI_OPEN command message */
        public const ulong MCI_OVLY_OPEN_WS             =   0x00010000L;
        public const ulong MCI_OVLY_OPEN_PARENT         =   0x00020000L;

        /* flags for dwFlags parameter of MCI_STATUS command message */
        public const ulong MCI_OVLY_STATUS_HWND         =   0x00004001L;
        public const ulong MCI_OVLY_STATUS_STRETCH      =   0x00004002L;

        /* flags for dwFlags parameter of MCI_INFO command message */
        public const ulong MCI_OVLY_INFO_TEXT           =   0x00010000L;

        /* flags for dwItem field of MCI_GETDEVCAPS_PARMS parameter block */
        public const ulong MCI_OVLY_GETDEVCAPS_CAN_STRETCH = 0x00004001L;
        public const ulong MCI_OVLY_GETDEVCAPS_CAN_FREEZE  = 0x00004002L;
        public const ulong MCI_OVLY_GETDEVCAPS_MAX_WINDOWS = 0x00004003L;

        /* flags for dwFlags parameter of MCI_WINDOW command message */
        public const ulong MCI_OVLY_WINDOW_HWND          =  0x00010000L;
        public const ulong MCI_OVLY_WINDOW_STATE         =  0x00040000L;
        public const ulong MCI_OVLY_WINDOW_TEXT          =  0x00080000L;
        public const ulong MCI_OVLY_WINDOW_ENABLE_STRETCH = 0x00100000L;
        public const ulong MCI_OVLY_WINDOW_DISABLE_STRETCH = 0x00200000L;

        /* flags for hWnd parameter of MCI_OVLY_WINDOW_PARMS parameter block */
        public const ulong MCI_OVLY_WINDOW_DEFAULT       =  0x00000000L;

        /* flags for dwFlags parameter of MCI_PUT command message */
        public const ulong MCI_OVLY_RECT                 =  0x00010000L;
        public const ulong MCI_OVLY_PUT_SOURCE           =  0x00020000L;
        public const ulong MCI_OVLY_PUT_DESTINATION      =  0x00040000L;
        public const ulong MCI_OVLY_PUT_FRAME            =  0x00080000L;
        public const ulong MCI_OVLY_PUT_VIDEO            =  0x00100000L;

        /* flags for dwFlags parameter of MCI_WHERE command message */
        public const ulong MCI_OVLY_WHERE_SOURCE         =  0x00020000L;
        public const ulong MCI_OVLY_WHERE_DESTINATION    =  0x00040000L;
        public const ulong MCI_OVLY_WHERE_FRAME          =  0x00080000L;
        public const ulong MCI_OVLY_WHERE_VIDEO          =  0x00100000L;


        /* parameter block for MCI_OPEN command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_OPEN_PARMSA {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
            public uint dwStyle;
            public object hWndParent;
        };// MCI_OVLY_OPEN_PARMSA, *PMCI_OVLY_OPEN_PARMSA, *LPMCI_OVLY_OPEN_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_OPEN_PARMSW {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
            public uint dwStyle;
            public object hWndParent;
        };// MCI_OVLY_OPEN_PARMSW, *PMCI_OVLY_OPEN_PARMSW, *LPMCI_OVLY_OPEN_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_OPEN_PARMS {
            public UInt64 dwCallback;
            public uint wDeviceID;
            public ushort wReserved0;
            public StringBuilder lpstrDeviceType;
            public StringBuilder lpstrElementName;
            public StringBuilder lpstrAlias;
            public uint dwStyle;
            public object hWndParent;
            public ushort wReserved1;
        };// MCI_OVLY_OPEN_PARMS, FAR *LPMCI_OVLY_OPEN_PARMS;

        /* parameter block for MCI_WINDOW command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_WINDOW_PARMSA {
            public UInt64 dwCallback;
            public object hWnd;
            public uint nCmdShow;
            public StringBuilder lpstrText;
        };// MCI_OVLY_WINDOW_PARMSA, *PMCI_OVLY_WINDOW_PARMSA, * LPMCI_OVLY_WINDOW_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_WINDOW_PARMSW {
            public UInt64 dwCallback;
            public object hWnd;
            public uint nCmdShow;
            public StringBuilder lpstrText;
        };// MCI_OVLY_WINDOW_PARMSW, *PMCI_OVLY_WINDOW_PARMSW, * LPMCI_OVLY_WINDOW_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_WINDOW_PARMS {
            public UInt64 dwCallback;
            public object hWnd;
            public ushort wReserved1;
            public uint nCmdShow;
            public ushort wReserved2;
            public StringBuilder lpstrText;
        };// MCI_OVLY_WINDOW_PARMS, FAR * LPMCI_OVLY_WINDOW_PARMS;


        /* parameter block for MCI_PUT, MCI_UPDATE, and MCI_WHERE command messages */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_RECT_PARMS {
            public UInt64 dwCallback;
            public mmPOINT ptOffset;
            public mmPOINT ptExtent;
            public mmRECT rc;
        };// MCI_OVLY_RECT_PARMS, *PMCI_OVLY_RECT_PARMS, FAR * LPMCI_OVLY_RECT_PARMS;


        /* parameter block for MCI_SAVE command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_SAVE_PARMSA {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
            public mmRECT rc;
        };// MCI_OVLY_SAVE_PARMSA, *PMCI_OVLY_SAVE_PARMSA, * LPMCI_OVLY_SAVE_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_SAVE_PARMSW {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
            public mmRECT rc;
        };// MCI_OVLY_SAVE_PARMSW, *PMCI_OVLY_SAVE_PARMSW, * LPMCI_OVLY_SAVE_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_SAVE_PARMS {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
            public mmRECT rc;
        };// MCI_OVLY_SAVE_PARMS, FAR * LPMCI_OVLY_SAVE_PARMS;

        /* parameter block for MCI_LOAD command message */
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_LOAD_PARMSA {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
            public mmRECT rc;
        };// MCI_OVLY_LOAD_PARMSA, *PMCI_OVLY_LOAD_PARMSA, * LPMCI_OVLY_LOAD_PARMSA;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_LOAD_PARMSW {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
            public mmRECT rc;
        };// MCI_OVLY_LOAD_PARMSW, *PMCI_OVLY_LOAD_PARMSW, * LPMCI_OVLY_LOAD_PARMSW;
        [StructLayout(LayoutKind.Sequential)]
        public struct tagMCI_OVLY_LOAD_PARMS {
            public UInt64 dwCallback;
            public StringBuilder lpfilename;
            public mmRECT rc;
        };// MCI_OVLY_LOAD_PARMS, FAR * LPMCI_OVLY_LOAD_PARMS;

        /****************************************************************************

                                DISPLAY Driver extensions

        ****************************************************************************/

            public const uint NEWTRANSPARENT = 3;           /* use with SetBkMode() */

            public const uint QUERYROPSUPPORT = 40;          /* use to determine ROP support */

        /****************************************************************************

                                DIB Driver extensions

        ****************************************************************************/

        public const uint SELECTDIB    =   41;                      /* DIB.DRV select dib escape */

        /****************************************************************************

                                ScreenSaver support

            The current application will receive a syscommand of SC_SCREENSAVE just
            before the screen saver is invoked.  If the app wishes to prevent a
            screen save, return non-zero value, otherwise call DefWindowProc().

        ****************************************************************************/

        public const uint SC_SCREENSAVE = 0xF140;

    }
}
