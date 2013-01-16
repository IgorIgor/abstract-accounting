$ ->
  class self.HomeController extends self.ApplicationController
    inbox: =>
      self.application.path('inbox')
      $.getJSON('/inbox.json', {}, (objects) ->
        toggleSelect("inbox_data")
        self.application.object(new DocumentsViewModel(objects, 'inbox'))
      )

    archive: =>
      self.application.path('archive')
      $.getJSON('/archive.json', {}, (objects) ->
        toggleSelect("archive_data")
        self.application.object(new DocumentsViewModel(objects, 'archive'))
      )
