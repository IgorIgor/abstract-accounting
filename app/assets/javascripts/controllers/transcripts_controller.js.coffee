$ ->
  class self.TranscriptsController extends self.ApplicationController
    index: =>
      filter = this.params.toHash()
      self.application.path('transcripts')
      $.getJSON('/transcripts/data.json', normalizeHash(filter), (objects) ->
        toggleSelect("transcripts_data")
        self.application.object(new TranscriptViewModel(objects))
      )
