defmodule KinoSSH.SSHCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/ssh_cell/build"
  use Kino.JS.Live
  use Kino.SmartCell, name: "SSH Client"

  alias Kino.AttributeStore

  @global_key __MODULE__
  @global_attrs ["password"]

  @impl true
  def init(attrs, ctx) do
    {shared_password, shared_password_secret} =
      AttributeStore.get_attribute({@global_key, :ssh_password}, {nil, nil})

    fields = %{
      "assign_to" => attrs["assign_to"] || "",
      "host" => attrs["host"] || "",
      "username" => attrs["username"] || "",
      "password" => attrs["password"] || shared_password || "",
      "password_secret" => attrs["password_secret"] || shared_password_secret || "",
      "use_password_secret" =>
        if(shared_password_secret, do: true, else: Map.get(attrs, "use_password_secret", false))
    }

    ctx = assign(ctx, fields: fields, ssh_conn: {nil, nil})

    {:ok, ctx}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{fields: ctx.assigns.fields}
    {:ok, payload, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    ctx = update(ctx, :fields, &Map.put(&1, field, value))
    if field in @global_attrs, do: put_shared_attr(field, value)

    broadcast_event(ctx, "update_field", %{"fields" => update_fields(field, value)})

    {:noreply, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
  end

  @impl true
  def to_source(%{"host" => ""}), do: ""
  def to_source(%{"username" => ""}), do: ""
  def to_source(%{"use_password_secret" => false, "password" => ""}), do: ""
  def to_source(%{"use_password_secret" => true, "password_secret" => ""}), do: ""

  def to_source(
        %{"use_password_secret" => true, "password_secret" => secret, "assign_to" => var} = attrs
      ) do
    var = if Kino.SmartCell.valid_variable_name?(var), do: var

    quote do
      Kino.SSH.new(
        host: unquote(attrs["host"]),
        username: unquote(attrs["username"]),
        password: System.fetch_env!(unquote("LB_#{secret}")) |> to_charlist()
      )
    end
    |> build_var(var)
    |> Kino.SmartCell.quoted_to_string()
  end

  def to_source(%{"assign_to" => var} = attrs) do
    var = if Kino.SmartCell.valid_variable_name?(var), do: var

    quote do
      Kino.SSH.new(
        host: unquote(attrs["host"]),
        username: unquote(attrs["username"]),
        password: unquote(attrs["password"])
      )
    end
    |> build_var(var)
    |> Kino.SmartCell.quoted_to_string()
  end

  defp put_shared_attr("password", value) do
    AttributeStore.put_attribute({@global_key, :password}, {value, nil})
  end

  defp put_shared_attr("password_secret", value) do
    AttributeStore.put_attribute({@global_key, :password}, {nil, value})
  end

  defp update_fields(field, value), do: %{field => value}

  defp build_var(call, nil), do: call

  defp build_var(call, var) do
    quote do
      unquote({String.to_atom(var), [], nil}) = unquote(call)
    end
  end
end
