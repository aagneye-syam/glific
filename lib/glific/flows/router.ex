defmodule Glific.Flows.Router do
  @moduledoc """
  The Router object which encapsulates the router in a given node.
  """

  use Glific.Schema
  import Ecto.Changeset

  alias Glific.Flows{
    Case,
    Category,
    Exit,
    Node,
    Wait,
  }

  @required_fields [:node_id]
  @optional_fields []

  @type t() :: %__MODULE__{
    __meta__: Ecto.Schema.Metadata.t(),
    uuid: Ecto.UUID.t() | nil,

    type: String.t() | nil,

    default_category_id: Ecto.UUID.t() | nil
    default_category: Category.t() | Ecto.Association.NotLoaded.t() | nil,

    node_id: Ecto.UUID.t() | nil,
    node: Node.t() | Ecto.Association.NotLoaded.t() | nil,
  }

  schema "routers" do
    field :type, :string
    field :operand, :string
    field :result_name, :string

    has_one :wait, Wait
    has_one :default_category, Category

    has_many :cases, Case
    has_many :categories, Category
    has_many :exits, Exit

    belongs_to :node, Node
  end


  @doc """
  Standard changeset pattern we use for all data types
  """
  @spec changeset(Node.t(), map()) :: Ecto.Changeset.t()
  def changeset(Node, attrs) do
    tag
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:node_id)
    |> foreign_key_constraint(:destination_node_id)
  end


end
