#!/usr/bin/env node
var path 		= require('path');
var fs   		= require('fs');
var skinnyPath  = path.dirname(fs.realpathSync(__filename));
var lib  		= skinnyPath + '/../lib';
var cmd 		= require('commander');
cmd
	.version(JSON.parse(fs.readFileSync(skinnyPath + '/../package.json')).version)
	.option('new <projectDir>', 'Create new project')
	.option('server', 'Skinny Dev Server')
	.option('generate <name>', 'Generate a template/example model (more generators coming soon)')
	.parse(process.argv);

if (cmd['new']) {
	var SkinnyJs = require(lib + '/skinny.js');
	var instance = new SkinnyJs();
	instance.install(cmd['new']);
} else if (cmd['server']) {
	require(fs.realpathSync('./app/server.js'));
} else if (cmd['generate']) {
	var template = fs.readFileSync(lib + '/templateProject/app/models/thing.js')
	fs.writeFileSync('./app/models/' + cmd['generate'] + '.js', template);
} else {
	cmd.help();
}