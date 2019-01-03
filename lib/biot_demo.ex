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

  def go(), do: go(5)

  def go(how_many) when is_integer(how_many),
    do: 1..how_many |> Enum.map(&Biot.Demo.DeviceFactory.start_or_get(&1))

  def slow() do
    DynamicSupervisor.which_children(Biot.Demo.DeviceFactory)
    |> Enum.map(fn {_, device, _, _} -> Biot.Demo.Device.slow(device) end)

    DynamicSupervisor.which_children(Biot.Demo.ProtocolHandlers)
    |> Enum.map(fn {_, handler, _, _} -> Biot.Demo.ProtocolHandler.set_comms_delay(handler, 1_000) end)
  end

  def normal() do
    DynamicSupervisor.which_children(Biot.Demo.DeviceFactory)
    |> Enum.map(fn {_, device, _, _} -> Biot.Demo.Device.normal(device) end)

    DynamicSupervisor.which_children(Biot.Demo.ProtocolHandlers)
    |> Enum.map(fn {_, handler, _, _} -> Biot.Demo.ProtocolHandler.set_comms_delay(handler, 50) end)
  end
end
