$ ->
  class self.ProjectsController extends self.ApplicationController
    index: =>
      @render 'estimate/projects'
      $.getJSON('estimate/projects/data.json', normalizeHash(this.params.toHash()), (objects) =>
        toggleSelect("estimate_projects_data")
        self.application.object(new EstimateProjectsViewModel(objects))
      )

    new: =>
      @render 'estimate/projects/preview'
      $.getJSON("estimate/projects/new.json", {}, (object) ->
        toggleSelect("estimate_projects_new")
        self.application.object(new EstimateProjectViewModel(object))
      )

    show: =>
      @render 'estimate/projects/preview'
      $.getJSON("estimate/projects/#{this.params.id}.json", {}, (object) ->
        toggleSelect("estimate_projects_data")
        self.application.object(new EstimateProjectViewModel(object, true))
      )
