module.exports = {
	'/': {
		// GET by default
		// method: 'GET',
		controller: 'home',
		action: 'home'
	},
	// Routes are just ExpressJS - http://expressjs.com/api.html#req.params
	'/:some/:dynamic/:route': {
		controller: 'home',
		action: 'somethingElse'
	}
};