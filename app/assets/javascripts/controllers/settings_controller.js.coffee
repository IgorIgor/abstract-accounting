$ ->
  class self.SettingsController extends self.ApplicationController
    index: ->
      self.application.path('settings/preview')
      $.getJSON('/settings.json', normalizeHash(this.params.toHash()), (object) ->
        toggleSelect("settings_data")
        self.application.object(new SettingsViewModel(object, true))
      )

    new: ->
      self.application.path('settings/preview')
      $.getJSON("/settings/new.json", {}, (object) ->
        toggleSelect("settings_new")
        self.application.object(new SettingsViewModel(object))
      )
