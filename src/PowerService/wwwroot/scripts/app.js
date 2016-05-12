var output;
var widget;

function init() {
    output = document.getElementById("output");
    widget = document.getElementById("widget");

    print("Connecting...");

    websocket = new WebSocket("ws://localhost:51842");
    websocket.onopen = function (evt) { onOpen(evt) };
    websocket.onclose = function (evt) { onClose(evt) };
    websocket.onmessage = function (evt) { onMessage(evt) };
    websocket.onerror = function (evt) { onError(evt) };
}

function onOpen(evt) {
    print("Connected!");
}

function onClose(evt) {
    print("Disconnected...");

    init();
}

function onError(evt) {
    print('<span style="color: red;">ERROR:</span> ' + evt.data);
}

function print(message) {
    var pre = document.createElement("p");

    pre.innerHTML = message;

    output.appendChild(pre);
}

function onMessage(evt) {
    var data = JSON.parse(evt.data);
    var html = "<h1>CPU Load: " + Math.round(data.AverageLoad) + "%</h1>";

    html += "<h2>" + (data.AvailableMhz / 1000) + " Ghz available across " + data.AvailableCores + " cores on " + data.Computers + " workstations</h2>";
    html += "<h3>Updated: " + data.Timestamp + "</h3>";

    widget.innerHTML = html;
}

window.addEventListener("load", init, false);