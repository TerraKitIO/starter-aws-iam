variable "aws_account_id" {
  type = "string"
  description = "Your AWS account ID"
}

variable "aws_region" {
  type = "string"
  description = "Your primary AWS region"
  default = "us-east-1"
}

variable "minimum_password_length" {
  description = "The minimum length of password for accounts."
  default = "8"
}

variable "password_reuse_prevention" {
  description = "Prevent users from re-using previous passwords up to this many."
  default = "2"
}

variable "max_password_age" {
  description = "Maximum age for passwords."
  default = "180"
}
