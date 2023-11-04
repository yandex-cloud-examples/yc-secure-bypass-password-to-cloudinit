# Creating Lockbox secret

resource "yandex_lockbox_secret" "password_secret" {
  name = var.secret_name
  kms_key_id = yandex_kms_symmetric_key.win-key.id
  labels = {
    "key_id" = "${yandex_kms_symmetric_key.win-key.id}"
    "service_account_id" = "${yandex_iam_service_account.win-sa.id}"
  }
}

# Creating Lockbox secret version
resource "yandex_lockbox_secret_version" "secret_version" {
  secret_id = yandex_lockbox_secret.password_secret.id
  entries {
    key        = "${var.windows_admin}"
    text_value = "${var.win_adm_pass}"
  }
}

# Creating Lockbox secret access binding via local exec because there are no terraform resources for secret access binding
# yc cli is required!
resource "null_resource" "lockbox_secrets_access_binding" {
  provisioner "local-exec" {
  command     = <<-CMD
    yc lockbox secret add-access-binding --id ${yandex_lockbox_secret.password_secret.id} --role lockbox.payloadViewer --service-account-id ${yandex_iam_service_account.win-sa.id}
    CMD
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<-CMD
    yc lockbox secret delete --id ${yandex_lockbox_secret.password_secret.id}
    CMD
  }
  depends_on = [
    yandex_kms_symmetric_key.win-key,
    yandex_iam_service_account.win-sa
  ]
}


