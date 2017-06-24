defmodule Dynaload.Packager do
  @moduledoc """
  Basic interface for a packager. A packager is reponsible for
  reading in Dynaload Elixir script packages and macking them
  available to load/execute.
  """

  @callback launch(package_name :: String.t | Atom.t, options :: Keyword.t) :: :ok | {:error, Atom.t}
  @callback require_script(script_name :: String.t | Atom.t) :: :ok | {:error, Atom.t}
end