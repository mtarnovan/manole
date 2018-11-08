defmodule Manole.Person do
  @moduledoc false
  use Ecto.Schema
  alias Manole.Dog

  schema "people" do
    field :name, :string
    field :age, :integer
    field :income, :integer
    has_many :dogs, Dog
  end
end
