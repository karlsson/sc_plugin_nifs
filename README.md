# sc_plugin_nifs
Elixir Erlang NIF versions of SuperCollider UGen plugins

## SuperCollider Plugins

SC plugins uses NIFs for generating and transforming the frames in a similar way as SuperCollider (SC) uses UGens.
SC "plugins" should implement the SC.Plugin behavior.

## Installation

  **Include from github.**
  - In your applications mix.exs, in deps part, include
  {:sc_plugin_nifs, git: "https://github.com/karlsson/sc_plugin_nifs.git"}}
  - mix deps.get
  - mix deps.compile

## License

The code is modified from SuperCollider and hence uses the same license:

"SuperCollider is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version." See COPYING file for the license text."

## Reference
https://github.com/supercollider/supercollider/tree/develop/server/plugins
