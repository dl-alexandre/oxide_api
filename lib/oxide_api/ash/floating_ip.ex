if Code.ensure_loaded?(Ash.Resource) do
  defmodule OxideApi.Ash.FloatingIp do
    @moduledoc """
    Ash resource for Oxide floating IPs.
    """

    use Ash.Resource, domain: OxideApi.Ash.Domain

    alias OxideApi.Ash.FloatingIpMapper
    alias OxideApi.Ash.Preparations.Load

    actions do
      read :list do
        argument(:client, :term, allow_nil?: false)
        argument(:project, :string, allow_nil?: false)
        argument(:params, :map, default: %{})

        prepare({Load, resource: :floating_ip, action: :list, ash_resource: __MODULE__})
      end

      read :get do
        get?(true)

        argument(:client, :term, allow_nil?: false)
        argument(:project, :string, allow_nil?: false)
        argument(:floating_ip, :string, allow_nil?: false)

        prepare({Load, resource: :floating_ip, action: :get, ash_resource: __MODULE__})
      end
    end

    attributes do
      attribute(:id, :string, primary_key?: true, allow_nil?: false, public?: true)
      attribute(:name, :string, allow_nil?: false, public?: true)
      attribute(:description, :string, public?: true)
      attribute(:ip, :string, public?: true)
      attribute(:project, :string, public?: true)
      attribute(:raw, :map, public?: true)
    end

    def from_api(map), do: FloatingIpMapper.from_api(__MODULE__, map)
  end
else
  defmodule OxideApi.Ash.FloatingIp do
    @moduledoc """
    Plain struct fallback for Oxide floating IPs when Ash is unavailable.
    """

    defstruct [:id, :name, :description, :ip, :project, :raw]

    alias OxideApi.Ash.FloatingIpMapper

    def from_api(map), do: FloatingIpMapper.from_api(__MODULE__, map)
  end
end
