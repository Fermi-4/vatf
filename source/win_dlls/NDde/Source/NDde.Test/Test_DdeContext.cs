namespace NDde.Test
{
    using System;
    using System.Collections;
    using NDde;
    using NDde.Advanced;
    using NDde.Client;
    using NDde.Server;
    using NUnit.Framework;

    [TestFixture]
    public sealed class Test_DdeContext
    {
        [Test]
        public void Test_Ctor_Overload_1()
        {
            DdeContext context = new DdeContext();
        }

        [Test]
        public void Test_Ctor_Overload_2()
        {
            DdeContext context = new DdeContext(new DdeContext());
        }

        [Test]
        public void Test_Dispose()
        {
            using (DdeContext context = new DdeContext())
            {
            }
        }

        [Test]
        public void Test_Initialize()
        {
            using (DdeContext context = new DdeContext())
            {
                context.Initialize();
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_Initialize_After_Dispose()
        {
            using (DdeContext context = new DdeContext())
            {
                context.Dispose();
                context.Initialize();
            }
        }

        [Test]
        public void Test_IsInitialized_Variation_1()
        {
            using (DdeContext context = new DdeContext())
            {
                Assert.IsFalse(context.IsInitialized);
            }
        }

        [Test]
        public void Test_IsInitialized_Variation_2()
        {
            using (DdeContext context = new DdeContext())
            {
                context.Initialize();
                Assert.IsTrue(context.IsInitialized);
            }
        }

        [Test]
        public void Test_AddTransactionFilter()
        {
            using (DdeContext context = new DdeContext())
            {
                IDdeTransactionFilter filter = new TransactionFilter();
                context.AddTransactionFilter(filter);
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_AddTransactionFilter_After_Dispose()
        {
            using (DdeContext context = new DdeContext())
            {
                IDdeTransactionFilter filter = new TransactionFilter();
                context.Dispose();
                context.AddTransactionFilter(filter);
            }
        }

        [Test]
        public void Test_RemoveTransactionFilter()
        {
            using (DdeContext context = new DdeContext())
            {
                TransactionFilter filter = new TransactionFilter();
                context.AddTransactionFilter(filter);
                context.RemoveTransactionFilter(filter);
            }
        }

        [Test]
        [ExpectedException(typeof(ObjectDisposedException))]
        public void Test_RemoveTransactionFilter_After_Dispose()
        {
            using (DdeContext context = new DdeContext())
            {
                TransactionFilter filter = new TransactionFilter();
                context.AddTransactionFilter(filter);
                context.Dispose();
                context.RemoveTransactionFilter(filter);
            }
        }

        [Test]
        public void Test_TransactionFilter()
        {
            using (DdeContext context = new DdeContext())
            {
                TransactionFilter filter = new TransactionFilter();
                context.AddTransactionFilter(filter);
                context.Initialize();
                using (DdeServer server = new TestServer("test"))
                {
                    server.Register();
                }
                Assert.IsTrue(filter.Received.WaitOne(5000, false));
            }
        }

        [Test]
        public void Test_Register()
        {
            using (DdeContext context = new DdeContext())
            {
                EventListener listener = new EventListener();
                context.Register += listener.OnEvent;
                context.Initialize();
                using (DdeServer server = new TestServer("test"))
                {
                    server.Register();
                }
                Assert.IsTrue(listener.Received.WaitOne(5000, false));
            }
        }

        [Test]
        public void Test_Unregister()
        {
            using (DdeContext context = new DdeContext())
            {
                EventListener listener = new EventListener();
                context.Unregister += listener.OnEvent;
                context.Initialize();
                using (DdeServer server = new TestServer("test"))
                {
                    server.Register();
                    server.Unregister();
                }
                Assert.IsTrue(listener.Received.WaitOne(5000, false));
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

            public void OnEvent(object sender, DdeRegistrationEventArgs args)
            {
                _Events.Add(args);
                _Received.Set();
            }
        }
        #endregion

        #region TransactionFilter
        private sealed class TransactionFilter : IDdeTransactionFilter
        {
            private System.Threading.ManualResetEvent _Received     = new System.Threading.ManualResetEvent(false);
            private ArrayList                         _Transactions = new ArrayList();

            public IList Transactions
            {
                get { return ArrayList.ReadOnly(_Transactions); }
            }

            public System.Threading.WaitHandle Received
            {
                get { return _Received; }
            }

            public bool PreFilterTransaction(DdeTransaction t)
            {
                _Transactions.Add(t);
                _Received.Set();
                return false;
            }
        }
        #endregion

        #region TestServer
        private sealed class TestServer : DdeServer
        {
            public TestServer(string service) : base(service)
            {
            }

        } // class
        #endregion

    } // class

} // namespace