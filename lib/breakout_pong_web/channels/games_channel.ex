defmodule BreakoutPongWeb.GamesChannel do
  use BreakoutPongWeb, :channel

  alias BreakoutPong.Game
  alias BreakoutPong.BackupAgent

  intercept ["update_players"]

  def join("games:" <> name, payload, socket) do
    if authorized?(payload) do
      game = BackupAgent.get(name) || Game.new()
      player = Map.get(payload, "user")
      game = BreakoutPong.Game.add_to_lobby(game, player)
      BackupAgent.put(name, game)
      update_players(name, player)

      socket = socket
      |> assign(:player, player)
      |> assign(:game, game)
      |> assign(:name, name)
      {:ok, %{"join" => name, "game" => Game.client_view(game)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("onkey", %{"keypressed" => ll}, socket) do
    name = socket.assigns[:name]
    game = Game.key_pressed(socket.assigns[:game], ll)
    socket = assign(socket, :game, game)
    BackupAgent.put(name, game)
    IO.inspect(game)
    {:reply, {:ok, %{ "game" => Game.client_view(game)}}, socket}
  end

  def handle_out("update_players", game, socket) do
    player = socket.assigns[:player]
    name = socket.assigns[:name]
    if player && name do
      IO.puts("This player is RECEIVING update:")
      IO.puts(player)
      push socket, "update", game
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def update_players(name, player) do
    IO.puts("This player is SENDING update:")
    IO.puts(player)
    if player do
      game = BackupAgent.get(name)
      {:ok, game}
      BreakoutPongWeb.Endpoint.broadcast!("games:#{name}", "update_players", game)
    end
  end
  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  #
end
