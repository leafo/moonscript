import with_dev from require "spec.helpers"

describe 'lint', ->
  local lint

  with_dev ->
    lint = require "moonscript.lint.init"

  clean = (code) ->
    initial_indent = code\match '^([ \t]*)%S'
    code = code\gsub '\n\n', "\n#{initial_indent}\n"
    lines = [l\gsub("^#{initial_indent}", '') for l in code\gmatch('[^\n]+')]
    code = table.concat lines, '\n'
    code = code\match '^%s*(.-)%s*$'
    code .. '\n'

  do_lint = (code, opts) ->
    inspections = assert lint.lint code, opts
    res = {}

    for i in *inspections
      {:line, :msg} = i
      res[#res + 1] = :line, :msg

    res

  describe 'unused variables', ->
    it 'detects unused variables', ->
      code = 'used = 2\nfoo = 2\nused'
      res = do_lint code, {}
      assert.same {
        {line: 2, msg: 'declared but unused - `foo`'}
      }, res

    it 'handles multiple assignments', ->
      code = 'a, b = 1, 2\na'
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'declared but unused - `b`'}
      }, res

    it 'does not report variable used in a different scope', ->
      code = clean [[
        a = 1
        ->
          a + 1
      ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'detects function scoped, unused variables', ->
      code = clean [[
        x = -> a = 1
        x = -> a = 1
        x
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'declared but unused - `a`'}
        {line: 2, msg: 'declared but unused - `a`'}
      }, res

    it 'detects control flow scoped, unused variables', ->
      code = clean [[
        if _G.foo
          x = 2
        elseif _G.zed
          x = 1
        else
          x = 1
        unless _G.bar
          x = 3
        x
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 2, msg: 'declared but unused - `x`'}
        {line: 4, msg: 'declared but unused - `x`'}
        {line: 6, msg: 'declared but unused - `x`'}
        {line: 8, msg: 'declared but unused - `x`'}
        {line: 9, msg: 'accessing global - `x`'}
      }, res

    it 'detects unused variables in with statements', ->
      code = clean [[
        with _G.foo
          x = 1
        with _G.bar
          x = 2
        x = 3
        x
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 2, msg: 'declared but unused - `x`'}
        {line: 4, msg: 'declared but unused - `x`'}
      }, res

    it 'detects while scoped unused variables', ->
      code = clean [[
        while true
          x = 1
          break
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 2, msg: 'declared but unused - `x`'}
      }, res

    it 'accounts for implicit returns', ->
      code = clean [[
        x = 1
        ->
          y = 1
          y
        x
       ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'handles inline with variable assignment statements', ->
      code = clean [[
        with foo = 2
          foo += 3
      ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'detects unused function parameters if requested', ->
      code = '(foo) -> 2'
      res = do_lint code, report_params: true
      assert.same {
        {line: 1, msg: 'declared but unused - `foo`'}
      }, res

    it 'detects usages in parameter lists', ->
      code = clean [[
      x = 1
      (v = x)->
        v
      ]]
      res = do_lint code
      assert.same {}, res

    it 'does not complain about varargs', ->
      code = clean [[
        (...) ->
          ...
       ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'respects a given whitelist_params', ->
      code = clean '(x) -> 1'
      res = do_lint code, { whitelist_params: {'x'} }
      assert.same {}, res

    it 'respects a given whitelist_loop_variables', ->
      code = clean 'for x in *{1,2}\n  _G.other = 1'
      res = do_lint code, { whitelist_loop_variables: {'x'} }
      assert.same {}, res

    it 'does not complain about @variables in methods', ->
      code = clean [[
        class Foo
          new: (@bar) =>
          other: (@zed) =>

        Foo
      ]]
      res = do_lint code
      assert.same {}, res

    it 'detects unused class definitions', ->
      code = clean [[
        class Foo extends _G.Bar
          new: =>

        {}
        ]]
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'declared but unused - `Foo`'}
      }, res

    it 'detects implicit returns of class definitions', ->
      code = clean [[
        class Foo
          new: =>
        ]]
      res = do_lint code, {}
      assert.same {
      }, res

    it 'detects dotted assignment references', ->
      code = clean [[
        (arg) ->
          arg.foo = .zed
      ]]
      res = do_lint code
      assert.same {}, res

    it 'handles local declarations', ->
      code = clean [[
        local x, y
        ->
          x = 2
          y = 1
          y + x
      ]]
      res = do_lint code
      assert.same {}, res

    it 'handles export declarations', ->
      code = clean [[
        export foo
        ->
          foo = 2
        y = 1
        export zed = ->
          y + 2
      ]]
      res = do_lint code
      assert.same {}, res

    it 'handles wildcard export declarations', ->
      code = clean [[
        x = 1
        export *
        y = 2
      ]]
      res = do_lint code
      assert.same {
        {line: 1, msg: 'declared but unused - `x`'}
      }, res

    it 'detects indexing references', ->
      code = clean [[
        (foo) ->
          _G[foo] = 2
      ]]
      res = do_lint code
      assert.same {}, res

    it 'detects unused imports', ->
      code = clean [[
        import foo from _G.bar
        import \func from _G.thing
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'declared but unused - `foo`'}
        {line: 2, msg: 'declared but unused - `func`'}
      }, res

    it 'detects usages in import source lists', ->
      code = clean [[
        ffi = require 'ffi'
        import C from ffi
        C
      ]]
      res = do_lint code
      assert.same {}, res

    it 'detects unused destructured variables', ->
      code = clean [[
      {:foo} = _G.bar
      {bar: other} = _G.zed
      {frob} = {1,2}
      {numbers: {first}} = _G.frob
      {props: {color: my_col}} = _G.what
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'declared but unused - `foo`'}
        {line: 2, msg: 'declared but unused - `other`'}
        {line: 3, msg: 'declared but unused - `frob`'}
        {line: 4, msg: 'declared but unused - `first`'}
        {line: 5, msg: 'declared but unused - `my_col`'}
      }, res

      code = '{:foo, :bar} = _G.bar'
      res = do_lint code, {}
      assert.equal 2, #res

    it 'detects unused variables in ordinary loops', ->
      code = clean [[
        for foo = 1,10
          _G.other!

        for foo = 1,10
          _G.other foo
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'declared but unused - `foo`'}
      }, res

    it 'detects unused variables in for each loops', ->
      code = clean [[
        for foo in *{2, 3}
          _G.other!

      ]]
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'declared but unused - `foo`'}
      }, res

    it 'detects unused destructured variables in for each loops', ->
      code = clean [[
        for {foo} in *{2, 3}
          _G.other!

        for {:bar} in *{2, 3}
          _G.other!

        for {bar: zed} in *{2, 3}
          _G.other!
      ]]
      res = do_lint code
      assert.same {
        {line: 1, msg: 'declared but unused - `foo`'}
        {line: 4, msg: 'declared but unused - `bar`'}
        {line: 7, msg: 'declared but unused - `zed`'}
      }, res

    it 'does not warn for used vars in decorated statements', ->
      code = clean [[
        _G[a] = nil for a in *_G.list
        ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'detects variable usages correctly in comprehensions', ->
      code = clean [[
        [x * 2 for x in *_G.foo]
        ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'detects variable usages correctly in for comprehensions', ->
      code = clean [[
      [tostring(l) for l = 1, 100]
      ]]
      res = do_lint code
      assert.same {}, res

    it 'detects variable usages correctly in comprehensions 2', ->
      code = clean [[
        [name for name in pairs _G.foo]
      ]]
      res = do_lint code
      assert.same {}, res

    it 'detects variable usages correctly in hash comprehensions', ->
      code = clean [[
        {k, _G.foo[k] for k in *{1,2}}
      ]]
      res = do_lint code
      assert.same {}, res

  describe 'undeclared access', ->
    it 'detected undeclared accesses', ->
      code = 'foo!'
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'accessing global - `foo`'}
      }, res

    it 'detected undeclared accesses for chained expressions', ->
      code = 'foo.x'
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'accessing global - `foo`'}
      }, res

    it 'reports each undeclared usage separately', ->
      code = clean [[
        x 1
        x 2
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'accessing global - `x`'}
        {line: 2, msg: 'accessing global - `x`'}
      }, res

    it 'includes built-ins in the global whitelist', ->
      code = clean [[
        x = tostring(_G.foo)
        y = table.concat {}, '\n'
        x + y
      ]]
      res = do_lint code
      assert.same {}, res

    it 'allows access to self and super in methods', ->
      code = clean [[
        class Foo
          meth: =>
            self.bar!
            super!
      ]]
      res = do_lint code
      assert.same {}, res

    it 'allows access to self in methods and sub scopes thereof', ->
      code = clean [[
        class Foo
          meth: =>
            if true
              self.bar!
      ]]
      res = do_lint code
      assert.same {}, res

    it 'disallows access to self in functions', ->
      code = clean [[
        ->
          self.bar!
      ]]
      res = do_lint code
      assert.same {
        {line: 2, msg: 'accessing global - `self`'}
      }, res

    it 'handles variabled assigned with statement modifiers correctly', ->
      code = clean [[
        x = _G.foo if true
        x
      ]]
      res = do_lint code
      assert.same {}, res

      code = clean [[
        x = _G.foo unless false
        x
      ]]
      res = do_lint code
      assert.same {}, res

    it 'handles variabled assigned with statement modifiers correctly', ->
      code = clean [[
        x or= _G.foo
        y or= _G.bar\zed!
        x + y
      ]]
      res = do_lint code
      assert.same {}, res

    it 'handles variables assigned with destructuring correctly', ->
      code = clean [[
        {foo, bar} = _G.zed
        foo + bar
      ]]
      res = do_lint code
      assert.same {}, res

    it 'detects class parent references', ->
      code = clean [[
        import Base from _G
        class I extends Base
      ]]
      res = do_lint code
      assert.same {}, res

    it 'handles non-prefixed member access', ->
      code = clean [[
        class Foo
          bar: (@x = 'zed') =>
            x
      ]]
      res = do_lint code
      assert.same {}, res

    it 'handles loop modified statements', ->
      code = clean [[
        _G.foo[t] = true for t in pairs {}
        t! for t in *{}
        _G.foo += i for i = 1, 10
      ]]
      res = do_lint code
      assert.same {}, res

    it 'handles "with" statement assignments', ->
      code = clean [[
        with x = 2
          .y + 2
      ]]
      res = do_lint code
      assert.same {}, res

    it 'handles while scoped unused variables', ->
      code = clean [[
        while true
          x = 1
          if x
            break
        x
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 5, msg: 'accessing global - `x`'}
      }, res

  describe 'format_inspections(inspections)', ->
    it 'returns a string representation of inspections', ->
      code = clean [[
      {:foo} = _G.bar
      {bar: other} = _G.zed
      ]]
      inspections = assert lint.lint code, {}
      assert.same clean([[
        line 1: declared but unused - `foo`
        ===================================
        > {:foo} = _G.bar

        line 2: declared but unused - `other`
        =====================================
        > {bar: other} = _G.zed
      ]]), lint.format_inspections(inspections)

  describe 'shadowing warnings', ->
    it 'detects shadowing outer variables in for each', ->
      code = clean [[
        x = 2
        for x in *{1,2}
          _G.other x
        x
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 2, msg: 'shadowing outer variable - `x`'}
      }, res

    it 'detects shadowing using local statements', ->
      code = clean [[
        x = 2
        ->
          local x
          x = 2
          x * 2
        x
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 3, msg: 'shadowing outer variable - `x`'}
      }, res

    it 'understand lexical scoping', ->
      code = clean [[
        for x in *{1,2}
          _G.other x
        x = 2 -- defined after previous declaration
        x
      ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'rvalue declaration values generally does not shadow lvalues', ->
      code = clean [[
        x = { -- assignment lvalue target
          f: (x) -> -- this is part of the rvalue
        }
        x
      ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'implicitly local lvalue declarations are recognized (i.e. fndefs)', ->
      code = clean [[
        f = (x) -> x + f(x + 1)
        f
      ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'does not complain about foreach comprehension vars shadowing target', ->
      code = clean [[
        for x in *[x for x in *_G.foo when x != 'bar' ]
          x!
      ]]
      res = do_lint code, {}
      assert.same {}, res

    it 'handles scope shadowing and unused variables correctly', ->
      code = clean [[
        (a) ->
          [ { a, b } for a, b in pairs {} ]
      ]]
      res = do_lint code, report_params: true
      assert.same {
        {line: 1, msg: 'declared but unused - `a`'},
        {line: 2, msg: 'shadowing outer variable - `a`'}
      }, res

    it 'handles shadowing with decorated statements correctly', ->
      code = clean [[
        x = 1
        (arg) -> x! for x in *arg
      ]]
      res = do_lint code, {}
      assert.same {
        {line: 1, msg: 'declared but unused - `x`'},
        {line: 2, msg: 'shadowing outer variable - `x`'}
      }, res

  describe 'lint.config', ->
    lfs = require 'lfs'
    dir = require 'pl.dir'
    local config

    with_dev ->
      config = require "moonscript.lint.config"

    write_file = (path, contents) ->
      f = assert io.open(path, 'wb')
      f\write contents
      assert f\close!

    describe 'config_for(file)', ->
      local base_dir

      before_each ->
        base_dir = os.tmpname!
        assert(os.remove(base_dir)) if lfs.attributes(base_dir)
        assert(lfs.mkdir(base_dir))

      after_each -> dir.rmtree(base_dir)

      it 'returns the first available lint_config by moving up the path', ->
        assert(lfs.mkdir("#{base_dir}/sub"))
        ex_file = "#{base_dir}/sub/file.moon"

        in_dir_cfg = "#{base_dir}/sub/lint_config.lua"
        write_file in_dir_cfg, '{}'
        assert.equal in_dir_cfg, config.config_for(ex_file)
        os.remove(in_dir_cfg)

        parent_dir_cfg = "#{base_dir}/lint_config.lua"
        write_file parent_dir_cfg, '{}'
        assert.equal parent_dir_cfg, config.config_for(ex_file)

      it 'supports and prefers moonscript config files if available', ->
        assert(lfs.mkdir("#{base_dir}/sub"))
        ex_file = "#{base_dir}/sub/file.moon"

        lua_cfg = "#{base_dir}/lint_config.lua"
        moon_cfg = "#{base_dir}/lint_config.moon"
        write_file lua_cfg, '{}'
        write_file moon_cfg, '{}'

        assert.equal moon_cfg, config.config_for(ex_file)
        os.remove(moon_cfg)
        assert.equal lua_cfg, config.config_for(ex_file)

    describe 'load_config_from(config, file)', ->
      sorted = (t) ->
        table.sort t
        t

      it 'loads the relevant settings for <file> from <config>', ->
        cfg = {
          report_loop_variables: true
          report_params: false

          whitelist_globals: {
            ['.']: { 'foo' },
            test: { 'bar' }
            other: { 'zed' }
          }
          whitelist_loop_variables: {
            test: {'k'}
          }
          whitelist_params: {
            ['.']: {'pipe'}
          }
          whitelist_unused: {
            ['.']: {'general'}
          }
          whitelist_shadowing: {
            ['.']: {'table'}
          }
        }
        loaded = config.load_config_from(cfg, '/test/foo.moon')
        assert.same {
          'bar',
          'foo'
        }, sorted loaded.whitelist_globals

        assert.same { 'k' }, loaded.whitelist_loop_variables
        assert.same { 'pipe' }, loaded.whitelist_params
        assert.same { 'general' }, loaded.whitelist_unused
        assert.same { 'table' }, loaded.whitelist_shadowing
        assert.is_true loaded.report_loop_variables
        assert.is_false loaded.report_params

      it 'loads <config> as a file when passed as a string', ->
        path = os.tmpname!
        write_file path, [[
        return {
          whitelist_globals = {
            test = {'bar'}
          }
        }
        ]]
        assert.same {
          whitelist_globals: { 'bar' }
        }, config.load_config_from(path, '/test/foo.moon')

    describe 'evaluator(config)', ->
      evaluator = config.evaluator

      describe 'allow_unused_param(p)', ->
        it 'generally returns true', ->
          assert.is_true evaluator({}).allow_unused_param('foo')

        it 'returns false if config.report_params is true', ->
          assert.is_false evaluator(report_params: true).allow_unused_param('foo')

        it 'returns true if config.whitelist_params contains <p>', ->
          whitelist_params = {'foo'}
          assert.is_true evaluator(:whitelist_params).allow_unused_param('foo')

        it 'supports patterns', ->
          whitelist_params = {'^a+'}
          assert.is_true evaluator(:whitelist_params).allow_unused_param('aardwark')

        it 'defaults to white listings params starting with an underscore', ->
          for sym in *{'_', '_foo', '_bar2'}
            assert.is_true evaluator().allow_unused_param(sym)

      describe 'allow_unused_loop_variable(p)', ->
        it 'generally returns false', ->
          assert.is_false evaluator({}).allow_unused_loop_variable('foo')

        it 'returns true if config.report_loop_variables is false', ->
          assert.is_true evaluator(report_loop_variables: false).allow_unused_loop_variable('foo')

        it 'returns true if config.whitelist_loop_variables contains <p>', ->
          whitelist_loop_variables = {'foo'}
          assert.is_true evaluator(:whitelist_loop_variables).allow_unused_loop_variable('foo')

        it 'supports patterns', ->
          whitelist_loop_variables = {'^a+'}
          assert.is_true evaluator(:whitelist_loop_variables).allow_unused_loop_variable('aardwark')

        it 'defaults to white listing params starting with an underscore', ->
          for sym in *{'_', '_foo', '_bar2'}
            assert.is_true evaluator().allow_unused_loop_variable(sym)

        it 'defaults to white listing the common names "i" and "j"', ->
          for sym in *{'i', 'j'}
            assert.is_true evaluator().allow_unused_loop_variable(sym)

      describe 'allow_global_access(p)', ->
        it 'generally returns false', ->
          assert.is_false evaluator({}).allow_global_access('foo')

        it 'returns true if config.whitelist_globals contains <p>', ->
          whitelist_globals = {'foo'}
          assert.is_true evaluator(:whitelist_globals).allow_global_access('foo')

        it 'supports patterns', ->
          whitelist_globals = {'^a+'}
          assert.is_true evaluator(:whitelist_globals).allow_global_access('aardwark')

        it 'always includes whitelisting of builtins', ->
          for sym in *{'require', '_G', 'tostring'}
            assert.is_true evaluator().allow_global_access(sym)

          whitelist_globals = {'foo'}
          assert.is_true evaluator(:whitelist_globals).allow_global_access('table')
