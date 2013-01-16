$ ->
  class self.GroupsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/groups/data.json'
      super(data)

      @params =
        page: @page
        per_page: @per_page

    getType: (object) ->
      'groups'
