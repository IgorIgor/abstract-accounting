class HomeController < ApplicationController
  def index
  end

  def inbox
    render "home/documents", :layout => false
  end

  def inbox_data
    @data = Version.joins("INNER JOIN (SELECT item_id, MAX(created_at) as last_create
                          FROM versions GROUP BY item_id, item_type) grouped
                            ON versions.item_id = grouped.item_id AND
                            versions.created_at = grouped.last_create").
        where("item_type='Waybill' OR item_type='Distribution'").
        all(include: [item: [:versions, :storekeeper]])
  end
end
