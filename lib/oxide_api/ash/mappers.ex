defmodule OxideApi.Ash.ProjectMapper do
  @moduledoc false

  def from_api(module, map) do
    struct(module, %{
      id: OxideApi.Ash.id_or_name(map),
      name: OxideApi.Ash.field(map, "name"),
      description: OxideApi.Ash.field(map, "description"),
      raw: map
    })
  end
end

defmodule OxideApi.Ash.InstanceMapper do
  @moduledoc false

  def from_api(module, map) do
    struct(module, %{
      id: OxideApi.Ash.id_or_name(map),
      name: OxideApi.Ash.field(map, "name"),
      hostname: OxideApi.Ash.field(map, "hostname"),
      run_state: OxideApi.Ash.field(map, "run_state"),
      project: OxideApi.Ash.field(map, "project"),
      raw: map
    })
  end
end

defmodule OxideApi.Ash.DiskMapper do
  @moduledoc false

  def from_api(module, map) do
    struct(module, %{
      id: OxideApi.Ash.id_or_name(map),
      name: OxideApi.Ash.field(map, "name"),
      description: OxideApi.Ash.field(map, "description"),
      state: OxideApi.Ash.field(map, "state"),
      size: OxideApi.Ash.field(map, "size"),
      project: OxideApi.Ash.field(map, "project"),
      raw: map
    })
  end
end

defmodule OxideApi.Ash.ImageMapper do
  @moduledoc false

  def from_api(module, map) do
    struct(module, %{
      id: OxideApi.Ash.id_or_name(map),
      name: OxideApi.Ash.field(map, "name"),
      description: OxideApi.Ash.field(map, "description"),
      os: OxideApi.Ash.field(map, "os"),
      version: OxideApi.Ash.field(map, "version"),
      project: OxideApi.Ash.field(map, "project"),
      raw: map
    })
  end
end

defmodule OxideApi.Ash.FloatingIpMapper do
  @moduledoc false

  def from_api(module, map) do
    struct(module, %{
      id: OxideApi.Ash.id_or_name(map),
      name: OxideApi.Ash.field(map, "name"),
      description: OxideApi.Ash.field(map, "description"),
      ip: OxideApi.Ash.field(map, "ip") || OxideApi.Ash.field(map, "address"),
      project: OxideApi.Ash.field(map, "project"),
      raw: map
    })
  end
end
