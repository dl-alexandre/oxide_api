if Code.ensure_loaded?(Ash.Domain) do
  defmodule OxideApi.Ash.Domain do
    @moduledoc """
    Ash domain exposing common Oxide resources.
    """

    use Ash.Domain, validate_config_inclusion?: false

    alias OxideApi.Ash.{Disk, FloatingIp, Image, Instance, Project}

    resources do
      resource Project do
        define(:list_projects, action: :list, args: [:client])
        define(:get_project, action: :get, args: [:client, :project])
      end

      resource Instance do
        define(:list_instances, action: :list, args: [:client, :project])
        define(:get_instance, action: :get, args: [:client, :project, :instance])
      end

      resource Disk do
        define(:list_disks, action: :list, args: [:client, :project])
        define(:get_disk, action: :get, args: [:client, :project, :disk])
      end

      resource Image do
        define(:list_images, action: :list, args: [:client, :project])
        define(:get_image, action: :get, args: [:client, :project, :image])
      end

      resource FloatingIp do
        define(:list_floating_ips, action: :list, args: [:client, :project])
        define(:get_floating_ip, action: :get, args: [:client, :project, :floating_ip])
      end
    end
  end
else
  defmodule OxideApi.Ash.Domain do
    @moduledoc """
    Plain Elixir fallback for the optional Ash domain.
    """

    alias OxideApi.Ash.{Disk, FloatingIp, Image, Instance, Project}
    alias OxideApi.{Disks, FloatingIps, Images, Instances, Projects}

    def list_projects(client, params \\ []) do
      with {:ok, page} <- Projects.list(client, params) do
        {:ok, map_items(page, Project)}
      end
    end

    def get_project(client, project) do
      with {:ok, item} <- Projects.get(client, project) do
        {:ok, Project.from_api(item)}
      end
    end

    def list_instances(client, project, params \\ []) do
      params = put_project(params, project)

      with {:ok, page} <- Instances.list(client, params) do
        {:ok, map_items(page, Instance)}
      end
    end

    def get_instance(client, project, instance, params \\ []) do
      params = put_project(params, project)

      with {:ok, item} <- Instances.get(client, instance, params) do
        {:ok, Instance.from_api(item)}
      end
    end

    def list_disks(client, project, params \\ []) do
      params = put_project(params, project)

      with {:ok, page} <- Disks.list(client, params) do
        {:ok, map_items(page, Disk)}
      end
    end

    def get_disk(client, project, disk, params \\ []) do
      params = put_project(params, project)

      with {:ok, item} <- Disks.get(client, disk, params) do
        {:ok, Disk.from_api(item)}
      end
    end

    def list_images(client, project, params \\ []) do
      params = put_project(params, project)

      with {:ok, page} <- Images.list(client, params) do
        {:ok, map_items(page, Image)}
      end
    end

    def get_image(client, project, image, params \\ []) do
      params = put_project(params, project)

      with {:ok, item} <- Images.get(client, image, params) do
        {:ok, Image.from_api(item)}
      end
    end

    def list_floating_ips(client, project, params \\ []) do
      params = put_project(params, project)

      with {:ok, page} <- FloatingIps.list(client, params) do
        {:ok, map_items(page, FloatingIp)}
      end
    end

    def get_floating_ip(client, project, floating_ip, params \\ []) do
      params = put_project(params, project)

      with {:ok, item} <- FloatingIps.get(client, floating_ip, params) do
        {:ok, FloatingIp.from_api(item)}
      end
    end

    defp map_items(%{"items" => items}, module), do: Enum.map(items, &module.from_api/1)
    defp map_items(%{items: items}, module), do: Enum.map(items, &module.from_api/1)
    defp map_items(_page, _module), do: []

    defp put_project(params, nil), do: params
    defp put_project(params, project) when is_map(params), do: Map.put(params, "project", project)
    defp put_project(params, project), do: Keyword.put(params, :project, project)
  end
end
