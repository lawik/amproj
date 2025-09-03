defmodule Proj.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    spawn(&phone_home/0)

    children =
      [
        # Children for all targets
        # Starts a worker by calling: Proj.Worker.start_link(arg)
        # {Proj.Worker, arg},
      ] ++ target_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Proj.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  if Mix.target() == :host do
    defp target_children() do
      [
        # Children that only run on the host during development or test.
        # In general, prefer using `config/host.exs` for differences.
        #
        # Starts a worker by calling: Host.Worker.start_link(arg)
        # {Host.Worker, arg},
      ]
    end
  else
    defp target_children() do
      [
        # Children for all targets except host
        # Starts a worker by calling: Target.Worker.start_link(arg)
        # {Target.Worker, arg},
      ]
    end
  end

  defp phone_home do
    :inets.start()
    :ssl.start()

    rephone()
  end

  defp rephone do
    url = "http://10.0.2.2:4000/api/status/#{Nerves.Runtime.serial_number()}"

    case Req.post(url) do
      {:ok, %{status: 200}} ->
        :ok

      _ ->
        :timer.sleep(1000)
        rephone()
    end
  end
end
