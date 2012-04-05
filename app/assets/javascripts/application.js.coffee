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
#= require jquery.validate
#= require sammy
#= require knockout
#= require_self
#= require_tree .

$ ->
  class FolderViewModel
    constructor: (objects) ->
      @documents = ko.observableArray(objects)

      $.sammy( ->
        this.get('#documents/:type/:id', ->
          id = this.params.id
          type = this.params.type
          $.get("#{type}/preview", {}, (form) ->
            $.getJSON("#{type}/#{id}.json", {}, (object) ->
              viewModel = switch type
                when 'distributions'
                  new DistributionViewModel(object, null, true)
                when 'waybills'
                  new WaybillViewModel(object, true)

              $('#container_documents').html(form)
              ko.applyBindings(viewModel, $('#container_documents').get(0))
            )
          )
        )
      )

    showDocument: (object) ->
      location.hash = "documents/#{object.type}/#{object.id}"


  homeViewModel = ->
    self.documentVM = null
    self.folderVM = null
    $.sammy( ->
      this.get("#inbox", ->
        $.get("/inbox", {}, (form) ->
          $.getJSON("/inbox_data.json", {}, (data) ->
            $("#container_documents").html(form)
            $(".sidebar-selected").removeClass("sidebar-selected")
            $("#inbox").addClass("sidebar-selected")
            self.folderVM = new FolderViewModel(data)
            ko.applyBindings(self.folderVM, $("#container_documents").get(0))
          )
        )
      )
      this.get("#documents/:type/new", ->
        menuClose()
        document_type = this.params.type
        $.get("/" + document_type + "/preview", {}, (form) ->
          $.getJSON("/" + document_type + "/new.json", {}, (data) ->
            $("#container_documents").html(form)
            $("#inbox").removeClass("sidebar-selected")
            if document_type == "distributions"
              $.getJSON("warehouses/data.json", {}, (items) ->
                self.documentVM = new DistributionViewModel(data, items)
                ko.applyBindings(self.documentVM, $("#container_documents").get(0))
              )
            else
              self.documentVM = new WaybillViewModel(data)
              ko.applyBindings(self.documentVM, $("#container_documents").get(0))
          )
        )
      )
      this.get("#warehouses", ->
        $.get("/warehouses", {}, (form) ->
          $.getJSON("/warehouses/data.json", {}, (data) ->
            $("#container_documents").html(form)
            $(".sidebar-selected").removeClass("sidebar-selected")
            $("#warehouses").addClass("sidebar-selected")
            self.folderVM = new FolderViewModel(data)
            ko.applyBindings(self.folderVM, $("#container_documents").get(0))
          )
        )
      )
    ).run()
    location.hash = "inbox" if $("#main").length

  ko.applyBindings(new homeViewModel())

  window.menuClose = ->
    $('#documents_list').slideUp('fast') unless $("#documents_list").css("display") == "none"

  $('#btn_create').click( ->
    $('#documents_list').slideToggle('fast')
    false
  )

  document.onclick = ->
    menuClose()

  window.ajaxRequest = (type, url, params = {}) ->
    $.ajax({
      type: type,
      url: url,
      data: params,
      complete: (data) ->
        if data.responseText == "success"
          location.hash = "inbox"
        else
          $("#container_notification").css("display", "block")
          $("#container_notification ul").css("display", "block")
          for key, value of JSON.parse(data.responseText)
            $("#container_notification ul")
            .append($("<li class='server-message'>#{key}: #{value}</li>"))
    })
