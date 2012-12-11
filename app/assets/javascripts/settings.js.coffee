$ ->
  class self.SettingsViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'settings', readonly)
