using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;

namespace TeHandlers
{
    class Mixer
    {
        private UInt32 mixerHandler;
        
        public Mixer()
        {
        }


        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint mixerOpen(ref UInt32 mixerHandle, UInt32 mixerId, ref UInt32 callBackWindow, ref UInt32 userInstance, UInt32 deviceFlags);

        [DllImport("winmm.dll", SetLastError = true)]
        private static extern uint mixerClose(UInt32 mixerHandle);

        [DllImport("winmm.dll")]
        private static extern uint mixerGetNumDevs();

        public void OpenMixer(UInt32 mixerId, ref UInt32 callBackWindow, ref UInt32 userInstance, UInt32 deviceFlags)
        {
            CheckMMResult(mixerOpen(ref this.mixerHandler, mixerId, ref callBackWindow, ref userInstance, deviceFlags));
        }

        public void CloseMixer()
        {
            CheckMMResult(mixerClose(this.mixerHandler));
        }

        public uint GetMixerNumDevices()
        {
            return mixerGetNumDevs();
        }

        public void CheckMMResult(uint result)
        {
        }

    }
}
