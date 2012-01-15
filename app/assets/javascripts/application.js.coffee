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
#= require sammy
#= require knockout
#= require_self
#= require_tree .

$ ->
  homeViewModel = ->
    $.sammy( ->
      this.get("#inbox", ->
        $.get("/inbox", {}, (form) ->
          $(".actions").html("")
          $(".container").html(form)
          $(".sidebar-selected").removeClass("sidebar-selected")
          $("#inbox").addClass("sidebar-selected")
        )
      )
    ).run()
    location.hash = "inbox" if $("#main").length

  ko.applyBindings(new homeViewModel())
