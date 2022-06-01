defmodule TenantSafe do
  defmodule Credentials do
    @enforce_keys [:user_id, :password, :product_type]
    defstruct [:user_id, :password, :product_type]

    @type t :: %__MODULE__{}
  end

  defmodule Applicant do
    defstruct city: "",
              dob: "",
              email: "",
              first_name: "",
              last_name: "",
              ref: "",
              phone: "",
              rent: 0,
              income: 0,
              ssn: "",
              state: "",
              street: "",
              zip: "",
              linked_orders: nil

    @type t :: %__MODULE__{}
  end
end
