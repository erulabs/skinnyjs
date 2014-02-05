#!/usr/bin/env node
var skinnyjs = require('skinny.js');
var skinny = new skinnyjs({
	port: 9000,
	reload: true
}).init(function () {
	// Use GZIP for requests:
	skinny.server.use skinny.express.compress()
	// Setup static routes:
	skinny.server.use '/views', skinny.express.static skinny.cfg.layout.views
	skinny.server.use '/assets', skinny.express.static skinny.cfg.layout.assets
});