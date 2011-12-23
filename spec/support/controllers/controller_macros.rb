# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module ControllerMacros
  def page_login email = "root@localhost",
                 password = Settings.root.password,
                 remember = false
    visit login_path
    fill_in("Email", :with => email)
    fill_in("Password", :with => password)
    check('remember_me') if remember
    click_on "Log in"
  end
end

RSpec.configure do |config|
  config.include(ControllerMacros)
end
