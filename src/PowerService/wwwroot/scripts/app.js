require("../styles/widget.css");

var Gauge = require("../scripts/gauge.min.js").Gauge;

window.powerservice = (function () {
    var exports = {};
  
    exports.init = function (id, url) {
        console.log("connecting...");

        // UI crap, sorry mum...
        var widget = document.getElementById(id);
        var container = document.createElement("div");

        container.id = "powercontainer";

        widget.appendChild(container);

        var cpuLoad = document.createElement("div");

        cpuLoad.id = "powerload";
        cpuLoad.innerHTML = "<h1>CPU load 0%</h1>";

        container.appendChild(cpuLoad);

        var canvas = document.createElement("canvas");

        canvas.id = "powercanvas";

        container.appendChild(canvas);
       
        var stats = document.createElement("div");

        stats.id = "powerstats";
        stats.innerHTML = "<h2>0 Ghz, 0 cores, 0 workstations</h2>";

        container.appendChild(stats);

        var opts = {
            lines: 15,
            angle: 0.15,
            lineWidth: 0.35,
            pointer: {
                length: 0.9,
                strokeWidth: 0.044,
                color: '#000000'
            },
            limitMax: 'true',
            percentColors: [[0.0, "#68A691"], [0.50, "#ED8161"], [1.0, "#FF95A2"]],
            strokeColor: '#E0E0E0',
            generateGradient: true
        };

        var cpuGauge = new Gauge(document.querySelector("#powercanvas")).setOptions(opts); 

        cpuGauge.maxValue = 100;
        cpuGauge.animationSpeed = 20;
        
        // The real stuff...
        connect(url, cpuLoad, cpuGauge, stats);
    };

    function connect(url, cpuLoad, cpuGauge, stats) {
        var socket = new WebSocket(url);

        socket.onopen = function (event) { console.log("connected", event); };
        socket.onerror = function (event) { console.log("socket error", event); };
        socket.onclose = function (event) {
            console.log("disconnected...", event);

            connect(url, cpuLoad, cpuGauge, stats);
        };
        
        socket.onmessage = function (event) {
            var data = JSON.parse(event.data);

            cpuLoad.innerHTML = "<h1>CPU load ~" + Math.round(data.AverageLoad) + "%</h1>";
            cpuGauge.set(data.AverageLoad);
            stats.innerHTML = "<h2>" + Math.round(data.AvailableMhz / 1000) + " Ghz, " + data.AvailableCores + " cores, " + data.Computers + " workstations, updated " + data.Timestamp.substring(data.Timestamp.indexOf("T") + 1, data.Timestamp.indexOf(".")) + "</h2>";
        };
    }

    return exports;
})();