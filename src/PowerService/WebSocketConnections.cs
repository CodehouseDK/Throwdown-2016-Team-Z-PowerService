using System;
using System.Collections.Concurrent;
using System.Linq;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace PowerService
{
    public class WebSocketConnections
    {
        static readonly ConcurrentBag<WebSocket> _sockets = new ConcurrentBag<WebSocket>();

        public static void AddSocket(WebSocket socket) => _sockets.Add(socket);

        public static async Task Broadcast(string message)
        {
            await Task.WhenAll(_sockets.Where(s => s.State == WebSocketState.Open).Select(async socket =>
            {
                var send = Encoding.UTF8.GetBytes(message);

                await socket.SendAsync(new ArraySegment<byte>(send, 0, send.Length), WebSocketMessageType.Text, true, CancellationToken.None);
            }));
        }
    }
}