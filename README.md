# Terraform Address Change Helper

Handy for the times when you've changed the name of a module or moved it to another folder
and Terraform tells you something like:

> Plan: 47 to add, 0 to change, 47 to destroy.

Given two arguments, `current address prefix` and `new address prefix`, this tool will simply
call `terraform state mv <current address> <new address>` once for every pair of resources
involved in the plan where the "current" one is being created, the "new" one is being destroyed,
and the addresses of both have matching strings following their respective prefixes.

### Examples

If a module `bob` is renamed to `david`:

    $ tf_addr_chg.sh module.bob module.david

If a module `abc` is moved from the root module to module `def`:

    $ tf_addr_chg.sh module.abc module.def.module.abc
