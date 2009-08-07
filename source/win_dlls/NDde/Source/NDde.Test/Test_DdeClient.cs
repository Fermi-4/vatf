namespace NDde.Test
{
    using System;
    using System.Collections;
    using System.Text;
    using NDde;
    using NDde.Advanced;
    using NDde.Client;
    using NDde.Server;
    using NUnit.Framework;

    [TestFixture]
    public sealed class Test_DdeClient
    {
        [Test]
        public void Test_Ctor_Overload_1()
        {
            DdeClient client = new DdeClient("myservice", "mytopic");
        }

        [Test]
        public void Test_Ctor_Overload_2()
        {
            using (DdeContext context = new DdeContext())
            {
                DdeClient client = new DdeClient("myservice", "mytopic", context);
            }
        }

        [Test]
        public void Test_Dispose()
        {
            using (DdeClient client = new DdeClient("myservice", "mytopic"))
            {
            }
        }

        [Test]
        public void Test_Service()
        {
            using (DdeClient client = new DdeClient("myservice", "mytopic")) 
            {
                Assert.AreEqual("myservice", client.Service);
            }
        }

        [Test]
        public void Test_Topic()
        {
            using (DdeClient client = new DdeClient("myservice", "mytopic")) 
            {
                Assert.AreEqual("mytopic", client.Topic);
            }
        }

        [Test]
        public void Test_Connect()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Connect_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Dispose();
                    client.Connect();
                }
            }
        }

        [Test]
        public void Test_Disconnect()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Disconnect();
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Disconnect_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    client.Disconnect();
                }
            }
        }

        [Test]
        public void Test_Handle_Variation_1()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    Assert.AreEqual(IntPtr.Zero, client.Handle);
                }
            }
        }

        [Test]
        public void Test_Handle_Variation_2()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    Assert.AreNotEqual(IntPtr.Zero, client.Handle);
                }
            }
        }

        [Test]
        public void Test_Handle_Variation_3()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Disconnect();
                    Assert.AreEqual(IntPtr.Zero, client.Handle);
                }
            }
        }

        [Test]
        public void Test_IsConnected_Variation_1()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    Assert.IsFalse(client.IsConnected);
                }
            }
        }

        [Test]
        public void Test_IsConnected_Variation_2()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    Assert.IsTrue(client.IsConnected);
                }
            }
        }

        [Test]
        public void Test_IsConnected_Variation_3()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Disconnect();
                    Assert.IsFalse(client.IsConnected);
                }
            }
        }

        [Test]
        public void Test_IsConnected_Variation_4()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    EventListener listener = new EventListener();
                    client.Disconnected += listener.OnEvent;
                    client.Connect();
                    server.Disconnect();
                    Assert.IsTrue(listener.Received.WaitOne(5000, false));
                    Assert.IsFalse(client.IsConnected);
                }
            }
        }

        [Test]
        public void Test_Pause()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Pause();
                    IAsyncResult ar = client.BeginExecute("mycommand", null, null);
                    Assert.IsFalse(ar.AsyncWaitHandle.WaitOne(5000, false));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Pause_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    client.Pause();
                }
            }
        }

        [Test]
        public void Test_Resume()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Pause();
                    IAsyncResult ar = client.BeginExecute("mycommand", null, null);
                    Assert.IsFalse(ar.AsyncWaitHandle.WaitOne(5000, false));
                    client.Resume();
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Resume_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Pause();
                    client.Dispose();
                    client.Resume();
                }
            }
        }

        [Test]
        public void Test_Abandon()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Pause();
                    IAsyncResult ar = client.BeginExecute("mycommand", null, null);
                    Assert.IsFalse(ar.AsyncWaitHandle.WaitOne(5000, false));
                    client.Abandon(ar);
                    client.Resume();
                    Assert.IsFalse(ar.AsyncWaitHandle.WaitOne(5000, false));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Abandon_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Pause();
                    IAsyncResult ar = client.BeginExecute("mycommand", null, null);
                    client.Dispose();
                    client.Abandon(ar);
                }
            }
        }

        [Test]
        public void Test_IsPaused_Variation_1()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    Assert.IsFalse(client.IsPaused);
                }
            }
        }

        [Test]
        public void Test_IsPaused_Variation_2()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Pause();
                    Assert.IsTrue(client.IsPaused);
                }
            }
        }

        [Test]
        public void Test_IsPaused_Variation_3()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Pause();
                    client.Resume();
                    Assert.IsFalse(client.IsPaused);
                }
            }
        }
        
        [Test]
        public void Test_Poke()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Poke("myitem", Encoding.ASCII.GetBytes("Hello World"), 1, 5000);
                    Assert.AreEqual("Hello World", Encoding.ASCII.GetString(server.GetData("mytopic", "myitem", 1)));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Poke_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    client.Poke("myitem", Encoding.ASCII.GetBytes("Hello World"), 1, 5000);
                }
            }
        }

        [Test]
        public void Test_BeginPoke()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginPoke("myitem", Encoding.ASCII.GetBytes("Hello World"), 1, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_BeginPoke_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    IAsyncResult ar = client.BeginPoke("myitem", Encoding.ASCII.GetBytes("Hello World"), 1, null, null);
                }
            }
        }

        [Test]
        public void Test_EndPoke()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginPoke("myitem", Encoding.ASCII.GetBytes("Hello World"), 1, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    client.EndPoke(ar);
                    Assert.AreEqual("Hello World", Encoding.ASCII.GetString(server.GetData("mytopic", "myitem", 1)));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_EndPoke_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginPoke("myitem", Encoding.ASCII.GetBytes("Hello World"), 1, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    client.Dispose();
                    client.EndPoke(ar);
                }
            }
        }

        [Test]
        public void Test_Request()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    byte[] data = client.Request("myitem", 1, 5000);
                    Assert.AreEqual("Hello World", Encoding.ASCII.GetString(data));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Request_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    byte[] data = client.Request("myitem", 1, 5000);
                }
            }
        }

        [Test]
        public void Test_BeginRequest()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginRequest("myitem", 1, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_BeginRequest_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    IAsyncResult ar = client.BeginRequest("myitem", 1, null, null);
                }
            }
        }

        [Test]
        public void Test_EndRequest()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginRequest("myitem", 1, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    byte[] data = client.EndRequest(ar);
                    Assert.AreEqual("Hello World", Encoding.ASCII.GetString(data));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_EndRequest_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginRequest("myitem", 1, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    client.Dispose();
                    byte[] data = client.EndRequest(ar);
                }
            }
        }

        [Test]
        public void Test_Execute()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Execute("Hello World", 5000);
                    Assert.AreEqual("Hello World", server.Command);
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Execute_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    client.Execute("Hello World", 5000);
                }
            }
        }

        [Test]
        public void Test_BeginExecute()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginExecute("Hello World", null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_BeginExecute_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    IAsyncResult ar = client.BeginExecute("Hello World", null, null);
                }
            }
        }

        [Test]
        public void Test_EndExecute()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginExecute("Hello World", null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    client.EndExecute(ar);
                    Assert.AreEqual("Hello World", server.Command);
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_EndExecute_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginExecute("Hello World", null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    client.Dispose();
                    client.EndExecute(ar);
                }
            }
        }

        [Test]
        public void Test_Disconnected_Variation_1()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    EventListener listener = new EventListener();
                    client.Disconnected += listener.OnEvent;
                    client.Connect();
                    client.Disconnect();
                    Assert.IsTrue(listener.Received.WaitOne(5000, false));
                    DdeDisconnectedEventArgs args = (DdeDisconnectedEventArgs)listener.Events[0];
                    Assert.IsFalse(args.IsServerInitiated);
                    Assert.IsFalse(args.IsDisposed);
                }
            }
        }

        [Test]
        public void Test_Disconnected_Variation_2()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    EventListener listener = new EventListener();
                    client.Disconnected += listener.OnEvent;
                    client.Connect();
                    server.Disconnect();
                    Assert.IsTrue(listener.Received.WaitOne(5000, false));
                    DdeDisconnectedEventArgs args = (DdeDisconnectedEventArgs)listener.Events[0];
                    Assert.IsTrue(args.IsServerInitiated);
                    Assert.IsFalse(args.IsDisposed);
                }
            }
        }

        [Test]
        public void Test_Disconnected_Variation_3()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    EventListener listener = new EventListener();
                    client.Disconnected += listener.OnEvent;
                    client.Connect();
                    client.Dispose();
                    Assert.IsTrue(listener.Received.WaitOne(5000, false));
                    DdeDisconnectedEventArgs args = (DdeDisconnectedEventArgs)listener.Events[0];
                    Assert.IsFalse(args.IsServerInitiated);
                    Assert.IsTrue(args.IsDisposed);
                }
            }
        }

        [Test]
        public void Test_StartAdvise_Hot()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    EventListener listener = new EventListener();
                    client.Advise += listener.OnEvent;
                    client.Connect();
                    client.StartAdvise("myitem", 1, true, 5000);
                    server.Advise("mytopic", "myitem");
                    Assert.IsTrue(listener.Received.WaitOne(5000, false));
                    DdeAdviseEventArgs args = (DdeAdviseEventArgs)listener.Events[0];
                    Assert.AreEqual("myitem", args.Item);
                    Assert.AreEqual(1, args.Format);
                    Assert.AreEqual("Hello World", Encoding.ASCII.GetString(args.Data));
                }
            }
        }

        [Test]
        public void Test_StartAdvise_Warm()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    EventListener listener = new EventListener();
                    client.Advise += listener.OnEvent;
                    client.Connect();
                    client.StartAdvise("myitem", 1, false, 5000);
                    server.Advise("mytopic", "myitem");
                    Assert.IsTrue(listener.Received.WaitOne(5000, false));
                    DdeAdviseEventArgs args = (DdeAdviseEventArgs)listener.Events[0];
                    Assert.AreEqual("myitem", args.Item);
                    Assert.AreEqual(1, args.Format);
                    Assert.IsNull(args.Data);
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_StartAdvise_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    client.StartAdvise("myitem", 1, false, 5000);
                }
            }
        }

        [Test]
        public void Test_BeginStartAdvise_Hot()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    EventListener listener = new EventListener();
                    client.Advise += listener.OnEvent;
                    client.Connect();
                    IAsyncResult ar = client.BeginStartAdvise("myitem", 1, true, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    server.Advise("mytopic", "myitem");
                    Assert.IsTrue(listener.Received.WaitOne(5000, false));
                    DdeAdviseEventArgs args = (DdeAdviseEventArgs)listener.Events[0];
                    Assert.AreEqual("myitem", args.Item);
                    Assert.AreEqual(1, args.Format);
                    Assert.AreEqual("Hello World", Encoding.ASCII.GetString(args.Data));
                }
            }
        }

        [Test]
        public void Test_BeginStartAdvise_Warm()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    EventListener listener = new EventListener();
                    client.Advise += listener.OnEvent;
                    client.Connect();
                    IAsyncResult ar = client.BeginStartAdvise("myitem", 1, false, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    server.Advise("mytopic", "myitem");
                    Assert.IsTrue(listener.Received.WaitOne(5000, false));
                    DdeAdviseEventArgs args = (DdeAdviseEventArgs)listener.Events[0];
                    Assert.AreEqual("myitem", args.Item);
                    Assert.AreEqual(1, args.Format);
                    Assert.IsNull(args.Data);
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_BeginStartAdvise_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Dispose();
                    IAsyncResult ar = client.BeginStartAdvise("myitem", 1, false, null, null);
                }
            }
        }

        [Test]
        public void Test_EndStartAdvise()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginStartAdvise("myitem", 1, true, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    client.EndStartAdvise(ar);
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_EndStartAdvise_After_Dispose()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                server.SetData("mytopic", "myitem", 1, Encoding.ASCII.GetBytes("Hello World"));
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    IAsyncResult ar = client.BeginStartAdvise("myitem", 1, true, null, null);
                    Assert.IsTrue(ar.AsyncWaitHandle.WaitOne(5000, false));
                    client.Dispose();
                    client.EndStartAdvise(ar);
                }
            }
        }

        #region EventListener
        private sealed class EventListener
        {
            private System.Threading.ManualResetEvent _Received = new System.Threading.ManualResetEvent(false);
            private ArrayList                         _Events   = new ArrayList();

            public IList Events
            {
                get { return ArrayList.ReadOnly(_Events); }
            }

            public System.Threading.WaitHandle Received
            {
                get { return _Received; }
            }

            public void OnEvent(object sender, DdeAdviseEventArgs args)
            {
                _Events.Add(args);
                _Received.Set();
            }

            public void OnEvent(object sender, DdeDisconnectedEventArgs args)
            {
                _Events.Add(args);
                _Received.Set();
            }
        }
        #endregion

        #region TracingServer
        private class TracingServer : DdeServer
        {
            public TracingServer(string service) : base(service)
            {
            }

            public TracingServer(string service, DdeContext context) : base(service, context)
            {
            }

            protected override bool OnBeforeConnect(string topic)
            {
                Console.WriteLine("OnBeforeConnect:".PadRight(16) 
                    + " Service='" + base.Service + "'"
                    + " Topic='" + topic + "'");

                return base.OnBeforeConnect(topic);
            }

            protected override void OnAfterConnect(DdeConversation conversation)
            {
                Console.WriteLine("OnAfterConnect:".PadRight(16) 
                    + " Service='" + conversation.Service + "'"
                    + " Topic='" + conversation.Topic + "'"
                    + " Handle=" + conversation.Handle.ToString());
            }

            protected override void OnDisconnect(DdeConversation conversation)
            {
                Console.WriteLine("OnDisconnect:".PadRight(16) 
                    + " Service='" + conversation.Service + "'"
                    + " Topic='" + conversation.Topic + "'"
                    + " Handle=" + conversation.Handle.ToString());
            }

            protected override bool OnStartAdvise(DdeConversation conversation, string item, int format)
            {
                Console.WriteLine("OnStartAdvise:".PadRight(16) 
                    + " Service='" + conversation.Service + "'"
                    + " Topic='" + conversation.Topic + "'"
                    + " Handle=" + conversation.Handle.ToString()
                    + " Item='" + item + "'"
                    + " Format=" + format.ToString());

                return base.OnStartAdvise(conversation, item, format);
            }

            protected override void OnStopAdvise(DdeConversation conversation, string item)
            {
                Console.WriteLine("OnStopAdvise:".PadRight(16) 
                    + " Service='" + conversation.Service + "'"
                    + " Topic='" + conversation.Topic + "'"
                    + " Handle=" + conversation.Handle.ToString()
                    + " Item='" + item + "'");
            }

            protected override ExecuteResult OnExecute(DdeConversation conversation, string command)
            {
                Console.WriteLine("OnExecute:".PadRight(16) 
                    + " Service='" + conversation.Service + "'"
                    + " Topic='" + conversation.Topic + "'"
                    + " Handle=" + conversation.Handle.ToString()
                    + " Command='" + command + "'");
            
                return base.OnExecute(conversation, command);
            }

            protected override PokeResult OnPoke(DdeConversation conversation, string item, byte[] data, int format)
            {
                Console.WriteLine("OnPoke:".PadRight(16) 
                    + " Service='" + conversation.Service + "'"
                    + " Topic='" + conversation.Topic + "'"
                    + " Handle=" + conversation.Handle.ToString()
                    + " Item='" + item + "'" 
                    + " Data=" + data.Length.ToString()
                    + " Format=" + format.ToString());

                return base.OnPoke(conversation, item, data, format);
            }

            protected override RequestResult OnRequest(DdeConversation conversation, string item, int format)
            {
                Console.WriteLine("OnRequest:".PadRight(16) 
                    + " Service='" + conversation.Service + "'"
                    + " Topic='" + conversation.Topic + "'"
                    + " Handle=" + conversation.Handle.ToString()
                    + " Item='" + item + "'" 
                    + " Format=" + format.ToString());

                return base.OnRequest(conversation, item, format);
            }
    
            protected override byte[] OnAdvise(string topic, string item, int format)
            {
                Console.WriteLine("OnAdvise:".PadRight(16) 
                    + " Service='" + this.Service + "'"
                    + " Topic='" + topic + "'"
                    + " Item='" + item + "'" 
                    + " Format=" + format.ToString());
            
                return base.OnAdvise(topic, item, format);
            }

        } // class
        #endregion

        #region TestServer
        private sealed class TestServer : TracingServer
        {
            private string      _Command = "";
            private IDictionary _Data    = new Hashtable();

            public TestServer(string service) : base(service)
            {
            }

            public TestServer(string service, DdeContext context) : base(service, context)
            {
            }

            public string Command
            {
                get { return _Command; }
            }

            public byte[] GetData(string topic, string item, int format)
            {
                string key = topic + ":" + item + ":" + format.ToString();
                return (byte[])_Data[key];
            }

            public void SetData(string topic, string item, int format, byte[] data)
            {
                string key = topic + ":" + item + ":" + format.ToString();
                _Data[key] = data;
            }

            protected override bool OnBeforeConnect(string topic)
            {
                base.OnBeforeConnect(topic);
                return true;
            }

            protected override void OnAfterConnect(DdeConversation conversation)
            {
                base.OnAfterConnect(conversation);
            }

            protected override void OnDisconnect(DdeConversation conversation)
            {
                base.OnDisconnect(conversation);
            }

            protected override bool OnStartAdvise(DdeConversation conversation, string item, int format)
            {
                base.OnStartAdvise(conversation, item, format);
                return true;
            }

            protected override void OnStopAdvise(DdeConversation conversation, string item)
            {
                base.OnStopAdvise(conversation, item);
            }

            protected override ExecuteResult OnExecute(DdeConversation conversation, string command)
            {
                base.OnExecute(conversation, command);
                _Command = command;
                return ExecuteResult.Processed;
            }

            protected override PokeResult OnPoke(DdeConversation conversation, string item, byte[] data, int format)
            {
                base.OnPoke(conversation, item, data, format);
                string key = conversation.Topic + ":" + item + ":" + format.ToString();
                _Data[key] = data;
                return PokeResult.Processed;
            }

            protected override RequestResult OnRequest(DdeConversation conversation, string item, int format)
            {
                base.OnRequest(conversation, item, format);
                string key = conversation.Topic + ":" + item + ":" + format.ToString();
                if (_Data.Contains(key)) 
                {
                    return new RequestResult((byte[])_Data[key]);
                }
                return RequestResult.NotProcessed;
            }
    
            protected override byte[] OnAdvise(string topic, string item, int format)
            {
                base.OnAdvise(topic, item, format);
                string key = topic + ":" + item + ":" + format.ToString();
                if (_Data.Contains(key)) 
                {
                    return (byte[])_Data[key];
                }
                return null;
            }

        } // class
        #endregion

    } // class

} // namespace