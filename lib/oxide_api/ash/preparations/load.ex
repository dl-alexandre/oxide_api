if Code.ensure_loaded?(Ash.Resource) do
  defmodule OxideApi.Ash.Preparations.Load do
    @moduledoc """
    Ash preparation that loads Oxide resources into a data-layer-less resource.
    """

    use Ash.Resource.Preparation

    alias Ash.DataLayer.Simple
    alias Ash.Query
    alias OxideApi.{Disks, FloatingIps, Images, Instances, Projects}

    @impl Ash.Resource.Preparation
    def prepare(query, opts, _context) do
      case run(query, opts) do
        {:ok, records} ->
          Simple.set_data(query, records)

        {:error, error} ->
          Query.add_error(query, error)
      end
    end

    defp run(query, opts) do
      resource = Keyword.fetch!(opts, :resource)
      action = Keyword.fetch!(opts, :action)
      ash_resource = Keyword.fetch!(opts, :ash_resource)
      client = Query.get_argument(query, :client)

      with {:ok, result} <- request(resource, action, client, query) do
        {:ok, to_records(result, ash_resource)}
      end
    end

    defp request(:project, :list, client, query) do
      Projects.list(client, params(query))
    end

    defp request(:project, :get, client, query) do
      Projects.get(client, Query.get_argument(query, :project))
    end

    defp request(:instance, :list, client, query) do
      Instances.list(client, scoped_params(query))
    end

    defp request(:instance, :get, client, query) do
      Instances.get(client, Query.get_argument(query, :instance), scoped_params(query))
    end

    defp request(:disk, :list, client, query) do
      Disks.list(client, scoped_params(query))
    end

    defp request(:disk, :get, client, query) do
      Disks.get(client, Query.get_argument(query, :disk), scoped_params(query))
    end

    defp request(:image, :list, client, query) do
      Images.list(client, scoped_params(query))
    end

    defp request(:image, :get, client, query) do
      Images.get(client, Query.get_argument(query, :image), scoped_params(query))
    end

    defp request(:floating_ip, :list, client, query) do
      FloatingIps.list(client, scoped_params(query))
    end

    defp request(:floating_ip, :get, client, query) do
      FloatingIps.get(client, Query.get_argument(query, :floating_ip), scoped_params(query))
    end

    defp to_records(%{"items" => items}, resource), do: Enum.map(items, &resource.from_api/1)
    defp to_records(%{items: items}, resource), do: Enum.map(items, &resource.from_api/1)
    defp to_records(item, resource), do: [resource.from_api(item)]

    defp scoped_params(query) do
      query
      |> params()
      |> Map.put("project", Query.get_argument(query, :project))
      |> Map.reject(fn {_key, value} -> is_nil(value) end)
    end

    defp params(query) do
      query
      |> Query.get_argument(:params)
      |> case do
        nil ->
          %{}

        params when is_map(params) ->
          params

        params when is_list(params) ->
          Map.new(params, fn {key, value} -> {to_string(key), value} end)
      end
    end
  end
end
