module.exports = (app) ->
	app.routes =
		'/':
			controller: 'home'
			action: 'home'
		'/somePost':
			method: 'post'
			controller: 'home'
			action: 'somePost'
	app.parseRoutes()