# Dynaload

A library designed to help load dynamic feature support intended to extend an application.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dynaload` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:dynaload, "~> 0.1.0"}]
end
```

## Usage

This library is designed to aid in fetching a package of Elixir scripts directly from Git or
from the local file system. The package is either a repo or a ordinary folder with Elixir
script (.exs) files.

The package is installed in the application working folder under the `.dynaload_packages`
folder. This is only intended to be the execution loaction and scripts should not be
modifed at this location. Loadinf Git requires git be installed on the system installing
the package and security permissions already resolved such as SSH security.

### Package Structure

```text
/
 install.exs      (<- The script that gets executed on install of the package [Required].)
 uninstall.exs    (<- The script that gets executed on uninstall of the package [Optional].)
 ...

Any other scripts must be imported through the `install.exs` or the `uninstall.exs` scripts.
Any resource may be packaged with the script bundle. Packages do not have the ability to
require mix dependencies, however all scripts do have access to any dependecies installed
by the application installing this package.
```

### Script Samples

* index.exs *

```elixir
use Dynaload
require Logger

require_script "script_a"

Logger.info "Installed package."
```

* script_a.exs *

```
use Dynaload

require Logger

require_script "subfolder/script_b"

Logger.info "Loaded script A"
```

* subfolder/script_b.exs *

```
use Dynaload

require Logger

Logger.info "Loaded script B"
```

### Feature Registration

Dynaload will only load the scripts themselves, it is up to your application to provide extension integration points.
The packages are intended to add custom specialized logic and not major features of you application. Major features
are better written into your application, and the dynamic loading of Elixir scripts should be used to add customizations
that are not part of your core business logic.

## Installing

```elixir
Dynaload.fetch_package ""
```