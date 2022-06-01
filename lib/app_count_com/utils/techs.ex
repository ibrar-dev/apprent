defmodule AppCountCom.Techs do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def tech_pass_code(name, code, email, property) do
    send_email(:tech_pass_code, email, "[AppRent] Your Pass Code",
      name: name,
      code: code,
      property: property
    )
  end
end
