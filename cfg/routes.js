module.exports = {
	'/': {
		// get by default
		// method: 'get',
		controller: 'home',
		action: 'home'
	},
	// Routes are just ExpressJS - http://expressjs.com/api.html#req.params
	'/:some/:dynamic/:route': {
		controller: 'home',
		action: 'somethingElse'
	}
};