defmodule AppCountAuth.Users.Admin do
  defstruct [:id, :name, :email, :features, :client_schema, :property_ids, :roles]
end
