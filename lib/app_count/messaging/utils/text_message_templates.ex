defmodule AppCount.Messaging.Utils.TextMessageTemplates do
  @moduledoc """
  To get the body of messages to be sent out.

  All messages must pass in "es" it will use the default english.

  offer_to_pay/2 needs params to have: first_name, property_name, balance, last_4
  """

  @payment_link "https://residents.apprent.com/payments"
  @spanish_lang "spanish"

  def offer_to_pay(params, @spanish_lang) do
    "Hola #{params.first_name}, este es un pago automático via texto desde #{params.property_name}. El balance de su cuenta es $#{
      params.balance
    }. Simplemente responda con P o Pagar para pagar el balance usando el método salvado por defecto en AppRent que termina en #{
      params.last_4
    }. Pueden aplicarse tarifas de procesamiento."
  end

  def offer_to_pay(params, _) do
    "Hi #{params.first_name}, this is an automated payment text from #{params.property_name}. The amount due on your account is $#{
      params.balance
    }. Simply reply with P or Pay to pay the balance using your saved payment method in AppRent ending in #{
      params.last_4
    }. Processing fees may apply."
  end

  def successful_payment(@spanish_lang),
    do:
      "Pago enviado correctamente. Esté atento a la confirmación por correo electrónico. Gracias por utilizar TextPay con AppRent."

  def successful_payment(_),
    do:
      "Payment successfully submitted. Please keep an eye out for an email confirmation. Thank you for using TextPay with AppRent."

  def zero_balance_message(@spanish_lang),
    do:
      "Su pago no fue procesado: te encantará oír que tu balance es $0. Para hacer un pago extra , inicia una sesión en tu cuenta de AppRent"

  def zero_balance_message(_),
    do:
      "You'll be happy to hear that there is a $0 balance on your account. To make a custom payment please login to your AppRent account"

  def generic_payment_error(@spanish_lang),
    do:
      "Error: no pudimos procesar tu pago en este momento. Por favor infórmanos a Support@apprent.com o haz click en el enlace para pagar en línea #{
        @payment_link
      }"

  def generic_payment_error(_),
    do:
      "Error: We were unable to process your payment at this time. Please contact Support@AppRent.com or click the link to pay online #{
        @payment_link
      }."

  def payment_declined_error(@spanish_lang),
    do:
      "Pago rechazado: tu pago fue rechazado. Por favor haz click aquí para actualizar tu método de pago #{
        @payment_link
      }."

  def payment_declined_error(_),
    do:
      "Payment Declined: Your payment has been declined. Please click here to update your payment method #{
        @payment_link
      }."

  def unrecognized_reply(@spanish_lang),
    do: "Está respuesta no es reconocida."

  def unrecognized_reply(_),
    do: "This reply is not recognized."
end
