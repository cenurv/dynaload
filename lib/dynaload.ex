defmodule Dynaload do
  @moduledoc """
  Provides functionality to loading elixir script file based packages of
  functionality. These are to be loaded in at runtime not compile time.
  The primary method of grabbing packages will be through git downloading
  repositories into the ```.dyna_packages``` folder at the root of the
  project that integrates this library.
  """
  @package_base ".dynaload_packages"

  defmacro __using__(_opts) do
    quote do
      import Dynaload, only: [require_script: 1, update_options: 1]
    end
  end

  defp package_folder(package) do
    folder = "#{get_options().folder}/#{package}"

    # most likely an absolute path if the project name
    # is not found under the folder. I need a better way
    # to handle this.
    if not File.exists? folder do
      get_options().folder
    end
  end

  defp get_process_agent_options_name do
    pid = to_string(inspect self())
    String.to_atom "packager_options_for_" <> pid
  end

  defp put_options(options) do
    Agent.start_link(fn -> options end, name: get_process_agent_options_name())
  end

  defp get_options do
    Agent.get(get_process_agent_options_name(), &(&1))
  end

  defp clear_options do
    Agent.stop get_process_agent_options_name()
  end

  defp run(package, script_name) do
    Code.load_file("#{to_string(script_name)}.exs", package_folder(package))
  end

  @doc """
  Allows a script to update the options used in the launch context.
  """
  def update_options(fun) do
    Agent.update get_process_agent_options_name(), fun
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

  defp get_installed_packages(opts \\ []) do
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
  Scans the packages folder and launches all packages.
  Will not launch in any guaranteed order, packages should
  not be written to be dependent upon other packages in the
  script. To use functionality, declare a module with function
  that can be called after all packages have been launched.
  """
  def launch_installed_packages(opts \\ []) do
    packages = get_installed_packages(opts)
    Enum.reduce(packages, %{}, &(Map.put(&2, &1, launch(&1, opts))))
  end

  @doc """
  Reads and executes immediately an Elixir script from the current process package.
  Used inside the elixir script files to load other files.
  """
  def require_script(script_name) do
    run get_options().package, script_name
  end

  @doc """
  Installs a new package from in a git repository or
  simple returns the git reference if it is already
  installed. This will not update the package from
  the remote git repository. For that functionality
  use `update_package`.
  """
  def fetch_package(package, opts \\ []) do
    packager = Keyword.get opts, :packager, Dynaload.Packager.Git
    packager.fetch_package package, opts
  end

  @doc """
  Uses git pull to update the package. Will throw
  an error if the package name is not installed.
  """
  def update_package(package, opts \\ []) do
    packager = Keyword.get opts, :packager, Dynaload.Packager.Git
    packager.update_package package, opts
  end

  @doc """
  Scans the packages folder and updates all sub folder
  repos.
  """
  def update_installed_packages(opts \\ []) do
    packages = get_installed_packages(opts)
    Enum.reduce(packages, %{}, &(Map.put(&2, &1, update_package(&1, opts))))
  end

  @doc """
  Remove an installed package.
  """
  def remove_package(package, opts \\ []) do
    packager = Keyword.get opts, :packager, Dynaload.Packager.Git
    packager.remove_package package, opts
  end

  @doc """
  Remove all installed packages, this will not remove the code from the running
  application since it has already been compiled. You will need to restart
  your application to have the code completely removed.
  """
  def remove_installed_packages(opts \\ []) do
    packages = get_installed_packages(opts)
    Enum.reduce(packages, %{}, &(Map.put(&2, &1, remove_package(&1, opts))))
  end
end
