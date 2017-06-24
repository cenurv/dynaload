defmodule Dynaload do
  @moduledoc """
  Provides functionality to loading elixir script file based packages of
  functionality. These are to be loaded in at runtime not compile time.
  The primary method of grabbing packages will be through git downloading
  repositories into the ```.dyna_packages``` folder at the root of the
  project that integrates this library.
  """

  @package_base ".dyna_packages"

  defmacro __using__(_opts) do
    quote do
      import Dynaload, only: [require_script: 1]
    end
  end

  defp package_folder(package), do: "#{@package_base}/#{package}"

  defp get_process_agent_name do
    pid = to_string(inspect self())
    String.to_atom "package_for_" <> pid
  end

  defp set_package(package) do
    Agent.start_link(fn -> package end, name: get_process_agent_name())
  end

  defp get_package do
    Agent.get(get_process_agent_name(), &(&1))
  end

  defp clear_package do
    Agent.stop get_process_agent_name()
  end

  @doc """
  Launches a elixir script package from the package folder.
  Will always load the index.exs file in the root of the
  package. That file is responsible for using `require_script`
  to load other files.
  """
  def launch(package) do
    set_package package
    run package, :index
    clear_package()
  end

  defp run(package, script_name) do
    Code.load_file("#{to_string(script_name)}.exs", package_folder(package))
  end

  @doc """
  Reads and executes immediately an Elixir script from the current process package.
  Used inside the elixir script files to load other files.
  """
  def require_script(script_name) do
    run get_package(), script_name
  end

  @doc """
  Installs a new package from in a git repository or
  simple returns the git reference if it is already
  installed. This will not update the package from
  the remote git repository. For that functionality
  use `update_package`.
  """
  def fetch_package(package, url) do
    folder = package_folder(package)
    if File.exists?(folder) do
      {:ok, Git.new(Path.absname(folder))}
    else
      Git.clone [url, folder] 
    end
  end

  @doc """
  Uses git pull to update the package. Will throw
  an error if the package name is not installed.
  """
  def update_package(package) do
    folder = package_folder(package)

    if File.exists?(folder) do
      Git.pull Git.new(folder)
    else
      {:error, :package_not_installed}
    end
  end

  @doc """
  Scans the packages folder and updates all sub folder
  repos.
  """
  def update_installed_packages do
    case File.ls @package_base do
      {:error, :enoent} -> {:error, :packages_not_installed}
      {:ok, files} ->
        # Filter out files that start with "." and are folders
        files
        |> Enum.filter(&(not String.starts_with?(&1, ".")))
        |> Enum.filter(&(File.dir?(package_folder(&1))))
        |> Enum.reduce(%{}, &(Map.put(&2, &1, update_package(&1))))
    end
  end
end
