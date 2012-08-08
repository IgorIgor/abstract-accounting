# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Abstract
  module Rspec
    module Waiters
      def wait_until_hash_changed_to(hash)
        wait_until { current_hash == hash }
      rescue Capybara::TimeoutError
        flunk 'Current hash is not changed.'
      end

      def wait_for_ajax(timeout = Capybara.default_wait_time)
        page.wait_until(timeout) do
          page.evaluate_script 'jQuery.active == 0'
        end
      rescue Capybara::TimeoutError
        flunk 'Ajax request is not completed.'
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Abstract::Rspec::Waiters)
end
