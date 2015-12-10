import ntype from require "moonscript.types"

class Transformer
  new: (@transformers) =>
    @seen_nodes = setmetatable {}, __mode: "k"

  transform_once: (scope, node, ...) =>
    return node if @seen_nodes[node]
    @seen_nodes[node] = true

    transformer = @transformers[ntype node]
    if transformer
      transformer(scope, node, ...) or node
    else
      node

  transform: (scope, node, ...) =>
    return node if @seen_nodes[node]

    @seen_nodes[node] = true
    while true
      transformer = @transformers[ntype node]
      res = if transformer
        transformer(scope, node, ...) or node
      else
        node

      return node if res == node
      node = res

    node

  bind: (scope) =>
    (...) -> @transform scope, ...

  __call: (...) => @transform ...

  can_transform: (node) =>
    @transformers[ntype node] != nil


{ :Transformer }
