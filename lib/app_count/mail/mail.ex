defmodule AppCount.Mail do
  alias AppCount.Mail.Utils.RingCentral

  def process_mail(mail) do
    decoded = Jason.decode!(mail)

    case decoded["Type"] do
      "SubscriptionConfirmation" ->
        HTTPoison.get(decoded["SubscribeURL"])

      "Notification" ->
        decoded["Message"]
        |> Jason.decode!()
        |> process_notification()
    end
  end

  def process_notification(message) do
    case message["mail"]["source"] do
      "notify@ringcentral.com" -> RingCentral.process_ring_central(message)
    end
  end
end
