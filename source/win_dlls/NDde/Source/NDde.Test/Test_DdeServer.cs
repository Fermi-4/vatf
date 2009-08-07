namespace NDde.Test
{
    using System;
    using System.Collections;
    using System.Text;
    using System.Timers;
    using NDde;
    using NDde.Advanced;
    using NDde.Client;
    using NDde.Server;
    using NUnit.Framework;

    [TestFixture]
    public sealed class Test_DdeServer
    {
        [Test]
        public void Test_Ctor_Overload_1()
        {
            DdeServer server = new TestServer("myservice");
        }

        [Test]
        public void Test_Ctor_Overload_2()
        {
            using (DdeContext context = new DdeContext())
            {
                DdeServer server = new TestServer("myservice");
            }
        }

        [Test]
        public void Test_Register()
        {
            using (DdeServer server = new TestServer("myservice"))
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
        public void Test_Register_After_Dispose()
        {
            using (DdeServer server = new TestServer("myservice"))
            {
                server.Dispose();
                server.Register();
            }
        }

        [Test]
        public void Test_Unregister()
        {
            using (DdeServer server = new TestServer("myservice"))
            {
                server.Register();
                server.Unregister();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    try
                    {
                        client.Connect();
                        Assert.Fail();
                    }
                    catch (DdeException e)
                    {
                        Assert.AreEqual(0x400A, e.Code);
                    }
                }
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Unregister_After_Dispose()
        {
            using (DdeServer server = new TestServer("myservice"))
            {
                server.Register();
                server.Dispose();
                server.Unregister();
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
        public void Test_Execute_NotProcessed()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    try 
                    {
                        client.Execute("#NotProcessed", 5000);
                    }
                    catch (DdeException e)
                    {
                        Assert.AreEqual(0x4009, e.Code);
                    }
                }
            }
        }

        [Test]
        public void Test_Execute_PauseConversation()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    client.Execute("#PauseConversation", 5000);
                }
            }
        }

        [Test]
        public void Test_Execute_TooBusy()
        {
            using (TestServer server = new TestServer("myservice"))
            {
                server.Register();
                using (DdeClient client = new DdeClient("myservice", "mytopic"))
                {
                    client.Connect();
                    try 
                    {
                        client.Execute("#TooBusy", 5000);
                    }
                    catch (DdeException e)
                    {
                        Assert.AreEqual(0x4001, e.Code);
                    }
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
        private class TestServer : TracingServer
        {
            private Timer       _Timer        = new Timer();
            private string      _Command      = "";
            private IDictionary _Data         = new Hashtable();
            private IDictionary _Conversation = new Hashtable();
            private bool        _Disposed     = false;

            public TestServer(string service) : base(service)
            {
                _Timer.Elapsed += new ElapsedEventHandler(this.OnTimerElapsed);
                _Timer.Interval = 1000;
                _Timer.SynchronizingObject = base.Context;
            }

            public TestServer(string service, DdeContext context) : base(service, context)
            {
                _Timer.Elapsed += new ElapsedEventHandler(this.OnTimerElapsed);
                _Timer.Interval = 1000;
                _Timer.SynchronizingObject = base.Context;
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

            protected override void Dispose(bool disposing)
            {
                try 
                {
                    if (!_Disposed) 
                    {
                        if (disposing)
                        {
                            _Timer.Dispose();
                        }
                        base.Dispose(true);
                    }
                }
                finally
                {
                    _Disposed = true;
                }
            }

            private void OnTimerElapsed(object sender, ElapsedEventArgs args)
            {
                foreach (DdeConversation c in _Conversation.Values)
                {
                    if (c.IsPaused)
                    {
                        Resume(c);
                    }
                }

                foreach (DdeConversation c in _Conversation.Values)
                {
                    if (c.IsPaused)
                    {
                        return;
                    }
                }

                _Timer.Stop();
            }

            protected override bool OnBeforeConnect(string topic)
            {
                base.OnBeforeConnect(topic);
                return true;
            }

            protected override void OnAfterConnect(DdeConversation conversation)
            {
                base.OnAfterConnect(conversation);
                _Conversation.Add(conversation.Handle, conversation);
            }

            protected override void OnDisconnect(DdeConversation conversation)
            {
                base.OnDisconnect(conversation);
                _Conversation.Remove(conversation.Handle);
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
                switch (command)
                {
                    case "#NotProcessed":
                    {
                        return ExecuteResult.NotProcessed;
                    }
                    case "#PauseConversation":
                    {
                        if ((string)conversation.Tag == command)
                        {
                            conversation.Tag = null;
                            return ExecuteResult.Processed;
                        }
                        conversation.Tag = command;
                        if (!_Timer.Enabled) _Timer.Start();
                        return ExecuteResult.PauseConversation;
                    }
                    case "#Processed":
                    {
                        return ExecuteResult.Processed;
                    }
                    case "#TooBusy":
                    {
                        return ExecuteResult.TooBusy;
                    }
                }
                return ExecuteResult.Processed;
            }

            protected override PokeResult OnPoke(DdeConversation conversation, string item, byte[] data, int format)
            {
                base.OnPoke(conversation, item, data, format);
                string key = conversation.Topic + ":" + item + ":" + format.ToString();
                _Data[key] = data;
                switch (item)
                {
                    case "#NotProcessed":
                    {
                        return PokeResult.NotProcessed;
                    }
                    case "#PauseConversation":
                    {
                        if ((string)conversation.Tag == item)
                        {
                            conversation.Tag = null;
                            return PokeResult.Processed;
                        }
                        conversation.Tag = item;
                        if (!_Timer.Enabled) _Timer.Start();
                        return PokeResult.PauseConversation;
                    }
                    case "#Processed":
                    {
                        return PokeResult.Processed;
                    }
                    case "#TooBusy":
                    {
                        return PokeResult.TooBusy;
                    }
                }
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