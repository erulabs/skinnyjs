module.exports = (app) ->
    # A small guide on writing compilers for Skinny:
    #  try to use the examples as a guide - most importantly,
    #  compilers are always just passed the _file path_ to the file which needs to be compiled
    #  so you'll need to read the file if your compiler works that way.
    #  - Additionally, try to use the "try require.resolve" pattern below.
    #  this causes Skinny to not "require" them, but will print a helpful message.
    #  this way, we hijack npm to be Skinny's package manager :D
    sass = false
    coffee = false
    less = false

    # Coffee-Script compiler
    app.compiler['.coffee'] = (file) ->
        # If we dont have the module, print a warning and return.
        try require.resolve 'coffee-script'
        catch error then return console.log app.clr.cyan+'CoffeeScript:'+app.clr.reset, 'not installed - try npm install "coffee-script"'
        coffee = require 'coffee-script' if !coffee
        app.fs.readFile file, 'utf8', (err, rawCode) =>
            console.log app.clr.red+'compileAsset() error:'+app.clr.reset, err if err
            console.log app.clr.cyan+'CoffeeScript:'+app.clr.reset, file.replace(app.cfg.path, '')
            try
                cs = coffee.compile rawCode
            catch error
                return console.log app.clr.red+'CoffeeScript error:'+app.clr.reset, file.replace(app.cfg.path, '')+':', error.message, "on lines:", error.location.first_line+'-'+error.location.last_line  
            unless error?
                app.fs.writeFile file.replace('.coffee', '.js'), cs, (err) -> console.log app.clr.red+'autocompile write error! file'+app.clr.reset, file.replace('.coffee', '.js'), 'error:', err if err
    
    # Node-Sass compiler
    app.compiler['.scss'] = (file) ->
        try require.resolve 'node-sass'
        catch error then return console.log app.clr.cyan+'SASS:'+app.clr.reset, 'not installed - try npm install "node-sass"'
        sass = require 'node-sass' if !sass
        console.log app.clr.cyan+'SASS:'+app.clr.reset, file.replace(app.cfg.path, '')
        sass.render 
            file: file
            success: (css) => app.fs.writeFile file.replace('.scss', '.css'), css, (err) -> console.log app.clr.red+'autocompile write error! file'+app.clr.reset, file.replace('.scss', '.css'), 'error:', err if err
            error: (error) => console.log app.clr.red+'SCSS Compile error:'+app.clr.reset, error
    
    # LESS compiler: http://lesscss.org
    app.compiler['.less'] = (file) ->
        try require.resolve 'less'
        catch error then return console.log app.clr.cyan+'LESS:'+app.clr.reset, 'not installed - try npm install "less"'
        if !less then less = require('less')
        less.render app.fs.readFileSync(file, 'utf8'), (err, css) ->
            app.fs.writeFile file.replace('.less', '.css'), css, (err) -> console.log app.clr.red+'autocompile write error! file'+app.clr.reset, file.replace('.less', '.css'), 'error:', err if err
