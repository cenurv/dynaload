defmodule Dynaload.Packager do
  @moduledoc """
  Basic interface for a packager. A packager is reponsible for
  reading in Dynaload Elixir script packages and macking them
  available to load/execute.
  """
  @package_base ".dynaload_packages"

  defmacro __using__(_opts) do
    quote do
      @behaviour Dynaload.Packager
      @package_base unquote(@package_base)
    end
  end

  @callback fetch_package(package_name :: String.t | Atom.t, options :: Keyword.t) :: String.t
  @callback update_package(package_name :: String.t | Atom.t, options :: Keyword.t) :: String.t
  @callback remove_package(package_name :: String.t | Atom.t, options :: Keyword.t) :: String.t
end
