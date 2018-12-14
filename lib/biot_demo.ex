defmodule Biot.Demo do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Biot.Demo.ProtocolHandlers},
      Biot.Demo.DeviceFactory,
      {Registry, keys: :unique, name: Registry.Via}
    ]

    opts = [strategy: :one_for_one, name: Biot.Demo.Nstrator]

    Supervisor.start_link(children, opts)
  end
end
