var socket = io.connect('http://' + window.location.host);
// Quick reload event
socket.on('__reload', function (data) {
    console.log('reloading in', data.delay, 'ms');
    setTimeout(function (){
        window.location = 'http://' + window.location.host;
    }, data.delay);
});