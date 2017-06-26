defmodule Dynaload.Packager.Git do
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
    url = Keyword.get opts, :url

    if url do
      folder = Keyword.get opts, :folder, @package_base
      folder = "#{folder}/#{package}"
      if File.exists?(folder) do
        {:ok, Git.new(Path.absname(folder))}
      else
        Git.clone [url, folder]
      end
    else
      throw :no_url_provided
    end
  end


  @doc """
  Uses git pull to update the package. Will throw
  an error if the package name is not installed.
  """
  def update_package(package, opts \\ []) do
    folder = Keyword.get opts, :folder, @package_base
    folder = "#{folder}/#{package}"

    if File.exists?(folder) do
      Git.pull Git.new(folder)
    else
      {:error, :package_not_installed}
    end
  end

  def remove_package(package, opts \\ []) do
    folder = Keyword.get opts, :folder, @package_base
    folder = "#{folder}/#{package}"

    File.rm folder
  end
end
