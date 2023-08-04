terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

variable zip_file {
  type = string
}

variable "user_hash" {
  type = string
}

variable "secret_id" {
  type = string
}

variable "secret_version_id" {
  type = string
}

variable "sa_account_id" {
  type = string  
}

variable "project_name" {
  type = string
}


provider "yandex" {
}


resource "yandex_function" "tf-function" {
  name               = "github-telegram-webhook-${var.project_name}"
  description        = "Webhook to recieve GitHub Events (project ${var.project_name})"
  user_hash          = var.user_hash
  runtime            = "python311"
  entrypoint         = "main.ya_handler"
  memory             = "128"
  execution_timeout  = "10"
  service_account_id = var.sa_account_id
  environment = {
    TEMPLATES_PATH = "./templates"
  }
  secrets {
    id = var.secret_id
    version_id = var.secret_version_id
    key = "BOT_TOKEN"
    environment_variable = "BOT_TOKEN"
  }
  secrets {
    id = var.secret_id
    version_id = var.secret_version_id
    key = "CHAT_ID"
    environment_variable = "CHAT_ID"    
  }
  secrets {
    id = var.secret_id
    version_id = var.secret_version_id
    key = "WEBHOOK_SECRET"
    environment_variable = "WEBHOOK_SECRET"    
  }
  secrets {
    id = var.secret_id
    version_id = var.secret_version_id
    key = "THREAD_ID"
    environment_variable = "THREAD_ID"    
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