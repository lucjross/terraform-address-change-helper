variable "some_var" {
  type = string
}

resource "null_resource" "a" {
  triggers = {
    some_var = var.some_var
  }
}

resource "null_resource" "b" {}

resource "null_resource" "c" {}
