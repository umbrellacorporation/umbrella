Filters =
  beforeFilter: (fn, opts) ->
    @_beforeFilters = @_filter(@_beforeFilters, fn, opts)

  afterFilter: (fn, opts) ->
    @_afterFilters = @_filter(@_afterFilters, fn, opts)

  _filter: (filters, fn, opts) ->
    if not filters then filters = []
    filters.push { 'fn': fn, 'opts': opts }
    filters

  _getFilterMiddleware: (action, filters) ->
    middleware_fns = []
    for hash in filters
      if not hash.opts
        middleware_fns.push @::[hash.fn]
      else if hash.opts?.only? and _.indexOf(hash.opts.only, action) > -1
        middleware_fns.push @::[hash.fn]
      else if hash.opts?.except? and _.indexOf(hash.opts.except, action) is -1
        middleware_fns.push @::[hash.fn]
    middleware_fns

  _getAllFilters: (action) ->
    {
      beforeFilters: @_beforeAction action
      afterFilters: @_afterAction action
    }


  _beforeAction: (action) ->
    @_getFilterMiddleware action, @_beforeFilters

  _afterAction: (action) ->
    @_getFilterMiddleware action, @_afterFilters

module.exports = Filters
