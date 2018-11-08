defmodule Manole.Toy do
  @moduledoc false
  use Ecto.Schema
  alias Manole.Dog

  schema "toys" do
    field :name, :string
    field :color, :string
    belongs_to :dog, Dog
  end
end
