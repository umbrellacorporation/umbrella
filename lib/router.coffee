ExpressRouter = require 'express/lib/router'
Controller = require './controller'
_ = require 'underscore'

# A router with advanced routing dsl capabilities
class Router extends ExpressRouter

  constructor: ->
    super

    # Paths to controller actions
    #
    #     @to.users(filter: {project_id: 3})
    #     @to.users.show(id: 10)
    #
    @to = {}

    # Named paths
    #
    #     @at.download_file(name: 'file.txt')
    #
    @at = {}

  # Route `method`, `path`, and optional middleware
  # to the callback defined by `cb`.
  # 
  # @param {String} method
  # @param {String} path
  # @param {Function} ...
  # @param {Function|String|Object} cb - connect middlewares or middleware definition as defined by `DefinitionResolver` class
  # @return {Router} for chaining
  # @api private
  _route: (method, path) ->
    beforeFilters = []
    afterFilters = []
    definition = arguments[arguments.length - 1]
    return super if arguments.length < 3 or typeof definition != 'object' # just like old api
    {to, as} = definition
    fn = switch typeof to
      when 'function'
        Controller.middleware to
      when 'string'
        throw new Error("string route definition must be in the form 'controller#action'") unless to.match /[\w_]+#[\w_]+/
        [controller, action] = to.split '#'
        { beforeFilters, afterFilters } = @_resolveFilters controller, action
        @_resolveControllerAction controller, action
      when 'object'
        {controller, action} = to
        { beforeFilters, afterFilters } = @_resolveFilters controller, action
        @_resolveControllerAction controller, action
      else
        throw new Error("unknown route endpoint #{to}")
    super method, path, beforeFilters, fn, afterFilters

  # @param {String} controller
  # @param {Function} action
  # @return {beforeFilters: [middleware functions], afterFilters: [middleware functions] }
  # @api private
  _resolveFilters: (controller, action) ->
    filters = {}
    # get before and after filters
    _filters = @findController(controller)._getAllFilters action
    # wrap each middleware function of before and after filters as if it was an action
    _.map(_filters, (val, key) =>
      val = _.map(val, (fn) =>
        return @_resolveControllerFilter(controller, fn)
      )
      filters[key] = val
    )
    filters

  # Validates the existence of controller and returns the resolved filter
  # (filter ~ Connect middleware)
  #
  # @param {String} controller - the controller name
  # @param {Function} a Connect middleware
  # @return {Function} a Connect middleware
  # @api private
  _resolveControllerFilter: (controller, fn) ->
    throw new Error("cannot resolve controller") unless controller?
    @findController(controller).resolveFilter fn

  # Validates the existence of controller and returns the resolved middleware
  #
  # @param {String} controller - the controller name
  # @param {String} action - the controller action (or skip if rest)
  # @return {Function} a Connect middleware (that resolves to the given controller and action)
  # @api private
  _resolveControllerAction: (controller, action) ->
    throw new Error("cannot resolve controller") unless controller?
    action = 'index' unless action?
    @findController(controller).middleware action

  # Requires the given controller based on the "controllers path" configuration
  #
  # @param {String} controller - the controller name
  # @return {Object} the controller class
  # @api public
  findController: (controller) ->
    controllersPath = @app.set 'controllers path'
    throw new Error("please configure controllers path") unless controllersPath?
    require "#{controllersPath}/#{controller}"

  # Return a url given a controller and an action, and optional params
  # TODO: steal from https://github.com/josh/rack-mount/blob/master/lib/rack/mount/route_set.rb
  #
  #     Given a route "/users/:id"
  #
  #     @url controller: 'users', id: 10, page: 12
  #     /users/10?page=12
  #
  url: (opts) ->
    throw new Error('controller must be specified') unless opts.controller?
    controller = opts.controller
    action = opts.action || 'index'
    method = opts.action || 'get'

module.exports = Router
