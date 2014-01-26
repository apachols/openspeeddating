User = require('../models/User')
Profile = require('../models/Profile')

class Profile
  constructor: (@app) ->
    @app.all /^\/profile/, @auth

    @app.get '/profile', @get

    @app.get '/profile/update', @update

  auth: (req, res, next) ->
    return res.send 'boo-urns', 401 unless req.isAuthenticated()
    next()

  get: (req, res) ->
    res.render 'profile', {
      brand: 'Profile'
      user: req.user
    }

  update: (req, res) ->
    console.log('UPDATE')

    User.findOne
      email: req.user.email
    , (err, userdoc) ->
      console.dir(userdoc)
      userdoc.profile =
        gender: 'F'
        genderSought: 'F'
        genderSecond: 'F'
        age: 24
        ageSoughtMin: 24
        ageSoughtMax: 24
      userdoc.save()

    res.redirect '/profile'



module.exports = (app) -> new Profile app
