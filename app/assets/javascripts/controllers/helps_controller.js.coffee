$ ->
  class self.HelpsController extends self.ApplicationController
    index: ->
      self.application.path('helps')
      self.application.object(new HelpViewModel())

    show: ->
      self.application.path("helps/#{this.params.id}")
      self.application.object(new HelpViewModel())
      $(document).ready ->
        self.application.object().scrolling()
