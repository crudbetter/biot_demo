defmodule Biot.Demo.ProtocolHandler do
  @moduledoc false

  use GenStateMachine

  alias __MODULE__, as: Mod

  require Logger

  def start_link(socket, device_id, buffer) do
    GenStateMachine.start_link(Mod, [socket, device_id, buffer],
      name: {:via, Registry, {Registry.Via, {Mod, socket}}}
    )
  end

  ## Callbacks

  def init([socket, device_id, buffer]) do
    :gen_tcp.send(
      socket,
      <<1::integer-size(8), device_id::integer-size(16), length(buffer)::integer-size(16)>>
    )

    {:ok, :ready, %{socket: socket, buffer: buffer, device_id: device_id}}
  end

  def handle_event(
        :info,
        msg = {:tcp, socket, _},
        state,
        data = %{socket: socket}
      ) do
    :timer.sleep(50)
    do_handle_event(:info, msg, state, data)
  end

  defp do_handle_event(
         :info,
         {:tcp, socket, <<2::integer-size(8)>>},
         :ready,
         data = %{socket: socket, buffer: [bufHd | bufTl]}
       ) do
    [ts | [val]] = bufHd

    :gen_tcp.send(socket, <<3::integer-size(8), ts::integer-size(64), val::integer-size(16)>>)

    {:next_state, :connected, %{data | buffer: bufTl}}
  end

  defp do_handle_event(
         :info,
         {:tcp, _, <<2::integer-size(8)>>},
         :ready,
         data = %{socket: socket, buffer: [], device_id: device_id}
       ) do
    :gen_tcp.send(socket, <<5::integer-size(8)>>)

    {:ok, device} = Biot.Demo.DeviceFactory.start_or_get(device_id)
    Biot.Demo.Device.hangup(device)

    {:stop, :shutdown}
  end

  defp do_handle_event(
         :info,
         {:tcp, socket, <<4::integer-size(8)>>},
         :connected,
         data = %{socket: socket, buffer: [], device_id: device_id}
       ) do
    :gen_tcp.send(socket, <<5::integer-size(8)>>)

    {:ok, device} = Biot.Demo.DeviceFactory.start_or_get(device_id)
    Biot.Demo.Device.hangup(device)

    {:stop, :shutdown}
  end

  defp do_handle_event(
         :info,
         {:tcp, socket, <<4::integer-size(8)>>},
         :connected,
         data = %{socket: socket, buffer: [bufHd | bufTl]}
       ) do
    [ts | [val]] = bufHd

    :gen_tcp.send(socket, <<3::integer-size(8), ts::integer-size(64), val::integer-size(16)>>)

    {:next_state, :connected, %{data | buffer: bufTl}}
  end
end
