module.exports = function(app) {
  return {
    someProp: 'hello',
    name: 'a Thing',
    someFunc: function() {
      return console.log('I am:', this.name);
    }
  }
}