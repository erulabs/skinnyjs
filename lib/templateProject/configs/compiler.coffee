module.exports = (app) ->
    coffee  = require 'coffee-script'
    sass    = require 'node-sass'
    app.compiler['.coffee'] = (file) ->
        app.fs.readFile file, 'utf8', (err, rawCode) =>
            console.log app.clr.red+'compileAsset() error:'+app.clr.reset, err if err
            console.log app.clr.cyan+'CoffeeScript:'+app.clr.reset, file.replace(app.cfg.path, '')
            try
                cs = coffee.compile rawCode
            catch error
                return console.log app.clr.red+'CoffeeScript error:'+app.clr.reset, file.replace(app.cfg.path, '')+':', error.message, "on lines:", error.location.first_line+'-'+error.location.last_line  
            unless error?
                app.fs.writeFile file.replace('.coffee', '.js'), cs, (err) -> console.log app.clr.red+'autocompile write error! file'+app.clr.reset, file.replace('.coffee', '.js'), 'error:', err if err
    app.compiler['.scss'] = (file) ->
        console.log app.clr.cyan+'SASS:'+app.clr.reset, file.replace(app.cfg.path, '')
        sass.render 
            file: file
            success: (css) => app.fs.writeFile file.replace('.scss', '.css'), css, (err) -> console.log app.clr.red+'autocompile write error! file'+app.clr.reset, file.replace('.scss', '.css'), 'error:', err if err
            error: (error) => console.log('SCSS Compile error:', error);