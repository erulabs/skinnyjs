#!/usr/bin/env node

var path = require('path'),
	fs = require('fs');

// Standard:
var skinnyjs = require('skinnyjs');

// Development mode:
// Linux/osX, etc:
/*if (path.sep === '/') {
	var skinnyjs = require('skinnyjs');
	// Development path example:
	// var skinnyjs = require('/home/eru/projects/skinnyjs/libs/skinny.js');
// Windows
} else {
	// An example for windows to use a development path
	// var skinnyjs = require(fs.realpathSync('c:\\Users\\eru\\Documents\\GitHub\\skinnyjs\\lib\\skinny.js'));
}*/

var skinny = new skinnyjs({
	port: 9000,
	reload: true
}).init(function (app) {
	// Use urlencoded (allows options in req.body)
	app.server.use(app.express.urlencoded());
	// Setup static routes:
	app.server.use('/assets', app.express.static(app.cfg.layout.assets));
});
