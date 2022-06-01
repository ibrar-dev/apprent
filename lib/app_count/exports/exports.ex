defmodule AppCount.Exports do
  alias AppCount.Exports.Utils.Categories
  alias AppCount.Exports.Utils.Documents
  alias AppCount.Exports.Utils.Recipients

  def list_categories(admin_id), do: Categories.list_categories(admin_id)
  def insert_category(params), do: Categories.insert_category(params)
  def update_category(id, params), do: Categories.update_category(id, params)
  def delete_category(id), do: Categories.delete_category(id)

  def insert_document(params), do: Documents.insert_document(params)
  def update_document(id, params), do: Documents.update_document(id, params)
  def delete_document(id), do: Documents.delete_document(id)
  def download(id), do: Documents.download(id)
  def send_document(id, params), do: Documents.send_document(id, params)

  def list_recipients(admin_id), do: Recipients.list_recipients(admin_id)
  def insert_recipient(params), do: Recipients.insert_recipient(params)
  def update_recipient(id, params), do: Recipients.update_recipient(id, params)
  def delete_recipient(id), do: Recipients.delete_recipient(id)
end
