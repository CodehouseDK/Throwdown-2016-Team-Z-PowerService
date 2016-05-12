var output;

function init() {
    output = document.getElementById("output");

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

function onMessage(evt) {
    print('<span style="color: blue;">' + evt.data + '</span>');
}

function onError(evt) {
    print('<span style="color: red;">ERROR:</span> ' + evt.data);
}

function print(message) {
    var pre = document.createElement("p");

    pre.innerHTML = message;

    output.appendChild(pre);
}

window.addEventListener("load", init, false);