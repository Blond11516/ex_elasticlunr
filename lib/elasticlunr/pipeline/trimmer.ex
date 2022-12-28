defmodule Elasticlunr.Pipeline.Trimmer do
  alias Elasticlunr.Token

  @behaviour Elasticlunr.Pipeline

  @impl true
  def call(%Token{token: str} = token) do
    str = String.trim(str)

    Token.update(token, token: str)
  end
end
