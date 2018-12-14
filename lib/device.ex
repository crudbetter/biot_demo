defmodule Biot.Demo.Device do
  @moduledoc false

  use GenStateMachine

  alias __MODULE__, as: Mod

  def lookup(device_id) do
    Registry.lookup(Registry.Via, {Mod, device_id})
  end

  def start_link(device_id, interval \\ 500, schedule \\ 5_000) do
    GenStateMachine.start_link(Mod, [device_id, interval, schedule],
      name: {:via, Registry, {Registry.Via, {Mod, device_id}}}
    )
  end

  def hangup(device) do
    GenStateMachine.cast(device, :hangup)
  end

  ## Callbacks

  def init([device_id, interval, schedule]) do
    Process.send_after(self(), :sample, interval)
    Process.send_after(self(), :dialup, schedule)

    {:ok, :sampling,
     %{
       device_id: device_id,
       buffer: [],
       interval: interval,
       schedule: schedule
     }}
  end

  def handle_event(:info, :sample, state, data = %{buffer: buffer, interval: interval}) do
    Process.send_after(self(), :sample, interval)
    updated_data = %{data | buffer: buffer ++ [[utc_now_ms(), 1]]}
    {:next_state, state, updated_data}
  end

  def handle_event(:info, :dialup, :communicating, %{schedule: schedule}) do
    Process.send_after(self(), :dialup, schedule)
    :keep_state_and_data
  end

  def handle_event(
        :info,
        :dialup,
        :sampling,
        data = %{device_id: device_id, buffer: buffer, schedule: schedule}
      ) do
    Process.send_after(self(), :dialup, schedule)

    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4040, [:binary, packet: 1, active: true])

    spec = %{
      id: Biot.Demo.ProtocolHandler,
      start: {Biot.Demo.ProtocolHandler, :start_link, [socket, device_id, buffer]},
      restart: :transient
    }

    {:ok, pid} =
      DynamicSupervisor.start_child(
        Biot.Demo.ProtocolHandlers,
        spec
      )

    :ok = :gen_tcp.controlling_process(socket, pid)
    {:next_state, :communicating, %{data | buffer: []}}
  end

  def handle_event(:cast, :hangup, :communicating, data) do
    {:next_state, :sampling, data}
  end

  defp utc_now_ms, do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)
end
