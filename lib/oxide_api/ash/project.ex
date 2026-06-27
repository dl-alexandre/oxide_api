if Code.ensure_loaded?(Ash.Resource) do
  defmodule OxideApi.Ash.Project do
    @moduledoc """
    Ash resource for Oxide projects.
    """

    use Ash.Resource, domain: OxideApi.Ash.Domain

    alias OxideApi.Ash.Preparations.Load
    alias OxideApi.Ash.ProjectMapper

    actions do
      read :list do
        argument(:client, :term, allow_nil?: false)
        argument(:params, :map, default: %{})

        prepare({Load, resource: :project, action: :list, ash_resource: __MODULE__})
      end

      read :get do
        get?(true)

        argument(:client, :term, allow_nil?: false)
        argument(:project, :string, allow_nil?: false)

        prepare({Load, resource: :project, action: :get, ash_resource: __MODULE__})
      end
    end

    attributes do
      attribute(:id, :string, primary_key?: true, allow_nil?: false, public?: true)
      attribute(:name, :string, allow_nil?: false, public?: true)
      attribute(:description, :string, public?: true)
      attribute(:raw, :map, public?: true)
    end

    def from_api(map), do: ProjectMapper.from_api(__MODULE__, map)
  end
else
  defmodule OxideApi.Ash.Project do
    @moduledoc """
    Plain struct fallback for Oxide projects when Ash is unavailable.
    """

    defstruct [:id, :name, :description, :raw]

    alias OxideApi.Ash.ProjectMapper

    def from_api(map), do: ProjectMapper.from_api(__MODULE__, map)
  end
end
