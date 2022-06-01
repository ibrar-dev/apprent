# unused?
defmodule AppCount.Admins.Auth.Permissions do
  @full %{read: true, write: true, destroy: true}

  #  @readonly %{read: true, write: false, destroy: false}
  #  @readupdate %{read: true, write: true, destroy: false}

  @resources [
    "prospects",
    "admins",
    "properties",
    "units",
    "leads",
    "occupants",
    "rentals",
    "properties",
    "mail_addresses"
  ]

  def super_admin do
    for resource <- @resources, into: %{} do
      {resource, @full}
    end
  end

  def prospect_admin do
    %{
      prospects: @full,
      occupants: @full,
      rentals: @full
    }
  end
end
