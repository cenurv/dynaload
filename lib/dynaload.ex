defmodule Dynaload do
  @moduledoc """
  Provides functionality to loading elixir script file based packages of
  functionality. These are to be loaded in at runtime not compile time.
  The primary method of grabbing packages will be through git downloading
  repositories into the ```.dyna_packages``` folder at the root of the
  project that integrates this library.
  """

  @package_base :".dyna_packages"

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

  def launch(package) do
    set_package package
    run package, :index
    clear_package()
  end

  defp run(package, script_name) do
    Code.load_file("#{to_string(script_name)}.exs", package_folder(package))
  end

  def require_script(script_name) do
    run get_package(), script_name
  end

  def fetch_package(package, url) do
    folder = package_folder(package)
    if File.exists?(folder) do
      {:ok, %Git.Repository{path: Path.absname(folder)}}
    else
      Git.clone [url, folder]
    end
  end
end
