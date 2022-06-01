defmodule AppCount.RentApply.AddressFormatter do
  def format(%{"address" => addr, "unit" => unit, "city" => city, "state" => state, "zip" => zip}) do
    unit =
      if unit == "" do
        ""
      else
        "Unit #{unit} "
      end

    "#{addr} #{unit}#{city} #{state} #{zip}"
  end
end
