module.exports = (app) ->
    coffee  = require 'coffee-script'
    sass    = require 'node-sass'
    colors  = { red: "\u001b[31m", blue: "\u001b[34m", green: "\u001b[32m", cyan: "\u001b[36m", reset: "\u001b[0m" }
    
    app.compiler['.coffee'] = (file) ->
        app.fs.readFile file, 'utf8', (err, rawCode) =>
            console.log colors.red+'compileAsset() error:'+colors.reset, err if err
            console.log colors.cyan+'CoffeeScript:'+colors.reset, file.replace(app.cfg.path, '')
            try
                cs = coffee.compile rawCode
            catch error
                return console.log colors.red+'CoffeeScript error:'+colors.reset, file.replace(app.cfg.path, '')+':', error.message, "on lines:", error.location.first_line+'-'+error.location.last_line  
            unless error?
                app.fs.writeFile file.replace('.coffee', '.js'), cs, (err) -> console.log colors.red+'autocompile write error! file'+colors.reset, file.replace('.coffee', '.js'), 'error:', err if err
    app.compiler['.scss'] = (file) ->
        sass.render 
            file: file
            success: (css) => app.fs.writeFile file.replace('.scss', '.css'), css, (err) -> console.log colors.red+'autocompile write error! file'+colors.reset, file.replace('.scss', '.css'), 'error:', err if err
            error: (error) => console.log('SCSS Compile error:', error);