asset = require 'assert'
path = require 'path'
fs = require 'fs'
should = require 'should'
rimraf = require 'rimraf'

if path.sep is '/'
	skinnyjs = require(__dirname + '/../lib/skinny.js');
else
	skinnyjs = require('c:\\Users\\eru\\Documents\\GitHub\\skinnyjs\\lib\\skinny.js');

testdir = path.dirname(__filename) + path.sep + '__skinnyTest'

tests = () ->
	fs.mkdirSync testdir

	skinny = new skinnyjs 
		port: 9001
		reload: true
		path: testdir
		env: 'test'

	## INSTALL
	describe "skinny", () ->
		describe ".install()", () ->
			it "should install correctly", (installComplete) ->
				skinny.install testdir, () ->
					installComplete()

					## INIT
					describe "skinny", () ->
						describe ".init()", () ->
							it "should boot correctly", (initComplete) ->
								skinny.init (app) ->
									app.server.use app.express.urlencoded()
									app.server.use '/assets', app.express.static(app.cfg.layout.assets)
									initComplete()

									## INIT MODEL
									describe "app", () ->
										describe ".initModel()", () ->
											it "should get correct functionality appended", (initModelComplete) ->
												test = app.initModel({ _id: '__skinnyTest' }, '__test')
												initModelComplete()

												## MODEL .NEW()
												describe "models", () ->
													it "should create instances without error", (instanceCreateComplete) ->
														instance = test.new()
														instanceCreateComplete()

														## MODEL .SAVE()
														describe "model instances", () ->
															it "should save without error", (instanceSaveComplete) ->
																instance.save () ->
																	instanceSaveComplete()

																	## MODEL .REMOVE()
																	describe "model instances", () ->
																		it "should delete without error", (instanceDeleteComplete) ->
																			instance.remove () ->
																				instanceDeleteComplete()

												## MODEL .FIND()
												describe "models", () ->
													describe ".find()", () ->
														it "should find without error", (findComplete) ->
															test.find (results) ->
																findComplete()

									## PARSE ROUTES
									describe ".parseRoutes()", () ->
										it "should save routes without error", (parseRoutesTestComplete) ->
											app.routes =
												'/__test': {
													controller: '__test',
													action: '__test1'
												}
											app.parseRoutes()
											parseRoutesTestComplete()

									## CONTROLLER CREATION
									describe "controllers", () ->
										it "should create without issue", (controllerCreateTest) ->
											testControllerPath = testdir + path.sep + 'app' + path.sep + 'controllers' + path.sep + '__test.js'
											testControllerJS = 'modules.export = { "__test1": function() { return "__testData"; } };'
											fs.writeFileSync testControllerPath, testControllerJS
											controllerCreateTest()

									#describe ""

											#if app.controllers['__test']?
											#	controllerCreateTest()
											#else
											#	throw new Error('controller wanst found');
# cleanup
after (done) ->
	rimraf testdir, () ->
		done()

if fs.existsSync testdir
	throw new Error('test dir exists, exiting')
else
	tests()