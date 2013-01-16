$ ->
  class self.ForemanController extends self.ApplicationController
    index: =>
      @render 'foreman/resources'
      $.getJSON('foreman/resources/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("foreman_report")
        toggleSelect("foreman_report")
        self.application.object(new ForemanViewModel(objects))
      )
