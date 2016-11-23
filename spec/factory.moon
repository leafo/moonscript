
-- ast factory

ref = (name="val") ->
  {"ref", name}

str = (contents="dogzone", delim='"') ->
  {"string", delim, contents}

{
  :ref
  :str
}
