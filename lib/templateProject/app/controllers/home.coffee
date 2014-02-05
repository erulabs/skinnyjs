module.exports = (app) ->
	'*': () ->
		# Catch all route
		# this method will be run before any other method on this controller (per request)
	home: (req, res) ->
		# This is a controller!
		# Take some action based on a route here

		# You can manually work with express if you'd like (using the req, res objects), for instance:
		# res.send("Hello world!");
		# Skinny will see that you've sent headers and leave your code alone

		# But you don't _have_ to work with express directly. For instance, Skinny will pass any output here
		# down the wire (if headers haven't yet been sent once this function returns). As an example:
		# return "Hello World!";
		# is exactly the same as the example above.

		# But it doesn't stop there! Skinny is smart enough to make sense of this too:
		# return { some: 'json' }

		# You can also return nothing (or explicitly "undefined"), in which case Skinny will assume
		# that you want to use a view (it'll look in app/views/CONTROLLERNAME/ACTIONNAME.html)
		# if we've dropped all the way down here and that file doesn't exist, then we'll finally 404