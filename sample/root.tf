
terraform {
  backend "local" {}
}

module "some_module_2" {
  source = "./some-module"
  some_var = "what"
}

resource "null_resource" "aaa" {}
