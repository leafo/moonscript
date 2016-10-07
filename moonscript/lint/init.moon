parse = require "moonscript.parse"
{:pos_to_line, :get_line} = require "moonscript.util"
config = require "moonscript.lint.config"

append = table.insert

add = (map, key, val) ->
  list = map[key]
  unless list
    list = {}
    map[key] = list

  append list, val

Scope = (node, parent) ->
  assert node, "Missing node"
  declared = {}
  used = {}
  scopes = {}
  shadowing_decls = {}
  pos = node[-1]
  if not pos and parent
    pos = parent.pos

  {
    :parent,
    :declared,
    :used,
    :shadowing_decls,
    :scopes,
    :node,
    :pos,
    type: 'default'

    has_declared: (name) =>
      return true if declared[name]
      parent and parent\has_declared(name)

    has_parent: (type) =>
      return false unless parent
      return true if parent.type == type
      return parent\has_parent type

    add_declaration: (name, opts) =>
      if parent and parent\has_declared(name)
        add shadowing_decls, name, opts

      add declared, name, opts

    add_assignment: (name, ass) =>
      return if @has_declared name
      if not parent or not parent\has_declared(name)
        add declared, name, ass

    add_ref: (name, ref) =>
      if declared[name]
        add used, name, ref
      else if parent and parent\has_declared(name)
        parent\add_ref name, ref
      else
        add used, name, ref

    open_scope: (sub_node, type) =>
      scope = Scope sub_node, @
      scope.type = type
      append scopes, scope
      scope
  }

has_subnode = (node, types) ->
  return false unless type(node) == 'table'
  for t in *types
    return true if node[1] == t

  for n in *node
    return true if has_subnode n, types

  false

is_loop_assignment = (list) ->
  node = list[1]
  return false unless type(node) == 'table'
  return false unless node[1] == 'chain'
  last = node[#node]
  return false unless last[1] == 'call'
  c_target = last[2]
  return false unless type(c_target) == 'table' and #c_target == 1
  op = c_target[1][1]
  op == 'for' or op == 'foreach'

is_fndef_assignment = (list) ->
  node = list[1]
  return false unless type(node) == 'table'
  node[1] == 'fndef'

destructuring_decls = (list) ->
  found = {}
  for exp_list in *list
    for t_var in *exp_list
      if type(t_var) == 'table'
        switch t_var[1]
          when 'ref'
            append found, { t_var[2], t_var[-1] }
          when 'table'
            for name, pos in destructuring_decls(t_var[2])
              append found, { name, pos }

  i = 1
  ->
    decl = found[i]
    return nil unless decl
    i += 1
    decl[1], decl[2]

handlers = {
  update: (node, scope, walk, ref_pos) ->
    target, val = node[2], node[4]

    unless scope.is_wrapper
      if is_loop_assignment({val})
        scope = scope\open_scope node, 'loop-update'
        scope.is_wrapper = true

    if target[1] == 'ref'
      scope\add_assignment target[2], pos: target[-1] or ref_pos
    else
      walk target, scope, ref_pos

    walk {val}, scope, ref_pos

  -- x, y = foo!, ...
  assign: (node, scope, walk, ref_pos) ->
    targets = node[2]
    values = node[3]
    pos = node[-1] or ref_pos

    unless scope.is_wrapper
      if is_loop_assignment(values)
        scope = scope\open_scope node, 'loop-assignment'
        scope.is_wrapper = true

    is_fndef = is_fndef_assignment values

    -- values are walked before the lvalue, except for fndefs where
    -- the lvalue is implicitly local
    walk values, scope, ref_pos unless is_fndef

    for t in *targets
      switch t[1] -- type of target
        when 'ref' -- plain assignment, e.g. 'x = 1'
          scope\add_assignment t[2], pos: t[-1] or pos
        when 'chain'
          -- chained assignment, e.g. 'x.foo = 1' - walk all references
          walk t, scope, ref_pos
        when 'table' -- handle decomposition syntax, e.g. '{:foo} = table'
          for name, d_pos in destructuring_decls(t[2])
            scope\add_assignment name, pos: d_pos or pos

    walk values, scope, ref_pos if is_fndef

  chain: (node, scope, walk, ref_pos) ->
    if not scope.is_wrapper and is_loop_assignment({node})
      scope = scope\open_scope node, 'chain'
      scope.is_wrapper = true

    walk node, scope, ref_pos

  ref: (node, scope, walk, ref_pos) ->
    scope\add_ref node[2], pos: node[-1] or ref_pos

  fndef: (node, scope, walk, ref_pos) ->
    params, f_type, body = node[2], node[4], node[5]
    t = f_type == 'fat' and 'method' or 'function'
    scope = scope\open_scope node, t
    pos = node[-1] or ref_pos
    for p in *params
      def = p[1]
      if type(def) == 'string'
        scope\add_declaration def, :pos, type: 'param'
        if p[2] -- default parameter assignment
          walk {p[2]}, scope, ref_pos
      elseif type(def) == 'table' and def[1] == 'self'
        scope\add_declaration def[2], :pos, type: 'param'
        scope\add_ref def[2], :pos
        if p[2] -- default parameter assignment
          walk {p[2]}, scope, ref_pos
      else
        walk {p}, scope, ref_pos

    walk body, scope, ref_pos

  for: (node, scope, walk, ref_pos) ->
    var, args, body = node[2], node[3], node[4]

    unless scope.is_wrapper
      scope = scope\open_scope node, 'for'

    scope\add_declaration var, pos: node[-1] or ref_pos, type: 'loop-var'

    walk args, scope, ref_pos
    walk body, scope, ref_pos if body

  foreach: (node, scope, walk, ref_pos) ->
    vars, args, body = node[2], node[3], node[4]

    if not body
      body = args
      args = nil

    unless scope.is_wrapper
      scope = scope\open_scope node, 'for-each'

    walk args, scope, ref_pos if args

    for var in *vars
      switch type(var)
        when 'string'
          scope\add_declaration var, pos: node[-1] or ref_pos, type: 'loop-var'
        when 'table'
          if var[1] == 'table'
            for name, pos in destructuring_decls(var[2])
              scope\add_declaration name, pos: pos or ref_pos, type: 'loop-var'

    walk body, scope, ref_pos

  declare_with_shadows: (node, scope, walk, ref_pos) ->
    names = node[2]
    for name in *names
      scope\add_declaration name, pos: node[-1] or ref_pos

  export: (node, scope, walk, ref_pos) ->
    names, vals = node[2], node[3]
    if type(names) == 'string' -- `export *`
      scope.exported_from = node[-1]
    else
      for name in *names
        scope\add_declaration name, pos: node[-1] or ref_pos, is_exported: true, type: 'export'

    if vals
      walk {vals}, scope, ref_pos

  import: (node, scope, walk, ref_pos) ->
    names, values = node[2], node[3]

    for name in *names
      if type(name) == 'table' and name[1] == 'colon'
        name = name[2] -- import \foo from bar

      scope\add_declaration name, pos: node[-1] or ref_pos, type: 'import'

    walk {values}, scope, ref_pos

  decorated: (node, scope, walk, ref_pos) ->
    stm, vals = node[2], node[3]

    -- statement modifiers with `if` and `unless` does not open a new scope
    unless vals[1] == 'if' or vals[1] == 'unless'
      scope = scope\open_scope node, 'decorated'
      scope.is_wrapper = true

    walk {vals}, scope, ref_pos
    walk {stm}, scope, ref_pos

  comprehension: (node, scope, walk, ref_pos) ->
    exps, loop = node[2], node[3]

    unless scope.is_wrapper
      scope = scope\open_scope node, 'comprehension'
      scope.is_wrapper = true

    unless loop
      loop = exps
      exps = nil

    -- we walk the loop first, as it's there that the declarations are
    walk {loop}, scope, ref_pos
    walk {exps}, scope, ref_pos if exps

  tblcomprehension: (node, scope, walk, ref_pos) ->
    exps, loop = node[2], node[3]

    unless scope.is_wrapper
      scope = scope\open_scope node, 'tblcomprehension'
      scope.is_wrapper = true

    -- we walk the loop first, as it's there that the declarations are
    unless loop
      loop = exps
      exps = nil

    walk {loop}, scope, ref_pos
    walk {exps}, scope, ref_pos if exps

  class: (node, scope, walk, ref_pos) ->
    name, parent, body = node[2], node[3], node[4]
    handle_name = name and type(name) == 'string'
    if handle_name
      scope\add_declaration name, pos: node[-1] or ref_pos, type: 'class'

    -- handle implicit return of class, if last node of current scope
    if handle_name and scope.node[#scope.node] == node
      scope\add_ref name, pos: node[-1] or ref_pos

    walk {parent}, scope, ref_pos
    scope = scope\open_scope node, 'class'
    walk body, scope, ref_pos

  while: (node, scope, walk, ref_pos) ->
    conds, body = node[2], node[3]
    walk {conds}, scope, ref_pos

    cond_scope = scope\open_scope node, 'while'
    walk body, cond_scope, ref_pos if body

  with: (node, scope, walk, ref_pos) ->
    assigns, body = node[2], node[3]

    with_scope = scope\open_scope node, 'with'
    walk {assigns}, with_scope, ref_pos

    -- mark any declaration as used immediately
    for name in pairs with_scope.declared
      with_scope\add_ref name, pos: ref_pos

    walk {body}, with_scope, ref_pos

  -- if, elseif, unless
  cond_block: (node, scope, walk, ref_pos) ->
    op, conds, body = node[1], node[2], node[3]
    walk {conds}, scope, ref_pos

    cond_scope = scope\open_scope node, op
    walk body, cond_scope, ref_pos if body

    -- walk any following elseifs/elses as necessary
    rest = [n for i, n in ipairs(node) when i > 3]
    if #rest > 0
      walk rest, scope, ref_pos

  else: (node, scope, walk, ref_pos) ->
    body = node[2]
    scope = scope\open_scope node, 'else'
    walk body, scope, ref_pos

}

handlers['if'] = handlers.cond_block
handlers['elseif'] = handlers.cond_block
handlers['unless'] = handlers.cond_block

resolve_pos = (node, base_pos) ->
  return node[-1] if node[-1]
  if type(node) == 'table'
    for sub_node in *node
      if type(sub_node) == 'table'
        if sub_node[-1]
          return sub_node[-1]

  base_pos

walk = (tree, scope, base_pos) ->
  unless tree
    error "nil passed for node: #{debug.traceback!}"

  unless base_pos
    error "nil passed for base_pos: #{debug.traceback!}"

  for node in *tree
    ref_pos = resolve_pos(node, base_pos)
    handler = handlers[node[1]]
    if handler
      handler node, scope, walk, ref_pos
    else
      for sub_node in *node
        if type(sub_node) == 'table'
          walk { sub_node }, scope, ref_pos

report_on_scope = (scope, evaluator, inspections = {}) ->

  -- Declared but unused variables
  for name, decls in pairs scope.declared
    continue if scope.used[name]

    for decl in *decls
      if decl.is_exported or scope.exported_from and scope.exported_from < decl.pos
        continue

      if decl.type == 'param'
        continue if evaluator.allow_unused_param(name)
      elseif decl.type == 'loop-var'
        continue if evaluator.allow_unused_loop_variable(name)
      else
        continue if evaluator.allow_unused(name)

      append inspections, {
        msg: "declared but unused - `#{name}`"
        pos: decl.pos or scope.pos,
      }

  -- Used but undefined references
  for name, nodes in pairs scope.used
    unless scope.declared[name] or evaluator.allow_global_access(name)
      if name == 'self' or name == 'super'
        if scope.type == 'method' or scope\has_parent('method')
          continue

      for node in *nodes
        append inspections, {
          msg: "accessing global - `#{name}`"
          pos: node.pos or scope.pos,
        }

    -- Shadowing declarations
  for name, nodes in pairs scope.shadowing_decls
    unless evaluator.allow_shadowing(name)
      for node in *nodes
        append inspections, {
          msg: "shadowing outer variable - `#{name}`"
          pos: node.pos or scope.pos,
        }

  for sub_scope in *scope.scopes
    report_on_scope sub_scope, evaluator, inspections

  inspections

format_inspections = (inspections) ->
  chunks = {}
  for inspection in *inspections
    chunk = "line #{inspection.line}: #{inspection.msg}\n"
    chunk ..= string.rep('=', #chunk - 1) .. '\n'
    chunk ..= "> #{inspection.code}\n"
    chunks[#chunks + 1]  = chunk

  table.concat chunks, '\n'

report = (scope, code, opts = {}) ->
  inspections = {}
  evaluator = config.evaluator opts
  report_on_scope scope, evaluator, inspections

  for inspection in *inspections
    line = pos_to_line(code, inspection.pos)
    inspection.line = line
    inspection.code = get_line code, line

  table.sort inspections, (a, b) -> a.line < b.line
  inspections

lint = (code, opts = {}) ->
  tree, err = parse.string code
  return nil, err unless tree
  require('moon').p(tree) if opts.print_tree
  scope = Scope tree
  walk tree, scope, 1
  report scope, code, opts

lint_file = (file, opts = {}) ->
  fh = assert io.open file, 'r'
  code = fh\read '*a'
  fh\close!
  config_file = opts.lint_config or config.config_for(file)
  opts = config_file and config.load_config_from(config_file, file) or {}
  opts.file = file
  lint code, opts

:lint, :lint_file, :format_inspections, :config
