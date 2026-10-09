# macroengine:issues - show the open GitHub issues for this repository.
#
# The data is not fetched by this function. Datapacks cannot make network
# requests, and SECURITY.md sections 3 and 4 forbid turning in-game state into
# anything that reaches a shell or the network. Instead the companion tool
# `scripts/packd` reads the GitHub API and writes the result into the
# `macroengine:issues` storage; this function only renders what is already
# there. The flow is one-way: tool -> server, never server -> tool.
#
#   on the host:  python3 -m packd issues
#   in game:      /function macroengine:issues

# `execute if data storage <target> <path>` needs a path; the bare target form
# is not valid. packd always writes `schema` first, so that key is the test for
# "something has been published".

# Nothing published yet.
execute unless data storage macroengine:issues schema run function macroengine:core/internal/issues/empty

# Published.
execute if data storage macroengine:issues schema run function macroengine:core/internal/issues/header
execute if data storage macroengine:issues schema run function macroengine:api/issues/show
