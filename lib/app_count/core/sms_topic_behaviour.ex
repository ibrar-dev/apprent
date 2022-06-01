defmodule AppCount.Core.SmsTopicBehaviour do
  @callback sms_requested(String.t(), String.t(), atom()) :: {:ok, term()} | term()
  @callback message_received({String.t(), String.t(), atom()}, atom()) :: {:ok, term()} | term()

  @callback message_sent({String.t(), String.t(), atom()}, atom()) :: {:ok, term()} | term()
  @callback invalid_phone_number(map(), atom()) :: {:ok, term()} | term()
end
