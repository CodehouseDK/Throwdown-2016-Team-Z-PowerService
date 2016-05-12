using System;
using System.Diagnostics;
using Microsoft.Extensions.Configuration;
using StackExchange.Redis;

namespace PowerService
{
    public class PowerApp
    {
        private static ConnectionMultiplexer _connection;
        private readonly string _dataChannelName = "powerservice";
        private readonly string _forwardChannelName = "hackaton";

        public PowerApp(IConfigurationSection section)
        {
            _connection = ConnectionMultiplexer.Connect(section.Value);

            Subscribe(Dump);
            Subscribe(Forward);
        }

        public static PowerApp Current { get; internal set; }

        private void Forward(string message)
        {
            _connection.GetSubscriber().Publish(_forwardChannelName, message);
        }

        private void Dump(string message)
        {
            Debug.WriteLine("Message: " + message);
        }

        public void Subscribe(Action<string> handler)
        {
            _connection.GetSubscriber().Subscribe(_dataChannelName, (channel, value) => { handler.Invoke(value.ToString()); });
        }
    }
}