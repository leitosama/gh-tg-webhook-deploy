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

variable "bot_token" {
  type = string
}

variable "chat_id" {
  type = string
}

variable "webhook_secret" {
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

resource "yandex_kms_symmetric_key" "tf_key" {
  name              = "gh-tg-webhook-kms-key-${var.project_name}"
  description       = "KMS Key for Webhook"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" // equal to 1 year
}

resource "yandex_lockbox_secret" "tf_secret" {
  name = "gh-tg-webhook-secret-${var.project_name}"
  kms_key_id = yandex_kms_symmetric_key.tf_key.kms_key_id
  description = "LockBox secret for gh-tg-webhook (project ${var.project_name})"
}

resource "yandex_lockbox_secret_version" "tf_secret_version" {
  secret_id = yandex_lockbox_secret.tf_secret.id
  entries {
    key = "BOT_TOKEN"
    text_value = var.bot_token
  }
  entries {
    key = "CHAT_ID"
    text_value = var.chat_id  
  }
  entries {
    key = "WEBHOOK_SECRET"
    text_value = var.webhook_secret 
  }
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
    id = yandex_lockbox_secret.tf_secret.id
    version_id = yandex_lockbox_secret_version.tf_secret_version.id
    key = "BOT_TOKEN"
    environment_variable = "BOT_TOKEN"
  }
  secrets {
    id = yandex_lockbox_secret.tf_secret.id
    version_id = yandex_lockbox_secret_version.tf_secret_version.id
    key = "CHAT_ID"
    environment_variable = "CHAT_ID"    
  }
  secrets {
    id = yandex_lockbox_secret.tf_secret.id
    version_id = yandex_lockbox_secret_version.tf_secret_version.id
    key = "WEBHOOK_SECRET"
    environment_variable = "WEBHOOK_SECRET"    
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