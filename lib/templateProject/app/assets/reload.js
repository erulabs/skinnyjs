var socket = io.connect('http://' + window.location.host);
// Quick reload event
socket.on('__skinnyjs', function (data) {
    if (data.reload !== undefined) {
        setTimeout(function (){
            window.location = 'http://' + window.location.host;
        }, data.reload.delay);
    } else if (data.error !== undefined) {
    	console.log('server error', data.error);
        document.write("<pre class='error'>" + JSON.stringify(data.error) + "</pre>");
    }
});