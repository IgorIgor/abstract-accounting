class HomeController < ApplicationController
  def index
  end

  def inbox
    render "home/documents", :layout => false
  end
end
