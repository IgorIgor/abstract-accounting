# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details
#= require jquery
#= require jquery-ui
#= require jquery_ujs
#= require jq.scrollabletabs
#= require jquery.mousewheel
#= require jquery.validate
#= require jquery.datepick-ru
#= require sammy
#= require knockout
#= require knockout.mapping
#= require sticky
#= require i18n
#= require i18n/opentask_translations
#= require sugar
#= require TrafficCop
#= require infuser
#= require koExternalTemplateEngine
#
#= require_tree ./lib
#= require vms/base
#= require_directory ./vms
#= require controllers/application_controller
#= require_directory ./controllers
#= require_directory ./config
#= require_self
$ ->

  $(document).ajaxStart( ->
    $('#message_box').text(I18n.t('views.notifications.load'))
    width = $('#message_box').css('width')
    $('#message_box').css( 'left', '50%')
    $('#message_box').css({'border-color': "#F0C36D", 'background-color': '#F9EDBE'})
    $('#message_box').css('display', 'block')
  )

  $(document).ajaxStop( ->
    $('#message_box').css('display', 'none') unless $('#message_box').data('msgType') == 'error'
  )

  $(document).ajaxError((e, jqXHR, settings) ->
    statusErrorMap =
      "400": I18n.t('views.notifications.bad_request')
      "401": I18n.t('views.notifications.unauth')
      "403": I18n.t('views.notifications.forbidden')
      "500": I18n.t('views.notifications.internal_error')
      "503": I18n.t('views.notifications.unavailable')
    message = I18n.t('views.notifications.error')
    if jqXHR.status
      message = statusErrorMap[jqXHR.status]
      if jqXHR.status == 500
        message += ": #{JSON.parse(jqXHR.responseText)['error']}"
        $('#message_box').data('msgType','error')
    else if e == 'parsererror'
      message = I18n.t('views.notifications.parsererror')
    else if e == 'timeout'
      message = I18n.t('views.notifications.timeout')
    else if e == 'abort'
      message = I18n.t('views.notifications.abort')
    else
      $('#message_box').data('msgType','error')
    $('#message_box').text(message)
    width = parseInt($('#message_box').css('width'))
    $('#message_box').css('left', "#{((screen.width - width) / 2)}px")
    $('#message_box').css({'border-color': "#ec9090", 'background-color': '#ecbbbb'})
    $('#message_box').css('display', 'block')
    setTimeout( ->
      $('#message_box').css('display', 'none')
    5000)
  )

  class ApplicationViewModel
    constructor: ->
      @object = ko.observable(null)
      @path = ko.observable(null)
      location.hash = defaultPage if $('#main').length && location.hash.length == 0

    templatePath: =>
      @path()

    expandResources: (object, event) =>
      @expand($('#slide_menu_resources'), $('#arrow_resources_actions'))

    expandEntities: (object, event) =>
      @expand($('#slide_menu_entities'), $('#arrow_entities_actions'))

    expand: (menu, actions) =>
      if menu.is(":visible")
        actions.removeClass('arrow-down-expand')
        actions.addClass('arrow-right-expand')
      else
        actions.removeClass('arrow-right-expand')
        actions.addClass('arrow-down-expand')
      menu.slideToggle()

    expandDeals: (object, event) =>
      toggle = true
      if $('#slide_menu_deals').is(":visible")
        if event.target.id == 'arrow_actions'
          $('#arrow_actions').removeClass('arrow-down-expand')
          $('#arrow_actions').addClass('arrow-right-expand')
        else
          toggle = false
          location.hash = $('#deals_data').attr('href')
      else
        if event.target.id == 'deals'
          location.hash = $('#deals_data').attr('href')
        $('#arrow_actions').removeClass('arrow-right-expand')
        $('#arrow_actions').addClass('arrow-down-expand')
      $("#slide_menu_deals").slideToggle() if toggle

    slide: (object, event) ->
      switch event.target.id
        when 'btn_slide_conditions'
          @slideMenu('#slide_menu_conditions', '#arrow_conditions')
        when 'btn_slide_lists'
          @slideMenu('#slide_menu_lists', '#arrow_lists')
        when 'btn_slide_services'
          @slideMenu('#slide_menu_services', '#arrow_services')

    slideMenu: (slide_id, arrow_id) ->
        if $(slide_id).is(":visible")
          $(arrow_id).removeClass('arrow-up-slide')
          $(arrow_id).addClass('arrow-down-slide')
        else
          $(arrow_id).removeClass('arrow-down-slide')
          $(arrow_id).addClass('arrow-up-slide')
        $(slide_id).slideToggle()

  self.application = new ApplicationViewModel()
  ko.applyBindings(self.application)

  Routes.run()
