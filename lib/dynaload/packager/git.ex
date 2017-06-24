defmodule Dynaload.Packager.Git do
  @moduledoc """

  """
  @behaviour Dynaload.Packager

  @package_base ".dynaload_packages"

  defp package_folder(package), do: "#{get_options().folder}/#{package}"

  defp get_process_agent_name do
    pid = to_string(inspect self())
    String.to_atom "packager_options_for_" <> pid
  end

  defp put_options(options) do
    Agent.start_link(fn -> options end, name: get_process_agent_name())
  end

  defp get_options do
    Agent.get(get_process_agent_name(), &(&1))
  end

  defp clear_options do
    Agent.stop get_process_agent_name()
  end

  defp run(package, script_name) do
    Code.load_file("#{to_string(script_name)}.exs", package_folder(package))
  end

  @doc """
  Launches a elixir script package from the package folder.
  Will always load the index.exs file in the root of the
  package. That file is responsible for using `require_script`
  to load other files.
  """
  def launch(package, opts \\ []) do
    folder = Keyword.get opts, :folder, @package_base
    put_options %{folder: folder, package: package}
    response = run package, :index
    clear_options()
    response
  end

  @doc """
  Reads and executes immediately an Elixir script from the current process package.
  Used inside the elixir script files to load other files.
  """
  def require_script(script_name) do
    run get_options().package, script_name
  end
end
