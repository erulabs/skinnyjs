Skinny.js
=======
__A very small, very fast, and very simple 'fullstack' NodeJS framework__.

by Seandon 'Eru' Mooy -> admin@erulabs.com -> https://github.com/erulabs

Featuring:

1. Very fast live reload via bundled socket.io
2. A simple and familiar route -> controller -> model -> view setup - if you've used an MVC framework before you'll wonder why they are tens of thousands of lines of code.
3. Coffee-script and Sass built right in, but not required whatsoever. Check configs/compiler.js in your skinny app!
4. A MongoDB wrapper that will make you wonder why most NodeJS framworks are thousands of lines of code
5. Basically nothing else!

## Install

    sudo npm install -g skinnyjs

Make a new project and install skinny.js as a dep (an example package.json is provided):

    skinny new myAwesomeProject && cd myAwesomeProject
    npm install

Run the development server with:

    skinny server

Point your browser at http://localhost:9000!

## Working with Skinny

You can now modify files in your application - if you used "skinny new project", you'll have a default "app/views/home/home.html". This is the view for "/" (as defined in cfg/routes). There is no magic happening to this HTML file - no parsing ever occurs, no templating or DOM manipulation. It's simply gzipped and sent down the wire! This rigidity helps Skinny stay fast and simple.

Contributions and suggestions are encouraged!

## Design goals

The goal for SkinnyJS is to stay highly readable (<500LoC at most) while packing in as much functionality as possible. The aim is to provide a sane, simple, and well tested startingpoint for full stack web applications.

Currently it packages angular, bootstrap, and socketio, but they're only there as a convience and only socketio is actually used at all (for quick reload).

If you have any questions about SkinnyJS, I recommend reading the code FIRST, as that's the point of this project. Typically, most logical actions equate to one or two lines of code in skinny.coffee, so patching is probably easier than asking questions :P

Happy hacking!!!

## Development

I recommend running skinny this way if you plan on contributing to Skinny.js:

    git clone git@github.com:erulabs/skinnyjs.git

Add skinny.js to your path or alias:

    alias skinny=`pwd`/skinnyjs/bin/skinny.js

Create a new project:

    skinny new awesomeProject

Modify the project to use your development version of skinny:

in 'myawesomeProject/app/server.js' change `skinnyjs = require('skinny.js')` to something like:

    skinnyjs = require('../../skinnyjs/lib/skinny.js')

You can then run something like "coffee -cw ." in the skinnyjs directory - keep in mind your skinny server _will not_ automatically reload when skinnyjs is changed. You'll need to stop and start the server manually.

# Documentation?

Skinny automatically includes all .js files in directories defined by skinny.cfg.moduleTypes - by default that means: 'configs', 'models', and 'controllers'.

Files in each directory (the directories correspond to these names in skinny.cfg.layout) are automatically required as `skinny[moduleType][configName]`. That is another way of saying if there is a file in `./configs/` called Application.js, then when Skinny is available (`.init(callback)` in app/server.js), `skinny.configs['Application']` will be the value of `require('/configs/Application.js')`.

However, if the value of `require(modulePath)` is a function, Skinny will call it and pass itself as the first argument (ie: `require(modulePath)(skinny)`). For example, most files ought to start like:

    modules.export = (skinny) ->
      # some code here

Files loaded from the 'models' directory are further modified with features connecting them to a MongoDB database, while files loaded from the 'controllers' directory are targeted by 'config/routes.js'. Even that file isn't required, infact, you can easily delete that directory setup and modify your layout in app/server.js.

As for the client side, I'm not sure I plan on adding anything but the simple socket.io setup by default. Angular is there along with bootstrap because that's what I end up using for every project :P Skinny is going to stay lean and I'd like that it not lose sight of front-end designers or learners who don't want a ton of prepackaged nonsense. If you think you have ultra lightweight ways of making the front-end js kickass, please share! :D

Here is a description of the template layout:

####app/server.js:
the entire application! Read the code! Here is where you can set skinny.cfg before skinny boots up
####app/client/:
automatically mapped to SERVER/assets and is where static frontend files live.
####app/controllers/:
default place to put controller-like things
####app/models/:
files here which expose functions are automatically made into mongoDB collections and appended with functionality (see the models section)
####app/views/:
files which are sent automatically by the skinny router/controller system.
####configs/:
some nice server modules - populate .compiler and .routes, and a nice friendly application.coffee

## configs

  As before, the exact names of the files dont matter, and they're all just functions anyways. So what I'll talk about here is the template that you get when you type  `skinny new projectName`
  
  Nothing is done to these files except that the container is executed - they're run immediatly when skinny starts, and they'll be automatically removed and re-required when they're changed. This is where you can scaffold any random nodejs script and have awesome autoreload/autorun and errorcatching with vim (this is my main use of skinny :P)

####configs/application.js
A friendly welcome!
####configs/routes.js
This is just Express.js - skinny.server is the express object, so you can easily do things like:

    skinny.server.use skinny.express.bodyParser()

directly on the object if you want, but the skinny.routes object is just a nice and easy way of targeting controllers and actions. There is nothing stopping you from doing:

    skinny.server.get '/someRoute', (req, res) ->

and using Express (ie: side stepping skinny). Read parseRoutes() here: https://github.com/erulabs/skinnyjs/blob/master/lib/skinny.coffee#L148

####configs/compiler.js
Skinny defaults with a coffee-script and node-sass plugin. You can add more and they too will be automatically reloaded into the app. They are run whenever a file in /app or /configs is changed which has a file extention that matches a compiler. ie:

    skinny.compiler['.coffee'] = (file) -> # Compile Coffee!

## models

  Model files are special - they're wrapped up tight with MongoDB. The collection they create is equal to the filename - ie: app/models/thing.js is skinny.db.collection('thing'). If you don't want Skinny to wrap the db results, just call the db directly! Essentially, the code says it all: https://github.com/erulabs/skinnyjs/blob/master/lib/skinny.coffee#L30
  
  That's it! That's all it is! The function your file returns (module.exports = () ->) is now at `skinny.models[ModelName]`, is a MongoDB collection, and gets functions like:
  
### .find()
  This is just mongodb's .find. Skinny uses https://github.com/mongodb/node-mongodb-native - specifically, it _is_: https://github.com/mongodb/node-mongodb-native#find - the difference is that the resulting objects are exnteded with the  values in the app/models/ file. As said before, use "skinny.db.collection(ModelName)" for direct access.

### .new()
  Just returns an instance of `require(ModelFile)(skinny)`. app.model.counter.new().save() == "worlds easiet hit counter" :P
  
### .remove()
  Deletes the mongoDb entry. It does not however, delete the Javascript var. So you can just .save() again later if you want.
  

## Instances

The instances that the model functions above (.fine, .new, etc) return have the following methods automatically added:
  
### .save()
  
  https://github.com/mongodb/node-mongodb-native#save :P In other words: skinny.db.collection(ModelName).save(myModelInstance)
  
### .remove()
  
  Oh my gosh you get the idea already. Geez. <3
  
  app/models/thing.js: An example model with a dummy function - becomes available to controllers with skinny.models.thing

## controllers

  app/controllers/home.js: An example controller which has some nice documentation text in it. I suggest you read it next! :D
  

# Thanks!

  Would like to thank anyone who uses my code! Please don't hesitate to let me know if you run into issues! I'd love to help!
  
  - Seandon
