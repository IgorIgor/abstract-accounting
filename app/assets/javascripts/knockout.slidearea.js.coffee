ko.bindingHandlers.slider =
  init: (element, valueAccessor) ->
    pressed_id = valueAccessor().pressed
    slidearea = valueAccessor().slidearea
    closed = valueAccessor().closed ? true
    pressed_style = valueAccessor().pressed_style ? false

    showerHandler = () ->
      $("##{slidearea}").slideToggle('fast')
      if $("##{slidearea}").is(":visible") and pressed_style
        $("##{pressed_id}").addClass('pressed')
      false

    ko.utils.registerEventHandler($(element).find("##{pressed_id}").get(0),
      "click", showerHandler)

    $(document).click (event) ->
      if $("##{slidearea}").css("display") != 'none' &&
         $(event.target).parents("##{slidearea}").length == 0
        $("##{slidearea}").slideUp("fast")


ko.bindingHandlers.slidemenu =
  init: (element, valueAccessor) ->
    $(element).addClass("action_element")
    menu = $(element).find("ul")
    menu.addClass("menu")
    menu.find("li").addClass("menu-item")
    menu.find("li > a").addClass("menu-item-link")
    $(menu).click ->
      menu.slideUp("fast")

ko.bindingHandlers.closeSlidearea =
  init: (element, valueAccessor) ->
    slidearea = valueAccessor().slidearea

    ko.utils.registerEventHandler($(element), "click", =>
      $("##{slidearea}").slideUp("fast")
    )
