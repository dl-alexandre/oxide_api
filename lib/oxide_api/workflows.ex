defmodule OxideApi.Workflows do
  @moduledoc """
  Higher-level helpers for common Oxide API workflows.

  These functions compose the thin endpoint modules and `OxideApi.Builders`.
  They still accept and return plain API maps.
  """

  alias OxideApi.{
    Builders,
    Client,
    Disks,
    Error,
    FloatingIps,
    Images,
    Instances,
    Projects,
    Telemetry,
    VpcFirewallRules,
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
    workflow(:ensure_project, fn -> do_ensure_project(client, project) end)
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
    workflow(:create_instance_with_disk, fn ->
      do_create_instance_with_disk(client, project, instance, disk)
    end)
  end

  @doc """
  Returns an existing disk, creating a blank disk when it is missing.

  Keyword input must include `:name` and `:size`; map input is forwarded as an
  API-shaped disk create body.
  """
  @spec ensure_disk(Client.t(), String.t(), keyword() | map()) :: result()
  def ensure_disk(%Client{} = client, project, disk) do
    workflow(:ensure_disk, fn -> do_ensure_disk(client, project, disk) end)
  end

  @doc """
  Returns an existing instance, creating it when Oxide reports it missing.

  Keyword input must include `:name`, `:hostname`, `:ncpus`, and `:memory`; map
  input is forwarded as an API-shaped instance create body.
  """
  @spec ensure_instance(Client.t(), String.t(), keyword() | map()) :: result()
  def ensure_instance(%Client{} = client, project, instance) do
    workflow(:ensure_instance, fn -> do_ensure_instance(client, project, instance) end)
  end

  @doc """
  Returns an existing image, creating it from a snapshot when it is missing.

  Options must include `:os` and `:version`.
  """
  @spec ensure_image_from_snapshot(Client.t(), String.t(), String.t(), String.t(), keyword()) ::
          result()
  def ensure_image_from_snapshot(%Client{} = client, project, name, snapshot_id, opts) do
    workflow(:ensure_image_from_snapshot, fn ->
      do_ensure_image_from_snapshot(client, project, name, snapshot_id, opts)
    end)
  end

  @doc """
  Returns an existing floating IP, creating it when it is missing.
  """
  @spec ensure_floating_ip(Client.t(), String.t(), String.t() | keyword() | map()) :: result()
  def ensure_floating_ip(%Client{} = client, project, floating_ip) do
    workflow(:ensure_floating_ip, fn -> do_ensure_floating_ip(client, project, floating_ip) end)
  end

  @doc """
  Ensures a VPC firewall rule set matches `rules`.

  The helper reads the current rule set and updates only when the API-shaped
  `"rules"` list differs.
  """
  @spec ensure_vpc_firewall_rules(Client.t(), String.t(), String.t(), [map()] | map()) ::
          result()
  def ensure_vpc_firewall_rules(%Client{} = client, project, vpc, rules) do
    workflow(:ensure_vpc_firewall_rules, fn ->
      do_ensure_vpc_firewall_rules(client, project, vpc, rules)
    end)
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
    workflow(:ensure_vpc_and_subnet, fn ->
      do_ensure_vpc_and_subnet(client, project, vpc, subnet)
    end)
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
    workflow(:create_image_from_snapshot, fn ->
      do_create_image_from_snapshot(client, project, name, snapshot_id, opts)
    end)
  end

  defp workflow(name, fun) do
    Telemetry.span([:oxide_api, :workflow], %{workflow: name}, fun)
  end

  defp do_ensure_project(client, project) do
    body = project_body(project)

    with {:ok, name} <- required_name(body, "project") do
      get_or_create(
        :project,
        fn -> Projects.get(client, name) end,
        fn -> Projects.create(client, body) end
      )
    end
  end

  defp do_create_instance_with_disk(client, project, instance, disk) do
    with {:ok, disk} <- disk_attachment_body(disk),
         {:ok, body} <- instance_body(instance) do
      body =
        body
        |> Map.put_new("boot_disk", disk)
        |> Map.update("disks", [disk], &[disk | List.wrap(&1)])

      Telemetry.span(
        [:oxide_api, :workflow, :step],
        %{workflow: :create_instance_with_disk, step: :create_instance},
        fn -> Instances.create(client, body, project: project) end
      )
    end
  end

  defp do_ensure_disk(client, project, disk) do
    with {:ok, body} <- disk_body(disk),
         {:ok, name} <- required_name(body, "disk") do
      get_or_create(
        :disk,
        fn -> Disks.get(client, name, project: project) end,
        fn -> Disks.create(client, body, project: project) end
      )
    end
  end

  defp do_ensure_instance(client, project, instance) do
    with {:ok, body} <- instance_body(instance),
         {:ok, name} <- required_name(body, "instance") do
      get_or_create(
        :instance,
        fn -> Instances.get(client, name, project: project) end,
        fn -> Instances.create(client, body, project: project) end
      )
    end
  end

  defp do_ensure_image_from_snapshot(client, project, name, snapshot_id, opts) do
    with {:ok, os} <- fetch_required(opts, :os),
         {:ok, version} <- fetch_required(opts, :version) do
      body = Builders.image_from_snapshot(name, snapshot_id, os, version, opts)

      get_or_create(
        :image,
        fn -> Images.get(client, name, project: project) end,
        fn -> Images.create(client, body, project: project) end
      )
    end
  end

  defp do_ensure_floating_ip(client, project, floating_ip) do
    body = floating_ip_body(floating_ip)

    with {:ok, name} <- required_name(body, "floating IP") do
      get_or_create(
        :floating_ip,
        fn -> FloatingIps.get(client, name, project: project) end,
        fn -> FloatingIps.create(client, body, project: project) end
      )
    end
  end

  defp do_ensure_vpc_firewall_rules(client, project, vpc, rules) do
    body = firewall_rules_body(rules)
    params = [project: project, vpc: vpc]

    with {:ok, current} <- VpcFirewallRules.get(client, params) do
      if equivalent_rules?(current, body) do
        {:ok, current}
      else
        VpcFirewallRules.update(client, body, params)
      end
    end
  end

  defp do_ensure_vpc_and_subnet(client, project, vpc, subnet) do
    vpc_body = vpc_body(vpc)
    subnet_body = subnet_body(subnet)

    with {:ok, vpc_name} <- required_name(vpc_body, "vpc"),
         {:ok, subnet_name} <- required_name(subnet_body, "subnet"),
         {:ok, vpc} <-
           get_or_create(
             :vpc,
             fn -> Vpcs.get(client, vpc_name, project: project) end,
             fn -> Vpcs.create(client, vpc_body, project: project) end
           ),
         {:ok, subnet} <-
           get_or_create(
             :vpc_subnet,
             fn -> VpcSubnets.get(client, subnet_name, project: project, vpc: vpc_name) end,
             fn -> VpcSubnets.create(client, subnet_body, project: project, vpc: vpc_name) end
           ) do
      {:ok, %{vpc: vpc, subnet: subnet}}
    end
  end

  defp do_create_image_from_snapshot(client, project, name, snapshot_id, opts) do
    with {:ok, os} <- fetch_required(opts, :os),
         {:ok, version} <- fetch_required(opts, :version) do
      body = Builders.image_from_snapshot(name, snapshot_id, os, version, opts)

      Telemetry.span(
        [:oxide_api, :workflow, :step],
        %{workflow: :create_image_from_snapshot, step: :create_image},
        fn -> Images.create(client, body, project: project) end
      )
    end
  end

  defp get_or_create(resource, get, create) do
    case Telemetry.span(
           [:oxide_api, :workflow, :step],
           %{resource: resource, step: :get},
           get
         ) do
      {:ok, resource} ->
        {:ok, resource}

      {:error, %Error{} = error} ->
        if Error.not_found?(error) do
          Telemetry.span(
            [:oxide_api, :workflow, :step],
            %{resource: resource, step: :create},
            create
          )
        else
          {:error, error}
        end

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

  defp floating_ip_body(floating_ip) when is_binary(floating_ip),
    do: Builders.floating_ip_create(floating_ip)

  defp floating_ip_body(floating_ip) when is_list(floating_ip),
    do: named_builder(floating_ip, &Builders.floating_ip_create/2)

  defp floating_ip_body(floating_ip), do: normalize_body(floating_ip)

  defp firewall_rules_body(rules) when is_list(rules), do: Builders.firewall_rules(rules)
  defp firewall_rules_body(rules), do: normalize_body(rules)

  defp equivalent_rules?(current, desired) do
    Map.get(current, "rules") == Map.get(desired, "rules")
  end

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

  defp disk_body(disk) when is_list(disk) do
    with {:ok, name} <- fetch_required(disk, :name),
         {:ok, size} <- fetch_required(disk, :size) do
      opts = Keyword.drop(disk, [:name, :size])
      {:ok, Builders.blank_disk(name, size, opts)}
    end
  end

  defp disk_body(disk), do: {:ok, normalize_body(disk)}

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
