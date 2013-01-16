$ ->
  class self.ApplicationController
    constructor: ->

    _action: (name) =>
      self.application.object(null)
      this[name]()

    render: (path) =>
      self.application.path(path)
