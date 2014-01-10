Skinny.js
=======
A micro ORM-less Javascript MVC Framework that makes your MVC look fat

by Seandon 'erulabs' Mooy -> admin@erulabs.com -> github.com/erulabs

The install process will be improved shortly when Skinny.js gets closer to a 0.1 (npm) release. For now:

    git clone git@github.com:erulabs/skinnyjs
    cd skinnyjs && npm install && cd ..

Then make a new project (this will also be improved soon - wrapped in a 'skinny' runner):

    mkdir killerProject && cd killerProject
    node ../skinnyjs/test/init.js
    npm install node-sass coffee-script
    node app/server.js

Point your browser at http://localhost:9000 and watch as SkinnyJS:

  1) Recompiles SASS and Coffeescript whenever you make changes
  
  2) Reloads the browser and server modularly when needed
  
  3) Binds models to MongoDB collections automagically (other NoSQL databases coming soon)
  
  4) Is blazingly fast (\<1ms route->controller->action->response) because it _only_ serves static content
  
  5) Has the best controller / model syntax you've ever seen (hint: it's just javascript!!!)
  
  6) Makes every other MVC framework look bloated and opaque

Contributions and suggestions are encouraged!

The goal for SkinnyJS is to stay highly readable (<500LoC at most) while packing in as much functionality as possible. It will only ever expose well known libraries (express, mongo, etc), and should almost never catch errors (it should leave that to the underlying libraries).

It will never block or try to wrap tools like browserify or grunt/gulp, although useful 'starting' templates for them might be added. Skinny is meant to get you up, running, and writing code in seconds - like the "yeoman" projects, but without the bulk and bloat and the 5 hours of reading Grunt configs before understand what your application is doing.

Currently it packages angular, bootstrap, and socketio, but they're only there as a convience.

If you have any questions about SkinnyJS, I recommend reading the code FIRST, as that's the point of this project. Typically, most logical actions equate to one or two lines of code in skinny.coffee, so patching is probably easier than asking questions :P

Happy hacking!!!
