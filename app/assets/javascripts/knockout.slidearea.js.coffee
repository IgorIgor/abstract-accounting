ko.bindingHandlers.slidearea =
  init: (element, valueAccessor) ->
    pressed_id = valueAccessor().pressed

    $(element).addClass("action_element")
    menu = $(element).find("ul")
    menu.addClass("menu")
    menu.find("li").addClass("menu-item")
    menu.find("li > a").addClass("menu-item-link")

    showerHandler = () ->
      menu.slideToggle('fast')
      false

    ko.utils.registerEventHandler($(element).find("##{pressed_id}").get(0),
      "click", showerHandler)

    $(document).click (event) ->
      e = $(event.target)
      if e != menu && menu.css("display") != 'none'
        menu.slideUp("fast")

ko.bindingHandlers.slider =
  init: (element, valueAccessor) ->
    pressed_id = valueAccessor().pressed
    slidearea = valueAccessor().slidearea
    closed = if valueAccessor().closed? then valueAccessor().closed else true
    pressed_style = if valueAccessor().pressed_style? then valueAccessor().pressed_style else false

    showerHandler = () ->
      $("##{slidearea}").slideToggle('fast')
      if $("##{slidearea}").is(":visible") and pressed_style
        $("##{pressed_id}").addClass('pressed')
      false

    ko.utils.registerEventHandler($(element).find("##{pressed_id}").get(0),
    "click", showerHandler)

    $(document).click (event) ->
      unless $("##{slidearea}").css("display") == 'none'
        if closed or $(event.target).parents("##{slidearea}").length == 0
          $("##{slidearea}").slideUp("fast")

ko.bindingHandlers.closeSlidearea =
  init: (element, valueAccessor) ->
    slidearea = valueAccessor().slidearea

    ko.utils.registerEventHandler($(element), "click", =>
      $("##{slidearea}").slideUp("fast")
    )
