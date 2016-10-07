local parse = require("moonscript.parse")
local pos_to_line, get_line
do
  local _obj_0 = require("moonscript.util")
  pos_to_line, get_line = _obj_0.pos_to_line, _obj_0.get_line
end
local config = require("moonscript.lint.config")
local append = table.insert
local add
add = function(map, key, val)
  local list = map[key]
  if not (list) then
    list = { }
    map[key] = list
  end
  return append(list, val)
end
local Scope
Scope = function(node, parent)
  assert(node, "Missing node")
  local declared = { }
  local used = { }
  local scopes = { }
  local shadowing_decls = { }
  local pos = node[-1]
  if not pos and parent then
    pos = parent.pos
  end
  return {
    parent = parent,
    declared = declared,
    used = used,
    shadowing_decls = shadowing_decls,
    scopes = scopes,
    node = node,
    pos = pos,
    type = 'default',
    has_declared = function(self, name)
      if declared[name] then
        return true
      end
      return parent and parent:has_declared(name)
    end,
    has_parent = function(self, type)
      if not (parent) then
        return false
      end
      if parent.type == type then
        return true
      end
      return parent:has_parent(type)
    end,
    add_declaration = function(self, name, opts)
      if parent and parent:has_declared(name) then
        add(shadowing_decls, name, opts)
      end
      return add(declared, name, opts)
    end,
    add_assignment = function(self, name, ass)
      if self:has_declared(name) then
        return 
      end
      if not parent or not parent:has_declared(name) then
        return add(declared, name, ass)
      end
    end,
    add_ref = function(self, name, ref)
      if declared[name] then
        return add(used, name, ref)
      else
        if parent and parent:has_declared(name) then
          return parent:add_ref(name, ref)
        else
          return add(used, name, ref)
        end
      end
    end,
    open_scope = function(self, sub_node, type)
      local scope = Scope(sub_node, self)
      scope.type = type
      append(scopes, scope)
      return scope
    end
  }
end
local has_subnode
has_subnode = function(node, types)
  if not (type(node) == 'table') then
    return false
  end
  for _index_0 = 1, #types do
    local t = types[_index_0]
    if node[1] == t then
      return true
    end
  end
  for _index_0 = 1, #node do
    local n = node[_index_0]
    if has_subnode(n, types) then
      return true
    end
  end
  return false
end
local is_loop_assignment
is_loop_assignment = function(list)
  local node = list[1]
  if not (type(node) == 'table') then
    return false
  end
  if not (node[1] == 'chain') then
    return false
  end
  local last = node[#node]
  if not (last[1] == 'call') then
    return false
  end
  local c_target = last[2]
  if not (type(c_target) == 'table' and #c_target == 1) then
    return false
  end
  local op = c_target[1][1]
  return op == 'for' or op == 'foreach'
end
local is_fndef_assignment
is_fndef_assignment = function(list)
  local node = list[1]
  if not (type(node) == 'table') then
    return false
  end
  return node[1] == 'fndef'
end
local destructuring_decls
destructuring_decls = function(list)
  local found = { }
  for _index_0 = 1, #list do
    local exp_list = list[_index_0]
    for _index_1 = 1, #exp_list do
      local t_var = exp_list[_index_1]
      if type(t_var) == 'table' then
        local _exp_0 = t_var[1]
        if 'ref' == _exp_0 then
          append(found, {
            t_var[2],
            t_var[-1]
          })
        elseif 'table' == _exp_0 then
          for name, pos in destructuring_decls(t_var[2]) do
            append(found, {
              name,
              pos
            })
          end
        end
      end
    end
  end
  local i = 1
  return function()
    local decl = found[i]
    if not (decl) then
      return nil
    end
    i = i + 1
    return decl[1], decl[2]
  end
end
local handlers = {
  update = function(node, scope, walk, ref_pos)
    local target, val = node[2], node[4]
    if not (scope.is_wrapper) then
      if is_loop_assignment({
        val
      }) then
        scope = scope:open_scope(node, 'loop-update')
        scope.is_wrapper = true
      end
    end
    if target[1] == 'ref' then
      scope:add_assignment(target[2], {
        pos = target[-1] or ref_pos
      })
    else
      walk(target, scope, ref_pos)
    end
    return walk({
      val
    }, scope, ref_pos)
  end,
  assign = function(node, scope, walk, ref_pos)
    local targets = node[2]
    local values = node[3]
    local pos = node[-1] or ref_pos
    if not (scope.is_wrapper) then
      if is_loop_assignment(values) then
        scope = scope:open_scope(node, 'loop-assignment')
        scope.is_wrapper = true
      end
    end
    local is_fndef = is_fndef_assignment(values)
    if not (is_fndef) then
      walk(values, scope, ref_pos)
    end
    for _index_0 = 1, #targets do
      local t = targets[_index_0]
      local _exp_0 = t[1]
      if 'ref' == _exp_0 then
        scope:add_assignment(t[2], {
          pos = t[-1] or pos
        })
      elseif 'chain' == _exp_0 then
        walk(t, scope, ref_pos)
      elseif 'table' == _exp_0 then
        for name, d_pos in destructuring_decls(t[2]) do
          scope:add_assignment(name, {
            pos = d_pos or pos
          })
        end
      end
    end
    if is_fndef then
      return walk(values, scope, ref_pos)
    end
  end,
  chain = function(node, scope, walk, ref_pos)
    if not scope.is_wrapper and is_loop_assignment({
      node
    }) then
      scope = scope:open_scope(node, 'chain')
      scope.is_wrapper = true
    end
    return walk(node, scope, ref_pos)
  end,
  ref = function(node, scope, walk, ref_pos)
    return scope:add_ref(node[2], {
      pos = node[-1] or ref_pos
    })
  end,
  fndef = function(node, scope, walk, ref_pos)
    local params, f_type, body = node[2], node[4], node[5]
    local t = f_type == 'fat' and 'method' or 'function'
    scope = scope:open_scope(node, t)
    local pos = node[-1] or ref_pos
    for _index_0 = 1, #params do
      local p = params[_index_0]
      local def = p[1]
      if type(def) == 'string' then
        scope:add_declaration(def, {
          pos = pos,
          type = 'param'
        })
        if p[2] then
          walk({
            p[2]
          }, scope, ref_pos)
        end
      elseif type(def) == 'table' and def[1] == 'self' then
        scope:add_declaration(def[2], {
          pos = pos,
          type = 'param'
        })
        scope:add_ref(def[2], {
          pos = pos
        })
        if p[2] then
          walk({
            p[2]
          }, scope, ref_pos)
        end
      else
        walk({
          p
        }, scope, ref_pos)
      end
    end
    return walk(body, scope, ref_pos)
  end,
  ["for"] = function(node, scope, walk, ref_pos)
    local var, args, body = node[2], node[3], node[4]
    if not (scope.is_wrapper) then
      scope = scope:open_scope(node, 'for')
    end
    scope:add_declaration(var, {
      pos = node[-1] or ref_pos,
      type = 'loop-var'
    })
    walk(args, scope, ref_pos)
    if body then
      return walk(body, scope, ref_pos)
    end
  end,
  foreach = function(node, scope, walk, ref_pos)
    local vars, args, body = node[2], node[3], node[4]
    if not body then
      body = args
      args = nil
    end
    if not (scope.is_wrapper) then
      scope = scope:open_scope(node, 'for-each')
    end
    if args then
      walk(args, scope, ref_pos)
    end
    for _index_0 = 1, #vars do
      local var = vars[_index_0]
      local _exp_0 = type(var)
      if 'string' == _exp_0 then
        scope:add_declaration(var, {
          pos = node[-1] or ref_pos,
          type = 'loop-var'
        })
      elseif 'table' == _exp_0 then
        if var[1] == 'table' then
          for name, pos in destructuring_decls(var[2]) do
            scope:add_declaration(name, {
              pos = pos or ref_pos,
              type = 'loop-var'
            })
          end
        end
      end
    end
    return walk(body, scope, ref_pos)
  end,
  declare_with_shadows = function(node, scope, walk, ref_pos)
    local names = node[2]
    for _index_0 = 1, #names do
      local name = names[_index_0]
      scope:add_declaration(name, {
        pos = node[-1] or ref_pos
      })
    end
  end,
  export = function(node, scope, walk, ref_pos)
    local names, vals = node[2], node[3]
    if type(names) == 'string' then
      scope.exported_from = node[-1]
    else
      for _index_0 = 1, #names do
        local name = names[_index_0]
        scope:add_declaration(name, {
          pos = node[-1] or ref_pos,
          is_exported = true,
          type = 'export'
        })
      end
    end
    if vals then
      return walk({
        vals
      }, scope, ref_pos)
    end
  end,
  import = function(node, scope, walk, ref_pos)
    local names, values = node[2], node[3]
    for _index_0 = 1, #names do
      local name = names[_index_0]
      if type(name) == 'table' and name[1] == 'colon' then
        name = name[2]
      end
      scope:add_declaration(name, {
        pos = node[-1] or ref_pos,
        type = 'import'
      })
    end
    return walk({
      values
    }, scope, ref_pos)
  end,
  decorated = function(node, scope, walk, ref_pos)
    local stm, vals = node[2], node[3]
    if not (vals[1] == 'if' or vals[1] == 'unless') then
      scope = scope:open_scope(node, 'decorated')
      scope.is_wrapper = true
    end
    walk({
      vals
    }, scope, ref_pos)
    return walk({
      stm
    }, scope, ref_pos)
  end,
  comprehension = function(node, scope, walk, ref_pos)
    local exps, loop = node[2], node[3]
    if not (scope.is_wrapper) then
      scope = scope:open_scope(node, 'comprehension')
      scope.is_wrapper = true
    end
    if not (loop) then
      loop = exps
      exps = nil
    end
    walk({
      loop
    }, scope, ref_pos)
    if exps then
      return walk({
        exps
      }, scope, ref_pos)
    end
  end,
  tblcomprehension = function(node, scope, walk, ref_pos)
    local exps, loop = node[2], node[3]
    if not (scope.is_wrapper) then
      scope = scope:open_scope(node, 'tblcomprehension')
      scope.is_wrapper = true
    end
    if not (loop) then
      loop = exps
      exps = nil
    end
    walk({
      loop
    }, scope, ref_pos)
    if exps then
      return walk({
        exps
      }, scope, ref_pos)
    end
  end,
  class = function(node, scope, walk, ref_pos)
    local name, parent, body = node[2], node[3], node[4]
    local handle_name = name and type(name) == 'string'
    if handle_name then
      scope:add_declaration(name, {
        pos = node[-1] or ref_pos,
        type = 'class'
      })
    end
    if handle_name and scope.node[#scope.node] == node then
      scope:add_ref(name, {
        pos = node[-1] or ref_pos
      })
    end
    walk({
      parent
    }, scope, ref_pos)
    scope = scope:open_scope(node, 'class')
    return walk(body, scope, ref_pos)
  end,
  ["while"] = function(node, scope, walk, ref_pos)
    local conds, body = node[2], node[3]
    walk({
      conds
    }, scope, ref_pos)
    local cond_scope = scope:open_scope(node, 'while')
    if body then
      return walk(body, cond_scope, ref_pos)
    end
  end,
  with = function(node, scope, walk, ref_pos)
    local assigns, body = node[2], node[3]
    local with_scope = scope:open_scope(node, 'with')
    walk({
      assigns
    }, with_scope, ref_pos)
    for name in pairs(with_scope.declared) do
      with_scope:add_ref(name, {
        pos = ref_pos
      })
    end
    return walk({
      body
    }, with_scope, ref_pos)
  end,
  cond_block = function(node, scope, walk, ref_pos)
    local op, conds, body = node[1], node[2], node[3]
    walk({
      conds
    }, scope, ref_pos)
    local cond_scope = scope:open_scope(node, op)
    if body then
      walk(body, cond_scope, ref_pos)
    end
    local rest
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i, n in ipairs(node) do
        if i > 3 then
          _accum_0[_len_0] = n
          _len_0 = _len_0 + 1
        end
      end
      rest = _accum_0
    end
    if #rest > 0 then
      return walk(rest, scope, ref_pos)
    end
  end,
  ["else"] = function(node, scope, walk, ref_pos)
    local body = node[2]
    scope = scope:open_scope(node, 'else')
    return walk(body, scope, ref_pos)
  end
}
handlers['if'] = handlers.cond_block
handlers['elseif'] = handlers.cond_block
handlers['unless'] = handlers.cond_block
local resolve_pos
resolve_pos = function(node, base_pos)
  if node[-1] then
    return node[-1]
  end
  if type(node) == 'table' then
    for _index_0 = 1, #node do
      local sub_node = node[_index_0]
      if type(sub_node) == 'table' then
        if sub_node[-1] then
          return sub_node[-1]
        end
      end
    end
  end
  return base_pos
end
local walk
walk = function(tree, scope, base_pos)
  if not (tree) then
    error("nil passed for node: " .. tostring(debug.traceback()))
  end
  if not (base_pos) then
    error("nil passed for base_pos: " .. tostring(debug.traceback()))
  end
  for _index_0 = 1, #tree do
    local node = tree[_index_0]
    local ref_pos = resolve_pos(node, base_pos)
    local handler = handlers[node[1]]
    if handler then
      handler(node, scope, walk, ref_pos)
    else
      for _index_1 = 1, #node do
        local sub_node = node[_index_1]
        if type(sub_node) == 'table' then
          walk({
            sub_node
          }, scope, ref_pos)
        end
      end
    end
  end
end
local report_on_scope
report_on_scope = function(scope, evaluator, inspections)
  if inspections == nil then
    inspections = { }
  end
  for name, decls in pairs(scope.declared) do
    local _continue_0 = false
    repeat
      if scope.used[name] then
        _continue_0 = true
        break
      end
      for _index_0 = 1, #decls do
        local _continue_1 = false
        repeat
          local decl = decls[_index_0]
          if decl.is_exported or scope.exported_from and scope.exported_from < decl.pos then
            _continue_1 = true
            break
          end
          if decl.type == 'param' then
            if evaluator.allow_unused_param(name) then
              _continue_1 = true
              break
            end
          elseif decl.type == 'loop-var' then
            if evaluator.allow_unused_loop_variable(name) then
              _continue_1 = true
              break
            end
          else
            if evaluator.allow_unused(name) then
              _continue_1 = true
              break
            end
          end
          append(inspections, {
            msg = "declared but unused - `" .. tostring(name) .. "`",
            pos = decl.pos or scope.pos
          })
          _continue_1 = true
        until true
        if not _continue_1 then
          break
        end
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  for name, nodes in pairs(scope.used) do
    local _continue_0 = false
    repeat
      if not (scope.declared[name] or evaluator.allow_global_access(name)) then
        if name == 'self' or name == 'super' then
          if scope.type == 'method' or scope:has_parent('method') then
            _continue_0 = true
            break
          end
        end
        for _index_0 = 1, #nodes do
          local node = nodes[_index_0]
          append(inspections, {
            msg = "accessing global - `" .. tostring(name) .. "`",
            pos = node.pos or scope.pos
          })
        end
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  for name, nodes in pairs(scope.shadowing_decls) do
    if not (evaluator.allow_shadowing(name)) then
      for _index_0 = 1, #nodes do
        local node = nodes[_index_0]
        append(inspections, {
          msg = "shadowing outer variable - `" .. tostring(name) .. "`",
          pos = node.pos or scope.pos
        })
      end
    end
  end
  local _list_0 = scope.scopes
  for _index_0 = 1, #_list_0 do
    local sub_scope = _list_0[_index_0]
    report_on_scope(sub_scope, evaluator, inspections)
  end
  return inspections
end
local format_inspections
format_inspections = function(inspections)
  local chunks = { }
  for _index_0 = 1, #inspections do
    local inspection = inspections[_index_0]
    local chunk = "line " .. tostring(inspection.line) .. ": " .. tostring(inspection.msg) .. "\n"
    chunk = chunk .. (string.rep('=', #chunk - 1) .. '\n')
    chunk = chunk .. "> " .. tostring(inspection.code) .. "\n"
    chunks[#chunks + 1] = chunk
  end
  return table.concat(chunks, '\n')
end
local report
report = function(scope, code, opts)
  if opts == nil then
    opts = { }
  end
  local inspections = { }
  local evaluator = config.evaluator(opts)
  report_on_scope(scope, evaluator, inspections)
  for _index_0 = 1, #inspections do
    local inspection = inspections[_index_0]
    local line = pos_to_line(code, inspection.pos)
    inspection.line = line
    inspection.code = get_line(code, line)
  end
  table.sort(inspections, function(a, b)
    return a.line < b.line
  end)
  return inspections
end
local lint
lint = function(code, opts)
  if opts == nil then
    opts = { }
  end
  local tree, err = parse.string(code)
  if not (tree) then
    return nil, err
  end
  if opts.print_tree then
    require('moon').p(tree)
  end
  local scope = Scope(tree)
  walk(tree, scope, 1)
  return report(scope, code, opts)
end
local lint_file
lint_file = function(file, opts)
  if opts == nil then
    opts = { }
  end
  local fh = assert(io.open(file, 'r'))
  local code = fh:read('*a')
  fh:close()
  local config_file = opts.lint_config or config.config_for(file)
  opts = config_file and config.load_config_from(config_file, file) or { }
  opts.file = file
  return lint(code, opts)
end
return {
  lint = lint,
  lint_file = lint_file,
  format_inspections = format_inspections,
  config = config
}
