var widget;

function init() {
    widget = document.getElementById("widget");

    console.log("connecting...");

    websocket = new WebSocket("ws://localhost:51842");
    websocket.onopen = function (evt) { onOpen(evt) };
    websocket.onclose = function (evt) { onClose(evt) };
    websocket.onmessage = function (evt) { onMessage(evt) };
    websocket.onerror = function (evt) { onError(evt) };
}

function onOpen(evt) {
    console.log("connected.");
}

function onClose(evt) {
    console.log("disconnected...");

    init();
}

function onError(evt) {
    console.log("socket error")
}

function onMessage(evt) {
    var data = JSON.parse(evt.data);
    var html = "<h1>CPU Load: " + Math.round(data.AverageLoad) + "%</h1>";

    html += "<h2>" + Math.round(data.AvailableMhz / 1000) + " Ghz available across " + data.AvailableCores + " cores on " + data.Computers + " workstations</h2>";
    html += "<h3>Updated: " + data.Timestamp + "</h3>";

    widget.innerHTML = html;
}

window.addEventListener("load", init, false);