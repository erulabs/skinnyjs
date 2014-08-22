module.exports = (app) ->
	'*': () ->
		# Catch all route
		# this method will be run before any other method on this controller
	home: (req, res) ->
		# This is a controller!

		# You can manually work with express if you'd like (using the req, res objects), for instance:
		# res.send("Hello world!");

		# But for convience, Skinny will pass any output here down the wire. For instance:
		# return "Hello World!";
		# is exactly the same as the example above.
		# In coffee-script, return is automatically appended to the last line of functions
		# So a valid controller method is:
	hello: () -> "Hello World!"
		# But it doesn't stop there! Skinny is smart enough to make sense of this too:
	api: () -> { some: 'json' }
		# You can also return nothing (or explicitly "undefined"), in which case Skinny will assume
		# that you want to use a view (it'll look in app/views/{{ controller }}/{{ action }}.html)

		# For async calls, you can return the request object and skinny will ignore the request the same as if you had sent headers.
		
		# If that wasn't clear - since skinny assumes "return undefined" (the default output of a function)
		# means "render a view", if you intend to do async or delayed actions, you can return the request object (or send headers)
		# An example:
		# 	setTimeout(() ->
		#		res.send("hello world!");
		# 	, 2000)
		# 	return req
		# or in coffee-script just:
		#	someAsync() -> ...
		#	req

		# Typically it's a better idea to just "res.writeHead 200" which skinny will notice and assume
		# you will complete the response on your own Be aware you're causing timeouts if you never respond to the request!

		# An example of using models:
		# models get their names from their file (so app/models/thing.js is app.models.thing)
		# they are automatically mongoDB collections, and that collection is app.models.thing.db
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
		# in the case of using coffee-script it can be easy to return something unintentionally since 'return' is prepended to the last
		# line of any function that doesn't have a return. Because of that, it's nice to just "return undefined" to be clear about whats happening
		# "return undefined" means "render the view named home#home or app/views/home/home.html"
	someView: () ->
		return undefined
