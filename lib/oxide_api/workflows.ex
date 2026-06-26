defmodule OxideApi.Workflows do
  @moduledoc """
  Higher-level helpers for common Oxide API workflows.

  These functions compose the thin endpoint modules and `OxideApi.Builders`.
  They still accept and return plain API maps.
  """

  alias OxideApi.{
    Builders,
    Client,
    Error,
    Images,
    Instances,
    Projects,
    Vpcs,
    VpcSubnets
  }

  @type result :: Client.result()
  @type vpc_subnet_result :: {:ok, %{vpc: term(), subnet: term()}} | {:error, term()}

  @doc """
  Returns an existing project, creating it when the API reports it missing.

  The `project` argument can be a project name, keyword options, or an
  API-shaped map. Keyword/map inputs must include `:name` or `"name"`.
  """
  @spec ensure_project(Client.t(), String.t() | keyword() | map()) :: result()
  def ensure_project(%Client{} = client, project) do
    body = project_body(project)

    with {:ok, name} <- required_name(body, "project") do
      get_or_create(
        fn -> Projects.get(client, name) end,
        fn -> Projects.create(client, body) end
      )
    end
  end

  @doc """
  Creates an instance with an inline boot disk attachment.

  `instance` can be an API-shaped map or keyword list with `:name`,
  `:hostname`, `:ncpus`, and `:memory`.

  `disk` can be an API-shaped instance disk attachment or keyword list with
  `:name` and `:size`.
  """
  @spec create_instance_with_disk(
          Client.t(),
          String.t(),
          keyword() | map(),
          keyword() | map()
        ) :: result()
  def create_instance_with_disk(%Client{} = client, project, instance, disk) do
    with {:ok, disk} <- disk_attachment_body(disk),
         {:ok, body} <- instance_body(instance) do
      body =
        body
        |> Map.put_new("boot_disk", disk)
        |> Map.update("disks", [disk], &[disk | List.wrap(&1)])

      Instances.create(client, body, project: project)
    end
  end

  @doc """
  Ensures a VPC and subnet exist in a project.

  Both `vpc` and `subnet` accept keyword options or API-shaped maps. The subnet
  input must include `:name` / `"name"` and `:ipv4_block` / `"ipv4_block"`.
  """
  @spec ensure_vpc_and_subnet(
          Client.t(),
          String.t(),
          String.t() | keyword() | map(),
          keyword() | map()
        ) :: vpc_subnet_result()
  def ensure_vpc_and_subnet(%Client{} = client, project, vpc, subnet) do
    vpc_body = vpc_body(vpc)
    subnet_body = subnet_body(subnet)

    with {:ok, vpc_name} <- required_name(vpc_body, "vpc"),
         {:ok, subnet_name} <- required_name(subnet_body, "subnet"),
         {:ok, vpc} <-
           get_or_create(
             fn -> Vpcs.get(client, vpc_name, project: project) end,
             fn -> Vpcs.create(client, vpc_body, project: project) end
           ),
         {:ok, subnet} <-
           get_or_create(
             fn -> VpcSubnets.get(client, subnet_name, project: project, vpc: vpc_name) end,
             fn -> VpcSubnets.create(client, subnet_body, project: project, vpc: vpc_name) end
           ) do
      {:ok, %{vpc: vpc, subnet: subnet}}
    end
  end

  @doc """
  Creates an image from a snapshot ID in a project.

  Options must include `:os` and `:version`; any `:description` is forwarded to
  `OxideApi.Builders.image_from_snapshot/5`.
  """
  @spec create_image_from_snapshot(
          Client.t(),
          String.t(),
          String.t(),
          String.t(),
          keyword()
        ) :: result()
  def create_image_from_snapshot(%Client{} = client, project, name, snapshot_id, opts) do
    with {:ok, os} <- fetch_required(opts, :os),
         {:ok, version} <- fetch_required(opts, :version) do
      body = Builders.image_from_snapshot(name, snapshot_id, os, version, opts)
      Images.create(client, body, project: project)
    end
  end

  defp get_or_create(get, create) do
    case get.() do
      {:ok, resource} ->
        {:ok, resource}

      {:error, %Error{} = error} ->
        if Error.not_found?(error), do: create.(), else: {:error, error}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp project_body(project) when is_binary(project), do: Builders.project(project)

  defp project_body(project) when is_list(project),
    do: named_builder(project, &Builders.project/2)

  defp project_body(project), do: normalize_body(project)

  defp vpc_body(vpc) when is_binary(vpc), do: Builders.vpc(vpc)
  defp vpc_body(vpc) when is_list(vpc), do: named_builder(vpc, &Builders.vpc/2)
  defp vpc_body(vpc), do: normalize_body(vpc)

  defp subnet_body(subnet) when is_list(subnet) do
    name = Keyword.get(subnet, :name)
    ipv4_block = Keyword.get(subnet, :ipv4_block)
    opts = Keyword.drop(subnet, [:name, :ipv4_block])

    if name && ipv4_block do
      Builders.vpc_subnet(name, ipv4_block, opts)
    else
      normalize_body(subnet)
    end
  end

  defp subnet_body(subnet), do: normalize_body(subnet)

  defp instance_body(instance) when is_list(instance) do
    with {:ok, name} <- fetch_required(instance, :name),
         {:ok, hostname} <- fetch_required(instance, :hostname),
         {:ok, ncpus} <- fetch_required(instance, :ncpus),
         {:ok, memory} <- fetch_required(instance, :memory) do
      opts = Keyword.drop(instance, [:name, :hostname, :ncpus, :memory])
      {:ok, Builders.instance(name, hostname, ncpus, memory, opts)}
    end
  end

  defp instance_body(instance), do: {:ok, normalize_body(instance)}

  defp disk_attachment_body(disk) when is_list(disk) do
    with {:ok, name} <- fetch_required(disk, :name),
         {:ok, size} <- fetch_required(disk, :size) do
      opts = Keyword.drop(disk, [:name, :size])
      {:ok, Builders.create_disk_attachment(name, size, opts)}
    end
  end

  defp disk_attachment_body(disk) do
    body =
      disk
      |> normalize_body()
      |> Map.put_new("type", "create")

    {:ok, body}
  end

  defp normalize_body(body) when is_map(body) do
    Map.new(body, fn {key, value} -> {to_string(key), value} end)
  end

  defp normalize_body(body) when is_list(body) do
    body
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
  end

  defp named_builder(opts, builder) do
    case Keyword.fetch(opts, :name) do
      {:ok, name} -> builder.(name, Keyword.delete(opts, :name))
      :error -> normalize_body(opts)
    end
  end

  defp required_name(body, resource) do
    case Map.get(body, "name") do
      name when is_binary(name) and name != "" ->
        {:ok, name}

      _missing ->
        {:error, Error.config("missing required :name option for #{resource}")}
    end
  end

  defp fetch_required(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, Error.config("missing required :#{key} option")}
    end
  end
end
