defmodule OxideApi.MixProject do
  use Mix.Project

  @version "0.0.1"
  @source_url "https://github.com/dl-alexandre/oxide_api"

  def project do
    [
      app: :oxide_api,
      version: @version,
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      dialyzer: [
        plt_add_apps: [:mix]
      ],
      source_url: @source_url,
      aliases: aliases()
    ]
  end

  def cli do
    [
      preferred_envs: [
        verify: :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ssl]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:bypass, "~> 2.1", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Elixir client for the Oxide control plane API."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Documentation" => "https://docs.oxide.computer/api/guides/introduction",
        "GitHub" => @source_url
      },
      files:
        ~w(lib priv mix.exs README.md CHANGELOG.md RELEASE_CHECKLIST.md LICENSE .formatter.exs)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "RELEASE_CHECKLIST.md"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        Core: [
          OxideApi,
          OxideApi.Builders,
          OxideApi.Client,
          OxideApi.Config,
          OxideApi.Credentials,
          OxideApi.Error,
          OxideApi.Operation,
          OxideApi.Response,
          OxideApi.Workflows
        ],
        Resources: [
          OxideApi.AffinityGroups,
          OxideApi.AntiAffinityGroups,
          OxideApi.AlertReceivers,
          OxideApi.Alerts,
          OxideApi.AuthSettings,
          OxideApi.Certificates,
          OxideApi.Disks,
          OxideApi.ExternalSubnets,
          OxideApi.FloatingIps,
          OxideApi.Groups,
          OxideApi.Images,
          OxideApi.Instances,
          OxideApi.InternetGatewayIpAddresses,
          OxideApi.InternetGatewayIpPools,
          OxideApi.InternetGateways,
          OxideApi.IpPools,
          OxideApi.Login,
          OxideApi.Me,
          OxideApi.Metrics,
          OxideApi.MulticastGroups,
          OxideApi.NetworkInterfaces,
          OxideApi.Ping,
          OxideApi.Policy,
          OxideApi.Projects,
          OxideApi.Snapshots,
          OxideApi.SubnetPools,
          OxideApi.Timeseries,
          OxideApi.Users,
          OxideApi.Utilization,
          OxideApi.VpcFirewallRules,
          OxideApi.VpcRouterRoutes,
          OxideApi.VpcRouters,
          OxideApi.VpcSubnets,
          OxideApi.Vpcs,
          OxideApi.Webhooks
        ],
        System: [
          OxideApi.System.AlertReceivers,
          OxideApi.System.Alerts,
          OxideApi.System.AuditLog,
          OxideApi.System.Hardware,
          OxideApi.System.IdentityProviders,
          OxideApi.System.IpPools,
          OxideApi.System.IpPoolsService,
          OxideApi.System.Metrics,
          OxideApi.System.Networking,
          OxideApi.System.Policy,
          OxideApi.System.Scim,
          OxideApi.System.SiloQuotas,
          OxideApi.System.Silos,
          OxideApi.System.SubnetPools,
          OxideApi.System.SupportBundles,
          OxideApi.System.Timeseries,
          OxideApi.System.Update,
          OxideApi.System.Users,
          OxideApi.System.Webhooks
        ],
        Experimental: [
          OxideApi.Experimental.Probes
        ]
      ]
    ]
  end

  defp aliases do
    [
      verify: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "test"
      ]
    ]
  end
end
