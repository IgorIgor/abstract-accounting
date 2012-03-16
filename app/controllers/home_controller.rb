class HomeController < ApplicationController
  def index
  end

  def inbox
    render "home/documents", :layout => false
  end

  def inbox_data
    @data = Waybill.find(:all, :include => :versions)
  end
end
