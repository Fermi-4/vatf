using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using Ti.Atf.Ted.Drivers;

namespace Ti.Atf.Ted.Drivers
{

    public class BaseMCIController:BaseMMController
    {
        [DllImport("winmm.dll", EntryPoint = "mciSendString", CharSet = CharSet.Ansi)]
        protected static extern uint mciSendString(string strCommand, StringBuilder strReturn, uint iReturnLength, IntPtr hwndCallback);

        [DllImport("winmm.dll", EntryPoint = "mciSendCommand", CharSet = CharSet.Ansi)]
        protected static extern uint mciSendCommand(uint deviceID, uint cmdMsg, long cmdFlags, IntPtr cmdParams);
   
        [DllImport("winmm.dll", EntryPoint = "mciExecute", CharSet = CharSet.Ansi)]
        protected static extern bool mciExecute(string strCommand);

        [DllImport("winmm.dll", EntryPoint = "mciGetCreatorTask", CharSet = CharSet.Ansi)]
        protected static extern UIntPtr mciGetCreatorTask(uint deviceID);

        [DllImport("winmm.dll", EntryPoint = "mciGetDeviceID", CharSet = CharSet.Ansi)]
        protected static extern uint mciGetDeviceID(string deviceId);

        [DllImport("winmm.dll", EntryPoint = "mciGetDeviceIDFromElementID", CharSet = CharSet.Ansi)]
        protected static extern uint mciGetDeviceIDFromElementID(uint deviceID, string deviceType);

        [DllImport("winmm.dll", EntryPoint = "mciGetErrorString", CharSet = CharSet.Ansi)]
        protected static extern bool mciGetErrorString(uint errorCode, StringBuilder errorText, uint eTextLength);

        [DllImport("winmm.dll", EntryPoint = "mciGetYieldProc", CharSet = CharSet.Ansi)]
        protected static extern uint mciGetYieldProc(uint deviceID, UIntPtr procParams);

        [DllImport("winmm.dll", EntryPoint = "mciSetYieldProc", CharSet = CharSet.Ansi)]
        protected static extern uint mciSetYieldProc(uint deviceID, uint yieldProc, UIntPtr procParams);

    }
}
