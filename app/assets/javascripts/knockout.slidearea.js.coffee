ko.bindingHandlers.slider =
  init: (element, valueAccessor) ->
    pressed_id = valueAccessor().pressed
    slidearea = valueAccessor().slidearea

    showerHandler = () ->
      $("##{slidearea}").slideToggle('fast')
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
