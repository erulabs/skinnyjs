#!/usr/bin/env node
var skinnyjs = require('skinny.js'),
	skinny = new skinnyjs({
		port: 9000,
		reload: true
	}).init();