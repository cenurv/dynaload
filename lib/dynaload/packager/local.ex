defmodule Dynaload.Packager.Local do
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

  @doc """
  Fetches all currently installed packages.
  """
  def get_installed_packages(opts \\ []) do
    folder = Keyword.get opts, :folder, @package_base

    case File.ls folder do
      {:error, :enoent} -> {:error, :packages_not_installed}
      {:ok, files} ->
        # Filter out files that start with "." and are folders
        files
        |> Enum.filter(&(not String.starts_with?(&1, ".")))
        |> Enum.filter(&(File.dir?(package_folder(&1))))
    end
  end

  @doc """
  Installs a new package from in a git repository or
  simple returns the git reference if it is already
  installed. This will not update the package from
  the remote git repository. For that functionality
  use `update_package`.
  """
  def fetch_package(package, opts \\ []) do
    path = Keyword.get opts, :path

    if path do
      folder = Keyword.get opts, :folder, @package_base
      folder = "#{folder}/#{package}"
      if not File.exists?(folder) do
        File.mkdir! folder
      end

      File.write! "#{folder}/index.exs", """
        Code.load_file "#{path}/index.exs"
      """
    else
      throw :no_path_provided
    end
  end


  @doc """
  Uses git pull to update the package. Will throw
  an error if the package name is not installed.
  """
  def update_package(_package, _opts \\ []) do
    :ok
  end

  def remove_package(package, opts \\ []) do
    folder = Keyword.get opts, :folder, @package_base
    folder = "#{folder}/#{package}"

    File.rm folder
  end
end
