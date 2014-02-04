Skinny.js
=======
Small simple and smart fullstack nodejs framework

## Install

by Seandon 'erulabs' Mooy -> admin@erulabs.com -> github.com/erulabs

    sudo npm install -g skinny.js

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
