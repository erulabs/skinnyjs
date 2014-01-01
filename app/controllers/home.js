module.exports = function (app) {
    // Any code here will be run when the controller is initialized
    return {
        '*': function () {
            // This is a catch all method, and will be run _before_ any other method is run
        },
        // Controllers have many methods...
        home: function (req, res) {
            // An example of using a model
            var thing = new app.models.thing();
            console.log('model thing', thing);

            // A model is simply a mongodb collection - nothing more, nothing less
            //thing.find().toArray(function (err, things) {
            //  console.log('Array of model Things:', things);
            //});
            // However, eruslab offers some shortcuts as well (the exact same as above):
            //thing.all(function (things) {
            //    console.log('A list of Things:', things);
            //});
            // returning a bool (true or false) tells eru's lab not to end this request
            // ie: "return false" is another way of saying "we'll reply when we're goddamn good and ready"
            // Since we're not doing anything async here, we'll leave this commented out
            // return false;
        }
    }
};