express = require 'express'
coffeekup = require 'coffeekup'
HTTPServer = require './http'
HTTPSServer = require './https'
I18n = require './i18n'
Controller = require './controller'

# Shortcut for `new Server(...)`.
#
# @param {Function} ...
# @return {Server}
# @api public
createServer = (options) ->
  if 'object' == typeof options
    new HTTPSServer options, Array.prototype.slice.call(arguments, 1)
  else
    new HTTPServer Array.prototype.slice.call(arguments)

exports.Controller = Controller
exports.createServer = createServer
exports.HTTPServer = HTTPServer
exports.HTTPSServer = HTTPSServer
exports.I18n = I18n
exports.express = express
exports.coffeekup = coffeekup
