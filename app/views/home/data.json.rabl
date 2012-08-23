# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@documents => :objects) do
  attributes document_id: :id, document_name: :name, document_content: :content
  node(:type) { |doc| doc.document_name.pluralize.downcase }
  node(:sum) { 0.0 }
  node(:created_at) { |doc| doc.document_created_at.strftime('%Y-%m-%d') }
  node(:update_at) { |doc| doc.document_updated_at.strftime('%Y-%m-%d') }
end
node (:per_page) { params[:per_page] || Settings.root.per_page }
node (:count) { @count }
