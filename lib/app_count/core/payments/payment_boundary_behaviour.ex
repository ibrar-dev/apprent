defmodule AppCount.Core.PaymentBoundaryBehaviour do
  @moduledoc false
  alias AppCount.Core.RentSaga

  @type ok_response :: {:ok, RentSaga.t()}
  @type error_response :: {:error, binary()}
  @type response :: ok_response | error_response

  @callback create_payment({integer(), binary()}, {integer(), integer(), binary()}) :: response
end
