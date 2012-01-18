# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details
#= require jquery
#= require jquery_ujs
#= require jquery.autocomplete
#= require sammy
#= require knockout
#= require_self
#= require_tree .

$ ->
  documentViewModel = (type, data) ->
    self.object = ko.observable(data)
    self.autocomplete_init = (data, event) ->
      unless $(event.target).attr("autocomplete")
        $(event.target).autocomplete($(event.target).attr("data-url"), {
          dataType: "json",
          selectFirst: false,
          delay: 600,
          cacheLength: 0,
          parse: (data) ->
            parsed = []
            for object, id in data
              parsed[id] =
                data: object
                value: object[$(event.target).attr("data-field")]
                result: object[$(event.target).attr("data-field")]
            parsed
          ,
          formatItem: (item) ->
            return item[$(event.target).attr("data-field")]
        })
        $(event.target).change( ->
          self.object()[$(event.target).attr("bind-param")] = null
        )
        $(event.target).result((event, data, formatted) ->
          self.object()[$(event.target).attr("bind-param")] = data["id"]
        )
    self

  homeViewModel = ->
    self.documentVM = null
    self.documents_new = ->
      location.hash = "documents/estimates/new"
    $.sammy( ->
      this.get("#inbox", ->
        $.get("/inbox", {}, (form) ->
          $(".actions").html("")
          $("#container_documents").html(form)
          $(".sidebar-selected").removeClass("sidebar-selected")
          $("#inbox").addClass("sidebar-selected")
        )
      )
      this.get("#documents/:type/new", ->
        document_type = this.params.type
        $.get("/" + document_type + "/preview", {}, (form) ->
          $.getJSON("/" + document_type + "/new.json", {}, (data) ->
            $(".actions").html(button("Save"))
            $(".actions").append(button("Cancel"))
            $(".actions").append(button("Draft"))
            $("#container_documents").html(form)
            $("#inbox").removeClass("sidebar-selected")
            self.documentVM = new documentViewModel(document_type, data)
            ko.applyBindings(self.documentVM, $("#container_documents").get(0))
          )
        )
      )
    ).run()
    location.hash = "inbox" if $("#main").length

  ko.applyBindings(new homeViewModel())

  window.button = (value) ->
    $("<input type='button'/>").attr("value", value)
