if Code.ensure_loaded?(Ash.Resource) do
  defmodule OxideApi.Ash.Disk do
    @moduledoc """
    Ash resource for Oxide disks.
    """

    use Ash.Resource, domain: OxideApi.Ash.Domain

    alias OxideApi.Ash.DiskMapper
    alias OxideApi.Ash.Preparations.Load

    actions do
      read :list do
        argument(:client, :term, allow_nil?: false)
        argument(:project, :string, allow_nil?: false)
        argument(:params, :map, default: %{})

        prepare({Load, resource: :disk, action: :list, ash_resource: __MODULE__})
      end

      read :get do
        get?(true)

        argument(:client, :term, allow_nil?: false)
        argument(:project, :string, allow_nil?: false)
        argument(:disk, :string, allow_nil?: false)

        prepare({Load, resource: :disk, action: :get, ash_resource: __MODULE__})
      end
    end

    attributes do
      attribute(:id, :string, primary_key?: true, allow_nil?: false, public?: true)
      attribute(:name, :string, allow_nil?: false, public?: true)
      attribute(:description, :string, public?: true)
      attribute(:state, :string, public?: true)
      attribute(:size, :integer, public?: true)
      attribute(:project, :string, public?: true)
      attribute(:raw, :map, public?: true)
    end

    def from_api(map), do: DiskMapper.from_api(__MODULE__, map)
  end
else
  defmodule OxideApi.Ash.Disk do
    @moduledoc """
    Plain struct fallback for Oxide disks when Ash is unavailable.
    """

    defstruct [:id, :name, :description, :state, :size, :project, :raw]

    alias OxideApi.Ash.DiskMapper

    def from_api(map), do: DiskMapper.from_api(__MODULE__, map)
  end
end
