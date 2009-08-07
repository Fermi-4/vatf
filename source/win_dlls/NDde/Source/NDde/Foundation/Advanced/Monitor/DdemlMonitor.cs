#region Copyright (c) 2005 by Brian Gideon (briangideon@yahoo.com)
/* Shared Source License for NDde
 *
 * This license governs use of the accompanying software ('Software'), and your use of the Software constitutes acceptance of this license.
 *
 * You may use the Software for any commercial or noncommercial purpose, including distributing derivative works.
 * 
 * In return, we simply require that you agree:
 *  1. Not to remove any copyright or other notices from the Software. 
 *  2. That if you distribute the Software in source code form you do so only under this license (i.e. you must include a complete copy of this
 *     license with your distribution), and if you distribute the Software solely in object form you only do so under a license that complies with
 *     this license.
 *  3. That the Software comes "as is", with no warranties.  None whatsoever.  This means no express, implied or statutory warranty, including
 *     without limitation, warranties of merchantability or fitness for a particular purpose or any warranty of title or non-infringement.  Also,
 *     you must pass this disclaimer on whenever you distribute the Software or derivative works.
 *  4. That no contributor to the Software will be liable for any of those types of damages known as indirect, special, consequential, or incidental
 *     related to the Software or this license, to the maximum extent the law permits, no matter what legal theory it’s based on.  Also, you must
 *     pass this limitation of liability on whenever you distribute the Software or derivative works.
 *  5. That if you sue anyone over patents that you think may apply to the Software for a person's use of the Software, your license to the Software
 *     ends automatically.
 *  6. That the patent rights, if any, granted in this license only apply to the Software, not to any derivative works you make.
 *  7. That the Software is subject to U.S. export jurisdiction at the time it is licensed to you, and it may be subject to additional export or
 *     import laws in other places.  You agree to comply with all such laws and regulations that may apply to the Software after delivery of the
 *     software to you.
 *  8. That if you are an agency of the U.S. Government, (i) Software provided pursuant to a solicitation issued on or after December 1, 1995, is
 *     provided with the commercial license rights set forth in this license, and (ii) Software provided pursuant to a solicitation issued prior to
 *     December 1, 1995, is provided with “Restricted Rights” as set forth in FAR, 48 C.F.R. 52.227-14 (June 1987) or DFAR, 48 C.F.R. 252.227-7013 
 *     (Oct 1988), as applicable.
 *  9. That your rights under this License end automatically if you breach it in any way.
 * 10. That all rights not expressly granted to you in this license are reserved.
 */
#endregion
namespace NDde.Foundation.Advanced.Monitor
{
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Windows.Forms;
    using NDde.Properties;
    
    internal sealed class DdemlMonitor : IDisposable
    {
        private DdemlContext _Context  = null; 
        private bool         _Disposed = false;
        
        public event EventHandler<DdemlCallbackActivityEventArgs>     CallbackActivity;
        public event EventHandler<DdemlConversationActivityEventArgs> ConversationActivity;
        public event EventHandler<DdemlErrorActivityEventArgs>        ErrorActivity;
        public event EventHandler<DdemlLinkActivityEventArgs>         LinkActivity;
        public event EventHandler<DdemlMessageActivityEventArgs>      MessageActivity;
        public event EventHandler<DdemlStringActivityEventArgs>       StringActivity;

        public DdemlMonitor(DdemlContext context)
        {
            _Context = context;
        }

        public void Dispose()
        {
            Dispose(true);
        }

        private void Dispose(bool disposing)
        {
            if (!_Disposed)
            {
                _Disposed = true;
                if (disposing)
                {
                    _Context.Dispose();
                }
            }
        }

        public void Start()
        {
            int flags = Ddeml.APPCLASS_STANDARD;
            flags |= Ddeml.MF_CALLBACKS;
            flags |= Ddeml.MF_CONV;
            flags |= Ddeml.MF_ERRORS;
            flags |= Ddeml.MF_HSZ_INFO;
            flags |= Ddeml.MF_LINKS;
            flags |= Ddeml.MF_POSTMSGS;
            flags |= Ddeml.MF_SENDMSGS;

            _Context.AddTransactionFilter(new TransactionFilter(this));
            _Context.Initialize(flags);
        }

        private sealed class TransactionFilter : IDdemlTransactionFilter
        {
            private DdemlMonitor _Parent = null;

            public TransactionFilter(DdemlMonitor parent)
            {
                _Parent = parent;
            }

            public bool PreFilterTransaction(DdemlTransaction t)
            {
                if (t.uType == Ddeml.XTYP_MONITOR) 
                {
                    switch (t.dwData2.ToInt32())
                    {
                        case Ddeml.MF_CALLBACKS:
                        {
                            // Get the MONCBSTRUCT object.
                            int length = 0;
                            IntPtr phData = Ddeml.DdeAccessData(t.hData, ref length);
                            Ddeml.MONCBSTRUCT ms = (Ddeml.MONCBSTRUCT)Marshal.PtrToStructure(phData, typeof(Ddeml.MONCBSTRUCT));
                            Ddeml.DdeUnaccessData(t.hData);

                            DdemlCallbackActivityEventArgs args = new DdemlCallbackActivityEventArgs(
                                ms.wType,
                                ms.wFmt,
                                ms.hConv,
                                ms.hsz1,
                                ms.hsz2,
                                ms.hData,
                                ms.dwData1,
                                ms.dwData2,
                                ms.dwRet,
                                ms.hTask);

                            if (_Parent.CallbackActivity != null)
                            {
                                _Parent.CallbackActivity(_Parent, args);
                            }

                            break;
                        }
                        case Ddeml.MF_CONV:
                        {
                            // Get the MONCONVSTRUCT object.
                            int length = 0;
                            IntPtr phData = Ddeml.DdeAccessData(t.hData, ref length);
                            Ddeml.MONCONVSTRUCT ms = (Ddeml.MONCONVSTRUCT)Marshal.PtrToStructure(phData, typeof(Ddeml.MONCONVSTRUCT));
                            Ddeml.DdeUnaccessData(t.hData);
                        
                            StringBuilder psz;

                            // Get the service name from the hszSvc string handle.
                            psz = new StringBuilder(Ddeml.MAX_STRING_SIZE);
                            length = Ddeml.DdeQueryString(_Parent._Context.InstanceId, ms.hszSvc, psz, psz.Capacity, Ddeml.CP_WINANSI);
                            string service = psz.ToString();

                            // Get the topic name from the hszTopic string handle.
                            psz = new StringBuilder(Ddeml.MAX_STRING_SIZE);
                            length = Ddeml.DdeQueryString(_Parent._Context.InstanceId, ms.hszTopic, psz, psz.Capacity, Ddeml.CP_WINANSI);
                            string topic = psz.ToString();

                            DdemlConversationActivityEventArgs args = new DdemlConversationActivityEventArgs(
                                service,
                                topic,
                                ms.fConnect,
                                ms.hConvClient,
                                ms.hConvServer,
                                ms.hTask);

                            if (_Parent.ConversationActivity != null)
                            {
                                _Parent.ConversationActivity(_Parent, args);
                            }

                            break;
                        }
                        case Ddeml.MF_ERRORS:
                        {
                            int length = 0;
                            IntPtr phData = Ddeml.DdeAccessData(t.hData, ref length);
                            Ddeml.MONERRSTRUCT ms = (Ddeml.MONERRSTRUCT)Marshal.PtrToStructure(phData, typeof(Ddeml.MONERRSTRUCT));
                            Ddeml.DdeUnaccessData(t.hData);

                            DdemlErrorActivityEventArgs args = new DdemlErrorActivityEventArgs(ms.wLastError, ms.hTask);

                            if (_Parent.ErrorActivity != null)
                            {
                                _Parent.ErrorActivity(_Parent, args);
                            }

                            break;
                        }
                        case Ddeml.MF_HSZ_INFO:
                        {
                            // TODO: Fix string retrieval.

                            int length = 0;
                            IntPtr phData = Ddeml.DdeAccessData(t.hData, ref length);
                            Ddeml.MONHSZSTRUCT ms = (Ddeml.MONHSZSTRUCT)Marshal.PtrToStructure(phData, typeof(Ddeml.MONHSZSTRUCT));
                            Ddeml.DdeUnaccessData(t.hData);

                            // Get the string from the hsz string handle.
                            StringBuilder psz = new StringBuilder(Ddeml.MAX_STRING_SIZE);
                            length = Ddeml.DdeQueryString(_Parent._Context.InstanceId, ms.hsz, psz, psz.Capacity, Ddeml.CP_WINANSI);
                            string str = psz.ToString();

                            DdemlStringActivityType action = DdemlStringActivityType.CleanUp;
                            switch (ms.fsAction)
                            {
                                case Ddeml.MH_CLEANUP:
                                {
                                    action = DdemlStringActivityType.CleanUp;
                                    break;
                                }
                                case Ddeml.MH_CREATE:
                                {
                                    action = DdemlStringActivityType.Create;
                                    break;
                                }
                                case Ddeml.MH_DELETE:
                                {
                                    action = DdemlStringActivityType.Delete;
                                    break;
                                }
                                case Ddeml.MH_KEEP:
                                {
                                    action = DdemlStringActivityType.Keep;
                                    break;
                                }
                            }

                            DdemlStringActivityEventArgs args = new DdemlStringActivityEventArgs(str, action, ms.hTask);

                            if (_Parent.StringActivity != null)
                            {
                                _Parent.StringActivity(_Parent, args);
                            }
                            
                            break;
                        }
                        case Ddeml.MF_LINKS:
                        {
                            int length = 0;
                            IntPtr phData = Ddeml.DdeAccessData(t.hData, ref length);
                            Ddeml.MONLINKSTRUCT ms = (Ddeml.MONLINKSTRUCT)Marshal.PtrToStructure(phData, typeof(Ddeml.MONLINKSTRUCT));
                            Ddeml.DdeUnaccessData(t.hData);

                            StringBuilder psz;

                            // Get the service name from the hszSvc string handle.
                            psz = new StringBuilder(Ddeml.MAX_STRING_SIZE);
                            length = Ddeml.DdeQueryString(_Parent._Context.InstanceId, ms.hszSvc, psz, psz.Capacity, Ddeml.CP_WINANSI);
                            string service = psz.ToString();

                            // Get the topic name from the hszTopic string handle.
                            psz = new StringBuilder(Ddeml.MAX_STRING_SIZE);
                            length = Ddeml.DdeQueryString(_Parent._Context.InstanceId, ms.hszTopic, psz, psz.Capacity, Ddeml.CP_WINANSI);
                            string topic = psz.ToString();
                        
                            // Get the item name from the hszItem string handle.
                            psz = new StringBuilder(Ddeml.MAX_STRING_SIZE);
                            length = Ddeml.DdeQueryString(_Parent._Context.InstanceId, ms.hszItem, psz, psz.Capacity, Ddeml.CP_WINANSI);
                            string item = psz.ToString();

                            DdemlLinkActivityEventArgs args = new DdemlLinkActivityEventArgs(
                                service, 
                                topic, 
                                item, 
                                ms.wFmt,
                                !ms.fNoData,
                                ms.fEstablished,
                                ms.fServer,
                                ms.hConvClient,
                                ms.hConvServer,
                                ms.hTask);

                            if (_Parent.LinkActivity != null)
                            {
                                _Parent.LinkActivity(_Parent, args);
                            }
                            
                            break;
                        }
                        case Ddeml.MF_POSTMSGS:
                        {
                            int length = 0;
                            IntPtr phData = Ddeml.DdeAccessData(t.hData, ref length);
                            Ddeml.MONMSGSTRUCT ms = (Ddeml.MONMSGSTRUCT)Marshal.PtrToStructure(phData, typeof(Ddeml.MONMSGSTRUCT));
                            Ddeml.DdeUnaccessData(t.hData);

                            Message m = new Message();
                            m.HWnd = ms.hwndTo;
                            m.Msg = ms.wMsg;
                            m.LParam = ms.lParam;
                            m.WParam = ms.wParam;

                            DdemlMessageActivityEventArgs args = new DdemlMessageActivityEventArgs(m, ms.hTask);

                            if (_Parent.MessageActivity != null)
                            {
                                _Parent.MessageActivity(_Parent, args);
                            }
                            
                            break;
                        }
                        case Ddeml.MF_SENDMSGS:
                        {
                            int length = 0;
                            IntPtr phData = Ddeml.DdeAccessData(t.hData, ref length);
                            Ddeml.MONMSGSTRUCT ms = (Ddeml.MONMSGSTRUCT)Marshal.PtrToStructure(phData, typeof(Ddeml.MONMSGSTRUCT));
                            Ddeml.DdeUnaccessData(t.hData);

                            Message m = new Message();
                            m.HWnd = ms.hwndTo;
                            m.Msg = ms.wMsg;
                            m.LParam = ms.lParam;
                            m.WParam = ms.wParam;

                            DdemlMessageActivityEventArgs args = new DdemlMessageActivityEventArgs(m, ms.hTask);
                            
                            if (_Parent.MessageActivity != null)
                            {
                                _Parent.MessageActivity(_Parent, args);
                            }
                            
                            break;
                        }
                    }
                }			
                return true;
            }
        
        } // class

    } // class

} // namespace