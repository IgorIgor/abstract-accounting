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
    self.object().catalog_id = ko.observable(data.catalog_id)
    self.autocomplete_init = (data, event) ->
      unless $(event.target).attr("autocomplete")
        params = {}
        if(event.target.id == "estimate_catalog_date")
          params["catalog_id"] = self.object()["catalog_id"]

        $(event.target).autocomplete($(event.target).attr("data-url"), {
          dataType: "json",
          selectFirst: false,
          delay: 600,
          cacheLength: 0,
          extraParams: params,
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
          switch $(event.target).attr("id")
            when "estimate_entity"
              $("#estimate_ident_name").val("")
              $("#estimate_ident_value").val("")
            when "estimate_catalog_date"
              $(event.target).val("")
        )
        $(event.target).result((event, data, formatted) ->
          switch $(event.target).attr("id")
            when "estimate_entity"
              self.object()[$(event.target).attr("bind-param")] = data["id"]
              $("#estimate_ident_name").val(data[$("#estimate_ident_name").attr("data-field")])
              $("#estimate_ident_value").val(data[$("#estimate_ident_value").attr("data-field")])
            when "estimate_catalog_date"
              self.object()[$(event.target).attr("bind-param")] = data["date"]
        )
    self.catalogs = ko.observableArray([])
    self.parent_id = null
    self.get_catalogs = (params = {}) ->
      $.getJSON("/catalogs.json", params, (data) ->
        if data.parent_id == null
          $(".actions input[value=Previous]").attr("disabled", "true")
        else
          $(".actions input[value=Previous]").removeAttr("disabled")
        self.parent_id = data.parent_id
        self.catalogs(data.subcatalogs)
      )
    self.show_catalog_selector = () ->
      $("#container_documents form").hide()
      $("div.form_choose").show()
      $(".actions").html(button("Cancel", hide_catalog_selector))
      $(".actions").append(button("Previous", show_previous_catalogs))
      get_catalogs()
    self.show_subcatalogs = (data, event) ->
      if $(event.target).parent().attr("count") > 0
        get_catalogs({ parent_id: $(event.target).parent().attr("id") })
    self.show_previous_catalogs = (data, event) ->
      get_catalogs({ id: self.parent_id })
    self.hide_catalog_selector = () ->
      $("div.form_choose").hide()
      $("#container_documents form").show()
      actions()
    self.select_catalog = (data, event) ->
      self.object().catalog_id($(event.target).parent().attr("id"))
      $("#estimate_catalog").val($(event.target).parent().attr("name"))
      $("#estimate_catalog_date").val("")
      hide_catalog_selector()
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
            actions()
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

  window.actions = ->
    $(".actions").html(button("Save"))
    $(".actions").append(button("Cancel"))
    $(".actions").append(button("Draft"))
  window.button = (value, func = null) ->
    $("<input type='button'/>").attr("value", value).click(func)
