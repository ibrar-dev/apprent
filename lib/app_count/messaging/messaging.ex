defmodule AppCount.Messaging do
  alias AppCount.Messaging.Utils.Emails
  alias AppCount.Messaging.Utils.Residents
  alias AppCount.Messaging.Utils.Mailings
  alias AppCount.Messaging.Utils.MailTemplates
  alias AppCount.Messaging.Utils.PropertyTemplates

  def create_email(params), do: Emails.create_email(params)
  def find_tenants(email), do: Emails.find_tenants(email)
  def list_emails(tenant_id), do: Emails.list_emails(tenant_id)

  def get_residents_by_type(admin, type), do: Residents.get_residents_by_type(admin, type)

  def get_residents_by_type(admin, property_id, type),
    do: Residents.get_residents_by_type(admin, property_id, type)

  def get_residents_csv(property_id),
    do: Residents.get_residents_csv(property_id)

  def create_mailing(admin, mailing), do: Mailings.create_mailing(admin, mailing)

  def create_scheduled_mailing(admin, mailing),
    do: Mailings.create_scheduled_mailing(admin, mailing)

  def create_template(admin, params), do: MailTemplates.create_template(admin, params)
  def list_templates(), do: MailTemplates.list_templates()
  def list_templates(admin), do: MailTemplates.list_templates(admin)
  def edit_template(id, params, admin), do: MailTemplates.edit_template(id, params, admin)
  def delete_template(id), do: MailTemplates.delete_template(id)

  def list_property_templates(admin), do: PropertyTemplates.list_property_templates(admin)

  def create_property_template(admin, params),
    do: PropertyTemplates.create_property_template(admin, params)

  def property_templates(admin, property_id),
    do: PropertyTemplates.property_templates(admin, property_id)

  def delete_all_templates(id), do: PropertyTemplates.delete_all_templates(id)
  def templates_properties(id), do: PropertyTemplates.templates_properties(id)

  def clear_bounces(email_address), do: AppCount.Messaging.BounceRepo.clear_bounces(email_address)
end
