terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

variable "webhook_secret" {
  type = string
}

variable "chat_id" {
  type = string
}

variable "bot_token" {
  type = string
}

variable zip_file {
  type = string
}

variable "user_hash" {
  type = string
}

provider "yandex" {
}

resource "yandex_function" "tf-function" {
  name               = "github-telegram-webhook"
  description        = "Webhook to recieve GitHub Events"
  user_hash          = var.user_hash
  runtime            = "python311"
  entrypoint         = "main.ya_handler"
  memory             = "128"
  execution_timeout  = "10"
  environment = {
    WEBHOOK_SECRET = var.webhook_secret
    CHAT_ID = var.chat_id
    BOT_TOKEN = var.bot_token
    TEMPLATES_PATH = "./templates"
  }
  content {
    zip_filename = var.zip_file
  }
}

resource "yandex_function_iam_binding" "function-iam" {
  function_id = "${yandex_function.tf-function.id}"
  role        = "functions.functionInvoker"
  members = [
    "system:allUsers",
  ]
}

output "yandex_function_tf-function" {
    value = "${yandex_function.tf-function.id}"
}