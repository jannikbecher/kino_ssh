defmodule Kino.SSH do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/ssh_terminal/build"
  use Kino.JS.Live

  def new(opts) do
    host = Keyword.fetch!(opts, :host) |> to_charlist()
    port = Keyword.get(opts, :port, 22)
    username = Keyword.fetch!(opts, :username) |> to_charlist()
    password = Keyword.get(opts, :password) |> to_charlist()

    Kino.JS.Live.new(__MODULE__, {host, port, username, password, opts})
  end

  def exec(ssh, command, timeout \\ 5000) do
    Kino.JS.Live.call(ssh, {:command, command}, timeout)
  end

  def subscribe(ssh, pid \\ self()) do
    Kino.JS.Live.cast(ssh, {:subscribe, pid})
  end

  def unsubscribe(ssh, pid \\ self()) do
    Kino.JS.Live.cast(ssh, {:unsubscribe, pid})
  end

  @impl true
  def init({host, port, username, password, _opts}, ctx) do
    options = [
      silently_accept_hosts: true,
      user_interaction: false,
      save_accepted_host: false,
      quiet_mode: true,
      user: username,
      password: password
    ]

    {:ok, ref} = :ssh.connect(host, port, options)
    {:ok, chan} = :ssh_connection.session_channel(ref, :infinity)
    {:ok, assign(ctx, conn: {ref, chan}, subscriber: [], from: nil)}
  end

  def init({_host, _port, _username, _opts}, ctx) do
    # TODO implement public key 
    {:ok, ctx}
  end

  @impl true
  def handle_connect(ctx) do
    {ref, chan} = ctx.assigns.conn
    :success = :ssh_connection.ptty_alloc(ref, chan, [])
    :ok = :ssh_connection.shell(ref, chan)

    {:ok, %{}, ctx}
  end

  @impl true
  def handle_event("update_terminal", %{"data" => data}, ctx) do
    {ref, chan} = ctx.assigns.conn
    :ssh_connection.send(ref, chan, data)

    {:noreply, ctx}
  end

  @impl true
  def handle_info({:ssh_cm, _ref, msg}, ctx) do
    data =
      case msg do
        {:data, 0, 0, data} -> data
         msg -> msg
      end

    broadcast_event(ctx, "update_terminal", %{"data" => data})
    Enum.each(ctx.assigns.subscriber, fn pid -> send(pid, {:data, data}) end)
    ctx =
      if ctx.assigns.from do
        Kino.JS.Live.reply(ctx.assigns.from, data)
        assign(ctx, from: nil)
      else
        ctx
      end

    {:noreply, ctx}
  end

  @impl true
  def handle_call({:command, command}, from, ctx) do
    {ref, chan} = ctx.assigns.conn
    case :ssh_connection.send(ref, chan, to_charlist(command) ++ ["\n"]) do
      :ok -> {:noreply, assign(ctx, from: from)}
      error -> {:reply, error, ctx}
    end
  end

  @impl true
  def handle_cast({:subscribe, pid}, ctx) do
    ctx = update_in(ctx, [:assigns, :subscriber], &List.insert_at(&1, 0, pid))
    {:noreply, ctx}
  end

  @impl true
  def handle_cast({:unsubscribe, pid}, ctx) do
    ctx = update_in(ctx, [:assigns, :subscriber], &List.delete(&1, pid))
    {:noreply, ctx}
  end
end
