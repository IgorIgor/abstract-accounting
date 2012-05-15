module HomeHelper
  def documents_by_user(user)
    if user.root?
      [Waybill.name, Distribution.name]
    else
      user.credentials(:force_update).collect{ |c| c.document_type }
    end
  end
  def documents_list(id)
    "<ul id='#{id}'>#{
      documents_by_user(current_user).collect do |dt|
        "<li>#{link_to(t("views.home.#{dt.underscore}"),
                       "#documents#{send("new_#{dt.underscore}_path")}")
        }</li>"
      end.join
    }</ul>".html_safe
  end
end
