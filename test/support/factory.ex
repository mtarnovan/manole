defmodule Manole.Factory do
  @moduledoc false
  alias Manole.{Dog, Person, Repo, Toy}

  def insert_person_with_dog_and_toy(person_attrs, dog_attrs, toy_attrs) do
    p = Repo.insert!(struct(Person, person_attrs))
    d = Repo.insert!(struct(Dog, Map.merge(dog_attrs, %{person_id: p.id})))
    t = Repo.insert!(struct(Toy, Map.merge(toy_attrs, %{dog_id: d.id})))
    {p, d, t}
  end
end
