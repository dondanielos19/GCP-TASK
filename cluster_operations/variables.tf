variable "domain" {
  type        = string
  description = "Domain name for the DNS setup."
  default     = "sikalafa.pl"

}


variable "git" {
  description = "Address of git repository"
  type        = string
  default     = "https://github.com/dondanielos19/task-gcp-argoCD.git"
}

variable "gitpaht" {
  description = "path git repository"
  type        = string
  default     = "hello-world-flask/manifests"
}
