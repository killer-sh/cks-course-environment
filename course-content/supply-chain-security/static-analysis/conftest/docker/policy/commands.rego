# from https://www.conftest.dev

package commands

denylist = [
  "apk",
  "apt",
  "pip",
  "curl",
  "wget",
]

deny contains msg if {
  input[i].Cmd == "run"
  val := input[i].Value
  contains(val[_], denylist[_])

  msg = sprintf("unallowed commands found %s", [val])
}
