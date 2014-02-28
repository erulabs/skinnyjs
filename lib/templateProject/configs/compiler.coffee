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
    app.compiler['.coffee'] = (file, callback) ->
        # If we dont have the module, print a warning and return.
        try require.resolve 'coffee-script'
        catch error then return app.log app.clr.cyan+'CoffeeScript:'+app.clr.reset, 'not installed - try npm install "coffee-script"'
        coffee = require 'coffee-script' if !coffee
        app.fs.readFile file, 'utf8', (err, rawCode) =>
            app.log app.clr.red+'compileAsset() error:'+app.clr.reset, err if err
            app.log app.clr.cyan+'CoffeeScript:'+app.clr.reset, file.replace(app.cfg.path, '')
            try
                cs = coffee.compile rawCode
            catch error
                return app.log app.clr.red+'CoffeeScript error:'+app.clr.reset, file.replace(app.cfg.path, '')+':', error.message, error.description, error
            unless error?
                app.fs.writeFile file.replace('.coffee', '.js'), cs, (err) ->
                    if err
                        app.log app.clr.red+'autocompile write error! file'+app.clr.reset, file.replace('.coffee', '.js'), 'error:', err
                        callback(false) if callback?
                    else
                        callback(file) if callback?

    # Node-Sass compiler
    app.compiler['.scss'] = (file, callback) ->
        try require.resolve 'node-sass'
        catch error then return app.log app.clr.cyan+'SASS:'+app.clr.reset, 'not installed - try npm install "node-sass"'
        sass = require 'node-sass' if !sass
        app.log app.clr.cyan+'SASS:'+app.clr.reset, file.replace(app.cfg.path, '')
        sass.render 
            file: file
            success: (css) =>
                app.fs.writeFile file.replace('.scss', '.css'), css, (err) -> app.log app.clr.red+'autocompile write error! file'+app.clr.reset, file.replace('.scss', '.css'), 'error:', err if err
                callback(file) if callback?
            error: (error) =>
                app.log app.clr.red+'SCSS Compile error:'+app.clr.reset, error
                callback(false) if callback?

    # LESS compiler: http://lesscss.org
    app.compiler['.less'] = (file, callback) ->
        try require.resolve 'less'
        catch error then return app.log app.clr.cyan+'LESS:'+app.clr.reset, 'not installed - try npm install "less"'
        if !less then less = require('less')
        app.log app.clr.cyan+'LESS:'+app.clr.reset, file.replace(app.cfg.path, '')
        less.render app.fs.readFileSync(file, 'utf8'), (err, css) ->
            app.fs.writeFile file.replace('.less', '.css'), css, (err) ->
                if err
                    app.log app.clr.red+'autocompile write error! file'+app.clr.reset, file.replace('.less', '.css'), 'error:', err
                    callback(false) if callback?
                else
                    console.log(file) if callback?
