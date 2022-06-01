defmodule AppCount.Properties.Utils.Settings do
  alias AppCount.Properties.PropertyRepo

  def agreement_text_for(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %{id: id}
      }) do
    agreement_text_for(%AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: id
    })
  end

  def agreement_text_for(nil) do
    nil
  end

  def agreement_text_for(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    property = PropertyRepo.get(property_id, prefix: client_schema)

    setting =
      PropertyRepo.property_settings(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property
      })

    setting.agreement_text
  end
end
