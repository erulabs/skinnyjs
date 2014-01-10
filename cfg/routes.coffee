module.exports = (app) ->
	app.routes =
		'/':
			controller: 'home'
			action: 'home'
		'/somePost':
			method: 'post'
			controller: 'home'
			action: 'somePost'
	app.parseRoutes = () ->
		app._.each app.routes, (obj, route) ->
			app.server[obj.method or 'get'] route, (req, res) ->
				app.controllers[obj.controller]['*'](req, res) if app.controllers[obj.controller]['*']?
				console.log '('+req.connection.remoteAddress+')', req.method+':', req.url, obj.controller+'#'+obj.action
				res.view = app.cfg.layout.views+'/'+obj.controller+'/'+obj.action+'.html'
				controllerOutput = app.controllers[obj.controller][obj.action](req, res)
				if controllerOutput?
					return if res.headersSent or !controllerOutput
					controllerOutput = JSON.stringify controllerOutput if typeof controllerOutput == "object"
					res.send controllerOutput
				else
					res.sendfile res.view
	app.parseRoutes()