MeetupModel = require '../models/meetup'
Matcher     = require '../lib/Matcher'
Scheduler   = require '../lib/Scheduler'

{inspect}   = require 'util'
{basename}  = require 'path'
_           = require 'lodash'

class Meetup
  constructor: (@app) ->

    @app.get  '/meetups/add', @add
    @app.post '/meetups/create', @create

    @app.get  '/meetup/:name/edit', @edit
    @app.post '/meetup/:name/update', @update

    @app.get  '/meetup/:name/register', @register
    @app.get  '/meetup/:name/unregister', @unregister

    @app.get  '/meetup/:name/schedules', @schedules
    @app.get  '/meetup/:name/generate', @generate

    @app.get  '/meetup/:name/schedule/:user', @name

    @app.get  '/meetups', @index
    @app.get  '/meetup/:name', @name

    @app.locals
      dateformat: 'mm/dd/yyyy'
      timeformat: 'hh:mm TT'

  index: (req, res) ->
    MeetupModel.find {}, (err, meetups) ->
      res.send 200, {meetups}

  add: (req, res) ->
    res.render 'meetups/add', {schema: MeetupModel.schema}

  create: (req, res) ->
    meetup = new MeetupModel req.body
    meetup.save (err, m) ->
      if err then res.send err, 400
      else res.redirect "/meetup/#{m.name}"

  edit: (args...) => @name args...
  name: (req, res) =>
    {params: {name, user}, route: {path}} = req
    user ?= req.user?.email

    # This is a little ugly
    view = @stripView path
    if view is 'user' then view = 'name'

    MeetupModel.findOne {name}, (err, meetup) ->
      done = (matches = {}) ->
        res.render "meetups/#{view}", {meetup, matches}

      return res.send 404, err if err
      if user then meetup.getScheduleUser user, done else do done

  stripView: (path) -> "#{basename path}".replace /\:/, ''

  register: (args...) => @unregister args...
  unregister: (req, res) =>
    {user, params: {name}, route: {path}} = req

    data = {registered: user.email}

    switch @stripView path
      when 'register' then query = {$push: data}
      when 'unregister' then query = {$pull: data}

    MeetupModel.findOneAndUpdate {name}
    , query
    , (err, meetup) ->
      meetup.registered = _.uniq meetup.registered
      meetup.save()
      res.redirect "/meetup/#{name}"

  schedules: (req, res) ->
    {name} = req.params
    MeetupModel.findOne {name}, (err, meetup) ->
      meetup.getScheduleAll (matches) ->
        res.render 'meetups/schedules', {matches, meetup}

  generate: (req, res) ->
    {name} = req.params

    MeetupModel.findOne {name}, (err, meetup) ->
      m = new Matcher meetup
      s = new Scheduler meetup

      m.execute (err, matches) ->
        console.error err if err
        console.log 'Created ' + matches.length + ' matches'

        s.scheduleRounds matches, (err, result) ->
          console.error err if err
          console.log result.length + ' rounds'
          console.dir r for r in result
          console.log 'Test Schedule Rounds Complete'
          # redirect to the meetup - db should be up to date!
          res.redirect "/meetup/#{name}"

  update: (req, res) ->
    {name} = req.params

    MeetupModel.findOneAndUpdate {name}, {$set: req.body}
    , (err, meetup) ->
      unless err
        meetup.save()
        res.redirect "/meetup/#{meetup.name}"
      else
        res.send err, 400

module.exports = (app) -> new Meetup app
