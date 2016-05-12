using System.Net.WebSockets;
using Microsoft.AspNet.Builder;
using Microsoft.AspNet.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace PowerService
{
    public class Startup
    {
        public Startup(IHostingEnvironment env)
        {
            var builder = new ConfigurationBuilder()
                .AddJsonFile("appsettings.json")
                .AddEnvironmentVariables();

            Configuration = builder.Build();
        }

        public IConfigurationRoot Configuration { get; set; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddMvc();
        }

        public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory)
        {
            loggerFactory.AddConsole(Configuration.GetSection("Logging"));
            loggerFactory.AddDebug();

            PowerApp.Current = new PowerApp(Configuration.GetSection("RedisConfiguration"));
            PowerApp.Current.Subscribe(Broadcast);

            app.UseIISPlatformHandler();
            app.UseStaticFiles();
            app.UseMvc();
            app.UseWebSockets();

            app.Use(async (http, next) =>
            {
                if (http.WebSockets.IsWebSocketRequest)
                {
                    var socket = await http.WebSockets.AcceptWebSocketAsync();

                    if (socket != null && socket.State == WebSocketState.Open)
                    {
                        WebSocketConnections.AddSocket(socket);
                    }
                }
                else
                {
                    await next();
                }
            });
        }

        private void Broadcast(string message)
        {
            // TODO: Transform message...

            WebSocketConnections.Broadcast(message).Wait();
        }

        public static void Main(string[] args) => WebApplication.Run<Startup>(args);
    }
}