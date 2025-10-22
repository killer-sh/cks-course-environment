# from https://www.conftest.dev
package main

denylist = [
  "ubuntu"
]

deny contains msg if {
  input[i].Cmd == "from"
  val := input[i].Value
  contains(val[i], denylist[_])

  msg = sprintf("unallowed image found %s", [val])
}
