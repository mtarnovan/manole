defmodule Manole.Test.Migration do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:people) do
      add(:name, :string)
      add(:age, :integer)
      add(:income, :integer)
    end

    create table(:dogs) do
      add(:name, :string)
      add(:person_id, references(:people))
    end

    create table(:toys) do
      add(:name, :string)
      add(:color, :string)
      add(:dog_id, references(:dogs))
    end
  end
end
