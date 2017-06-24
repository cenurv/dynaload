defmodule Dynaload do
  @moduledoc """
  Provides functionality to loading elixir script file based packages of
  functionality. These are to be loaded in at runtime not compile time.
  The primary method of grabbing packages will be through git downloading
  repositories into the ```.dyna_packages``` folder at the root of the
  project that integrates this library.
  """

  defmacro __using__(_opts) do
    quote do
      import Dynaload, only: [require_script: 1]
    end
  end

  defp get_process_agent_name do
    pid = to_string(inspect self())
    String.to_atom "packager_for_" <> pid
  end

  defp set_packager(packager) do
    Agent.start_link(fn -> packager end, name: get_process_agent_name())
  end

  defp get_packager do
    Agent.get(get_process_agent_name(), &(&1))
  end

  defp clear_packager do
    Agent.stop get_process_agent_name()
  end

  @doc """
  Launches a elixir script package from the package folder.
  Will always load the index.exs file in the root of the
  package. That file is responsible for using `require_script`
  to load other files.
  """
  def launch(package, opts \\ []) do
    packager = Keyword.get opts, :packager, Dynaload.Packager.Git
    set_packager packager
    packager.launch package, opts
    clear_packager()
  end

  @doc """
  Scans the packages folder and launches all packages.
  Will not launch in any guaranteed order, packages should
  not be written to be dependent upon other packages in the
  script. To use functionality, declare a module with function
  that can be called after all packages have been launched.
  """
  def launch_installed_packages(opts \\ []) do
    packager = Keyword.get opts, :packager, Dynaload.Packager.Git
    packages = packager.get_installed_packages opts
    Enum.reduce(packages, %{}, &(Map.put(&2, &1, launch(&1, opts))))
  end

  @doc """
  Reads and executes immediately an Elixir script from the current process package.
  Used inside the elixir script files to load other files.
  """
  def require_script(script_name) do
    get_packager().require_script script_name
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
    packager = Keyword.get opts, :packager, Dynaload.Packager.Git
    packages = packager.get_installed_packages opts
    Enum.reduce(packages, %{}, &(Map.put(&2, &1, update_package(&1, opts))))
  end
end
