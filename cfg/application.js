module.exports = function (app) {
    app.web.use(app.express.compress());
    app.web.use(app.express.cookieParser('skinnySecret'));
};