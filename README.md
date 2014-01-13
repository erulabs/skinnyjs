Skinny.js
=======
Small simple and smart fullstack nodejs framework

by Seandon 'erulabs' Mooy -> admin@erulabs.com -> github.com/erulabs

    sudo npm install -g skinny.js

Make a new project and install skinny.js as a dep (an example package.json is provided):

    skinny new myAwesomeProject && cd myAwesomeProject
    npm install

Run the development server with:

    skinny server

Point your browser at http://localhost:9000 and watch as SkinnyJS:

  1) Recompiles SASS and Coffeescript whenever you make changes
  
  2) Reloads the browser and server modularly when needed
  
  3) Binds models to MongoDB collections automagically (other NoSQL databases coming soon)
  
  4) Is blazingly fast (\<1ms route->controller->action->response) because it _only_ serves static content
  
  5) Has the best controller / model syntax you've ever seen (hint: it's just javascript!!!)
  
  6) Makes every other MVC framework look bloated and opaque

Contributions and suggestions are encouraged!

The goal for SkinnyJS is to stay highly readable (<500LoC at most) while packing in as much functionality as possible. It will only ever expose well known libraries (express, mongo, etc), and should almost never catch errors (it should leave that to the underlying libraries).

It will never block or try to wrap tools like browserify or grunt/gulp, although useful 'starting' templates for them might be added. Skinny is meant to get you up, running, and writing code in seconds - like the "yeoman" projects, but without the bulk and bloat and the 5 hours of reading Grunt configs before understanding what your application is doing.

Currently it packages angular, bootstrap, and socketio, but they're only there as a convience and only socketio is actually used at all (for quick reload).

If you have any questions about SkinnyJS, I recommend reading the code FIRST, as that's the point of this project. Typically, most logical actions equate to one or two lines of code in skinny.coffee, so patching is probably easier than asking questions :P

Happy hacking!!!
