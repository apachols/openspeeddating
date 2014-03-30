# Requirements for testing
require 'should'
gently = new(require 'gently')

# Mock app
req =
res =
app =
  get: ->

# Test route
MeetupModel = require '../../../src/models/Meetup'
Main = require('../../../src/routes/main') app

# Test suite
describe 'src/routes/main.coffee', ->

  beforeEach ->
    req =
      logout: ->
      user: 'test'

    res =
      locals: ->
      redirect: ->
      render: ->

  describe '#get *', ->
    it 'should set up common vars for all routes', (done) ->
      res.locals = (args) ->
        args.brand.should.equal 'Homepage'
        args.my.should.equal 'test'
        done()

      Main.setup req, res, ->

  describe '#get /index', ->
    it 'should display error if error', (done) ->
      fakeerror = "everything is wrong"
      gently.expect MeetupModel, 'find', (args, callback) ->
        callback fakeerror, null

      res.send = (code, error) ->
        code.should.equal 500
        error.should.equal.fakeerror
        done()

      Main.index req, res

    it 'should display meetups if found', (done) ->
      fakemeetups = [{},{}]
      gently.expect MeetupModel, 'find', (args, callback) ->
        callback null, fakemeetups

      res.render = (view, meetups) ->
        view.should.equal 'index'
        meetups.should.equal.fakemeetups
        done()

      Main.index req, res


  describe '#get /logout', ->
    it 'should call req.logout', (done) ->
      req.logout = ->
        done()

      Main.logout req, res

    it 'should redirect to /', (done) ->
      res.redirect = (location) ->
        location.should.equal '/'
        done()

      Main.logout req, res
