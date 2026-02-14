defmodule BetterAuth.Core.Password do
  @moduledoc """
  Handles password hashing and verification.
  """
  import Argon2

  def hash(password) do
    Argon2.hash_pwd_salt(password)
  end

  def verify(password, hash) do
    Argon2.verify_pass(password, hash)
  end
end
