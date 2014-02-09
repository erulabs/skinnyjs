asset = require 'assert'
path = require 'path'
fs = require 'fs'
skinnyjs = require '../../skinnyjs/lib/skinny.js'

skinny = new skinnyjs 
	port: 9001
	reload: true
	path: (__dirname + '/../')
	env: 'test'

testOne = () ->
	describe "skinny", () ->
		describe ".init()", () ->
			it "should boot correctly", (initComplete) ->
				skinny.init (app) ->
					app.server.use app.express.urlencoded()
					app.server.use '/assets', app.express.static(app.cfg.layout.assets)
					initComplete()
					if testTwo? then testTwo()

testOne();