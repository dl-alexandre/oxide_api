if Code.ensure_loaded?(Ash.Resource) do
  defmodule OxideApi.Ash.Instance do
    @moduledoc """
    Ash resource for Oxide instances.
    """

    use Ash.Resource, domain: OxideApi.Ash.Domain

    alias OxideApi.Ash.InstanceMapper
    alias OxideApi.Ash.Preparations.Load

    actions do
      read :list do
        argument(:client, :term, allow_nil?: false)
        argument(:project, :string, allow_nil?: false)
        argument(:params, :map, default: %{})

        prepare({Load, resource: :instance, action: :list, ash_resource: __MODULE__})
      end

      read :get do
        get?(true)

        argument(:client, :term, allow_nil?: false)
        argument(:project, :string, allow_nil?: false)
        argument(:instance, :string, allow_nil?: false)

        prepare({Load, resource: :instance, action: :get, ash_resource: __MODULE__})
      end
    end

    attributes do
      attribute(:id, :string, primary_key?: true, allow_nil?: false, public?: true)
      attribute(:name, :string, allow_nil?: false, public?: true)
      attribute(:hostname, :string, public?: true)
      attribute(:run_state, :string, public?: true)
      attribute(:project, :string, public?: true)
      attribute(:raw, :map, public?: true)
    end

    def from_api(map), do: InstanceMapper.from_api(__MODULE__, map)
  end
else
  defmodule OxideApi.Ash.Instance do
    @moduledoc """
    Plain struct fallback for Oxide instances when Ash is unavailable.
    """

    defstruct [:id, :name, :hostname, :run_state, :project, :raw]

    alias OxideApi.Ash.InstanceMapper

    def from_api(map), do: InstanceMapper.from_api(__MODULE__, map)
  end
end
