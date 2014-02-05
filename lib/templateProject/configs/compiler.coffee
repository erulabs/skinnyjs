module.exports = (app) ->
    coffee  = require 'coffee-script'
    sass    = require 'node-sass'
    app.compiler['.coffee'] = (file) ->
        app.fs.readFile file, 'utf8', (err, rawCode) =>
            console.log app.colors.red+'compileAsset() error:'+app.colors.reset, err if err
            console.log app.colors.cyan+'CoffeeScript:'+app.colors.reset, file.replace(app.cfg.path, '')
            try
                cs = coffee.compile rawCode
            catch error
                return console.log app.colors.red+'CoffeeScript error:'+app.colors.reset, file.replace(app.cfg.path, '')+':', error.message, "on lines:", error.location.first_line+'-'+error.location.last_line  
            unless error?
                app.fs.writeFile file.replace('.coffee', '.js'), cs, (err) -> console.log app.colors.red+'autocompile write error! file'+app.colors.reset, file.replace('.coffee', '.js'), 'error:', err if err
    app.compiler['.scss'] = (file) ->
        sass.render 
            file: file
            success: (css) => app.fs.writeFile file.replace('.scss', '.css'), css, (err) -> console.log app.colors.red+'autocompile write error! file'+app.colors.reset, file.replace('.scss', '.css'), 'error:', err if err
            error: (error) => console.log('SCSS Compile error:', error);