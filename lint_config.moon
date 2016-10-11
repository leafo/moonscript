{
  whitelist_globals: {
    '.': {
    },

    'parse.moon': {
      '[A-Z][a-z]+'
    },

    spec: {
      'after_each',
      'async',
      'before_each',
      'describe',
      'it',
      'settimeout',
      'setup',
      'spy',
      'teardown',

      'hello'
    }
  }

  whitelist_unused: {
    'spec/import_spec': { 'hello', 'foo' }
  }
}
