defmodule AppCount.Core.SchemaHelper do
  def cleanup_email(%{email: nil} = params) do
    params
  end

  def cleanup_email(%{email: ""} = params) do
    %{params | email: nil}
  end

  def cleanup_email(%{email: email} = params) do
    [email | _] = String.split(email)
    %{params | email: email}
  end

  def cleanup_email(params) do
    params
  end
end
