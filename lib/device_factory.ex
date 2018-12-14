defmodule Biot.Demo.DeviceFactory do
  use DynamicSupervisor

  alias __MODULE__, as: Mod

  def start_link(arg) do
    DynamicSupervisor.start_link(Mod, arg, name: Mod)
  end

  def start_child(device_id) do
    spec = %{
      id: Biot.Demo.Device,
      start:
        {Biot.Demo.Device, :start_link, [device_id, :rand.uniform(1_000), :rand.uniform(5_000)]}
    }

    DynamicSupervisor.start_child(Mod, spec)
  end

  def start_or_get(device_id) do
    case Biot.Demo.Device.lookup(device_id) do
      [{device, _}] -> {:ok, device}
      [] -> start_child(device_id)
    end
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
