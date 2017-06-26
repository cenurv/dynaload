defmodule Dynaload.Packager.Local do
  @moduledoc """

  """
  use Dynaload.Packager

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

      expanded_path = Path.expand path, Path.absname(".")

      File.write! "#{folder}/index.exs", """
        import Dynaload
        update_options fn(options) -> Map.put options, :folder, "#{expanded_path}" end
        require_script :index
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
