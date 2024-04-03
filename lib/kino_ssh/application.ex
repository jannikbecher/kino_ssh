defmodule KinoSSH.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Kino.SmartCell.register(KinoSSH.SSHCell)

    children = []

    opts = [strategy: :one_for_one, name: KinoSSH.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
