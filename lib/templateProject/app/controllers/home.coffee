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

		# Should you want complete control, and you want to make the browser wait for your response (not normally a good idea)
		# you can return { skip: true } and skinny will ignore the request the same as if you had sent headers.
		# Typically it's a better idea to "res.writeHead(200);" which will also tell skinny to ignore the request.
		# Be aware you're causing timeouts if you never respond to the request!

		# An example of using models:
		# models get their names from their file (so models/thing.js is app.models.thing)
		# they are automatically mongoDB collections, and that collection is model.db
		# (https://github.com/mongodb/node-mongodb-native "collection" object)
		
		# SO, onto mongo queries! A simple "raw" insert:
		# app.models.thing.db.insert { somedata: 'yay' }, (err, docs) -> console.log 'Yay, we inserted our model!'		
		
		# A simple find:
		# app.models.thing.find (results) -> console.log results
		
		# A more complex find:
		# app.models.thing.find { someFilter: 'foobar' }, (results) -> console.log results

		# Because models can be instantiated before mongo is ready, the raw collection object is now a function
		# on the model which returns the collection - example:
		# app.models.thing.collection().find()

		# It's important to note that your model functionality lives in both places (the model Class, and the model Instance).
		# For example: app.models.thing.someFunctionality() runs as expected
		# (assuming the function doesn't rely on some data thats ONLY in the database) but also:
		# app.models.thing.find (results) -> results[0].someFunctionality()

		# Likewise, you can create models by invoking the models .new() function or just directly insert data into the database
		# the only difference being that .new() can be overridden by the model

		# some example functionality:
		# app.models.thing.remove()
		# myThing = app.models.thing.new()
		# console.log 'some functionality:', myThing.someFunctionality()
		# app.models.thing.find (results) ->
		#	console.log results

		# explicitly tell skinny to render our view - this is inherently the output of javascript functions which do not "return"
		# but sometimes (in the case of using coffee-script)
		return undefined