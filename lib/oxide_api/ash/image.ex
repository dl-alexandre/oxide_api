if Code.ensure_loaded?(Ash.Resource) do
  defmodule OxideApi.Ash.Image do
    @moduledoc """
    Ash resource for Oxide images.
    """

    use Ash.Resource, domain: OxideApi.Ash.Domain

    alias OxideApi.Ash.ImageMapper
    alias OxideApi.Ash.Preparations.Load

    actions do
      read :list do
        argument(:client, :term, allow_nil?: false)
        argument(:project, :string, allow_nil?: false)
        argument(:params, :map, default: %{})

        prepare({Load, resource: :image, action: :list, ash_resource: __MODULE__})
      end

      read :get do
        get?(true)

        argument(:client, :term, allow_nil?: false)
        argument(:project, :string, allow_nil?: false)
        argument(:image, :string, allow_nil?: false)

        prepare({Load, resource: :image, action: :get, ash_resource: __MODULE__})
      end
    end

    attributes do
      attribute(:id, :string, primary_key?: true, allow_nil?: false, public?: true)
      attribute(:name, :string, allow_nil?: false, public?: true)
      attribute(:description, :string, public?: true)
      attribute(:os, :string, public?: true)
      attribute(:version, :string, public?: true)
      attribute(:project, :string, public?: true)
      attribute(:raw, :map, public?: true)
    end

    def from_api(map), do: ImageMapper.from_api(__MODULE__, map)
  end
else
  defmodule OxideApi.Ash.Image do
    @moduledoc """
    Plain struct fallback for Oxide images when Ash is unavailable.
    """

    defstruct [:id, :name, :description, :os, :version, :project, :raw]

    alias OxideApi.Ash.ImageMapper

    def from_api(map), do: ImageMapper.from_api(__MODULE__, map)
  end
end
