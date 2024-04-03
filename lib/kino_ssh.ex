defimpl Kino.Render, for: Kino.SSH do
  def to_livebook(result) do
    result
    |> Kino.SSH.new()
    |> Kino.Render.to_livebook()
  end
end
