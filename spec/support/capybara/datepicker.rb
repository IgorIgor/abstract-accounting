# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Capybara
  class Session
    def has_datepicker?(id)
      execute_script %Q{ $('##{id}').trigger("focus") }
      has_xpath?("//div[@id='ui-datepicker-div' and contains(@style, 'display: block')]")
    end

    def datepicker(id)
      execute_script %Q{ $('##{id}').trigger("focus") }
      elem = find(:xpath, "//div[@id='ui-datepicker-div' and " +
                          "contains(@style, 'display: block')]")
      elem.instance_eval do
        def prev_month
          session.execute_script %Q{ $('a.ui-datepicker-prev').trigger("click") }
          self
        end

        def next_month
          session.execute_script %Q{ $('a.ui-datepicker-next').trigger("click") }
          self
        end

        def day(day)
          session.execute_script %Q{
            $("a.ui-state-default:contains('#{day}')").trigger("click")
          }
        end
      end
      elem
    end
  end
end
