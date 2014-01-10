module.exports = (app) ->
    #'*': () -> # Catch all route
    home: (req, res) ->
        # do things for home page here