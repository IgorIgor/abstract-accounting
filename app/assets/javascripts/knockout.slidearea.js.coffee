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
