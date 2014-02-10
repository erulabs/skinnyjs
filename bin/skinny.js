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
	.option('generate <type> <name>', 'Generate a template module (only type=model works now - more generators coming soon)')
	.parse(process.argv);

if (cmd['new']) {
	var SkinnyJs = require(lib + '/skinny.js');
	var instance = new SkinnyJs();
	instance.install(cmd['new']);
} else if (cmd['server']) {
	require(fs.realpathSync('./app/server.js'));
} else if (cmd['generate']) {
	// This is massivly incorrect, but it does work assuming everything is as default.
	// This should be using skinny.cfg.layout instead
	if (cmd['generate'] === 'model') {
		var template = fs.readFileSync(lib + '/templateProject/app/models/thing.js')
		fs.writeFileSync('./app/models/' + cmd.args[0] + '.js', template);
	} else if (cmd['generate'] === 'controller') {
		var template = fs.readFileSync(lib + '/templateProject/app/controllers/home.js')
		fs.writeFileSync('./app/controllers/' + cmd.args[0] + '.js', template);
	} else {
		cmd.help();
	}
} else {
	cmd.help();
}