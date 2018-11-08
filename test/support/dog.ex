defmodule Manole.Dog do
  @moduledoc false
  use Ecto.Schema
  alias Manole.{Person, Toy}

  schema "dogs" do
    field :name, :string
    belongs_to :person, Person
    has_many :toys, Toy
  end
end
