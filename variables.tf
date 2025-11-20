variable "project_id" {
  description = "ID проекта в панеле my-selectel"
  type        = string
}
variable "domain_name" {
  description = "ID аккаунта в панеле my-selectel"
  type        = string
}
variable "username" {
  description = "Имя пользователя с доступом к проекту"
  type        = string
}
variable "password" {
  description = "Пароль пользователя с доступом к проекту"
  type        = string
}
variable "auth_region" {
  description = "Регион авторищации"
  type        = string
}
variable "auth_url" {
  description = "URL для авторизации"
  type        = string
}
