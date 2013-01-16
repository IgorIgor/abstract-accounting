$ ->
  class self.Route
    constructor: (@path_i, @name, @method) ->
    path: ()=>
      @path_i

    block: ()=>
      name_i = @name
      method_i = @method
      ->
        controller = new window["#{name_i.camelize()}Controller"]()
        controller.params = this.params
        controller._action(method_i)

  class self.BasicRoutes
    @INDEX = 1
    @NEW = 2
    @EDIT = 3
    @SHOW = 4

    @DEFAULT_ACTIONS = [@INDEX, @NEW, @SHOW, @EDIT]

    _routes: () ->
      @routes

    constructor: () ->
      @routes = []

  class self.ResourceRoutes extends self.BasicRoutes
    constructor: (@path, @name, @options = {}) ->
      Object.merge(@options, only: BasicRoutes.DEFAULT_ACTIONS, false, false)
      super()
    generate: (block = undefined) =>
      block.call(this) if block?

      this.collection "index" if BasicRoutes.INDEX in @options.only
      this.collection "new" if BasicRoutes.NEW in @options.only

      @routes.push new Route("##{@path}#{@name}/:id", @name,
        "show") if BasicRoutes.SHOW in @options.only
      @routes.push new Route("##{@path}#{@name}/:id/edit", @name,
        "edit") if BasicRoutes.EDIT in @options.only
      this

    collection: (method) ->
      if method == "index"
        @routes.push new Route("##{@path}#{@name}", @name, method)
      else
        @routes.push new Route("##{@path}#{@name}/#{method}", @name, method)


  class self.NamespaceRoutes extends self.BasicRoutes
    constructor: (@namespace_i) ->
      super

    generate: (block) =>
      block.call this
      this

    resource: (name, options = {}, block = undefined) =>
      path = if @namespace_i == "" then "" else "#{@namespace_i}/"
      res_routes = (new ResourceRoutes(path, name, options)).generate(block)._routes()
      @routes.push route for route in res_routes

  class self.Routes extends self.NamespaceRoutes
    _instance = undefined
    @instance: () ->
      _instance ?= new Routes()

    @configure: (block) ->
      block.call(Routes.instance())

    @run: () ->
      routes = Routes.instance()._routes()
      $.sammy(->
        this.get(route.path(), route.block()) for route in routes
      ).run()

    constructor: () ->
      super("")

    namespace: (name, block) =>
      @routes.push route for route in (new NamespaceRoutes(name)).generate(block)._routes()

    get: (path, method) =>
      cm = method.split("#")
      @routes.push new Route(path, cm[0], cm[1])

