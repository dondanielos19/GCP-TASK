variable "project_id" {
  description = "my-task-1234" #your project id
  type        = string
}
variable "region" {
  description = "Region"
  type        = string
  default     = "europe-central2" #your gcp region
}
variable "domain" {
  description = "Your Domain"
  type        = string
  default     = "sikalafa.pl" #your domain name
}
