defmodule AppCount.Core.PhoneNumber do
  alias AppCount.Core.PhoneNumber
  defstruct [:number]
  require Logger
  @phone_number_length 10

  def new("+1" <> number) do
    non_digits = ~r"[\D]"
    number = String.replace(number, non_digits, "")
    %__MODULE__{number: "+1" <> number}
  end

  def new(number) when is_binary(number) do
    new("+1" <> number)
  end

  def new(_non_binary) do
    %__MODULE__{}
  end

  def valid?(%PhoneNumber{number: "+1" <> number}) when is_binary(number) do
    length = String.length(number)

    if length == @phone_number_length do
      true
    else
      false
    end
  end

  def valid?(_anything_not_a_phone_number) do
    false
  end

  def dial_string(%PhoneNumber{number: number} = phone_number) do
    if valid?(phone_number) do
      number
    else
      "Invalid Number: #{display(number)}"
    end
  end

  defp display(number) when is_binary(number) do
    number
  end

  defp display(nil) do
    "nil"
  end
end
