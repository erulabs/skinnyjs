#!/usr/bin/env node
var path 		= require('path');
var fs   		= require('fs');
var lib  		= path.join(path.dirname(fs.realpathSync(__filename)), '../lib');
var cmd 		= require('commander');
var SkinnyJs 	= require(lib + '/skinny.js');
var instance 	= new SkinnyJs();

//var myTest 		= instance.install({});

cmd
	.version('0.0.1')
	.option('new <projectDir>', 'Create new project')
	.option('server', 'Skinny Dev Server')
	.parse(process.argv);

if (cmd['new']) {
	instance.install(cmd['new']);
} else if (cmd['server']) {
	instance.init();
} else {
	cmd.help();
}