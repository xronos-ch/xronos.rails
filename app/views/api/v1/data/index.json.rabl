# trick to override root object without changing site-wide config:
# https://github.com/nesquena/rabl/issues/576
collection @data, object_root: :measurement

extends "data/show"
