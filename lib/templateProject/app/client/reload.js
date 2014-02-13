var socket = io.connect('http://' + window.location.host);
// Quick reload event
socket.on('__skinnyjs', function (data) {
    if (data.reload !== undefined) {
        setTimeout(function (){
            window.location = window.location.href.toString();
        }, data.reload.delay);
    } else if (data.error !== undefined) {
    	console.log('server error', data.error);
        alert('SkinnyJS error! See console output');
        //document.write("<pre class='error'>" + JSON.stringify(data.error) + "</pre>");
    }
});