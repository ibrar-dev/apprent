defmodule AppCount.Accounts.Account do
  @moduledoc """
  Used to allow for Tenant Login
  """
  use Ecto.Schema
  use AppCount.EctoTypes.Attachment

  import Ecto.Changeset
  import AppCount.EctoTypes.Upload

  @required [:encrypted_password, :password_changed, :tenant_id, :username, :property_id]
  @languages ["english", "spanish"]

  schema "accounts__accounts" do
    field :encrypted_password, :string
    field :password_changed, :boolean, default: false
    field :receives_mailings, :boolean, default: true
    field :uuid, Ecto.UUID
    field :push_token, :string
    field :profile_pic, upload_type("appcount-accounts:profile-pics", "profile-pic", public: true)
    #    attachment :profile_pic
    field :username, :string
    field :allow_sms, :boolean, default: true
    field :preferred_language, :string, default: "english"

    belongs_to :tenant, AppCount.Tenants.Tenant
    belongs_to :property, AppCount.Properties.Property
    has_many :locks, AppCount.Accounts.Lock
    has_many :password_resets, AppCount.Accounts.PasswordReset
    has_many :logins, AppCount.Accounts.Login
    has_many :payment_sources, AppCount.Accounts.PaymentSource
    has_one :autopay, AppCount.Accounts.Autopay
    belongs_to :public_user, AppCount.Public.User

    timestamps()
  end

  def new(%{password: _password} = attrs) do
    attrs = hash_pwd(attrs)

    attrs =
      attrs
      |> Map.put(:encrypted_password, attrs.encrypted_password)
      |> Map.put(:password_changed, false)

    struct(__MODULE__, attrs)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(
      hash_pwd(attrs),
      [
        :encrypted_password,
        :password_changed,
        :tenant_id,
        :receives_mailings,
        :profile_pic,
        :username,
        :property_id,
        :push_token,
        :allow_sms,
        :preferred_language,
        :public_user_id,
        :uuid
      ]
    )
    |> validate_required(@required)
    |> validate_inclusion(:preferred_language, @languages)
    |> unique_constraint(:unique, name: :accounts__accounts_tenant_id_property_id_index)
    |> unique_constraint(:unique_username, name: :accounts__accounts_username_index)
  end

  def hash_pwd(%{"password" => password} = p) do
    Map.put(p, "encrypted_password", Bcrypt.hash_pwd_salt(password))
  end

  def hash_pwd(%{password: password} = p) do
    Map.put(p, :encrypted_password, Bcrypt.hash_pwd_salt(password))
  end

  def hash_pwd(attrs), do: attrs
end
