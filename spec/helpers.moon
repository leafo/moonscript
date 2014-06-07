
-- remove front indentation from a multiline string, making it suitable to be
-- parsed
unindent = (str) ->
  indent = str\match "^%s+"
  return str unless indent
  (str\gsub("\n#{indent}", "\n")\gsub "%s+$", "")

{ :unindent }
