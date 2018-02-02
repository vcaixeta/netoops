#when calling the module and passing values, store them on the variables defined here.
variable "vpc_cidr" {
  default = ""
  description = "the vpc cdir to be used"
}
variable "vpc_name" {
  default = ""
  description = "the vpc cdir to be used"
}

variable "subnet-public-a" {
  default = ""
  description = "the vpc cdir to be used"
}
variable "subnet-public-b" {
  default = ""
  description = "the vpc cdir to be used"
}
variable "subnet-private-a" {
  default = ""
  description = "the vpc cdir to be used"
}
variable "subnet-private-b" {
  default = ""
  description = "the vpc cdir to be used"
}

variable "region" {
  default = ""
  description = "the vpc cdir to be used"
}

