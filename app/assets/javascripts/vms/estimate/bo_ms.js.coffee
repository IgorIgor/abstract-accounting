$ ->
  class self.EstimateBomsViewModel extends FolderViewModel
    constructor: (data, options = {}) ->
      @url = '/estimate/bo_ms/data.json'

      @filter =
        uid: ko.observable('')
        mu: ko.observable('')
        tags:
          main: ko.observable('')
          more: ko.observableArray([])

      @disableInclusionBtn = ko.computed(=>
        @filter.tags.main().length == 0
      )

      super(data)

      @params =
        like: @filter
        page: @page
        per_page: @per_page

      @params.catalog_id = options.catalog_id if options.catalog_id?

    addTag: =>
      @filter.tags.more.push({type:I18n.t("views.estimates.filter.or"), tag: ''})

    removeTag: (item) =>
      @filter.tags.more.remove(item)

    clearFilterTags: () =>
      @filter.tags.main('')
      @filter.tags.more([])

    getType: (o)=>
      "bo_ms"

    namespace: =>
      "estimate"

  class self.DialogEstimateBomsViewModel extends EstimateBomsViewModel
    constructor: (data, catalog_pid = null) ->
      super(data)
      @params.catalog_pid = catalog_pid if catalog_pid?

    @include DialogsHelper
