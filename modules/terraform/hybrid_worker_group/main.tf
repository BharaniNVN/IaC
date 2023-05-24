resource "null_resource" "this" {
  for_each = var.name == null ? [] : var.name
  triggers = {
    url  = format("https://management.azure.com%s/hybridRunbookWorkerGroups/%s?api-version=2021-06-22", var.automation_account_id, each.key)
    body = var.credential_name == null ? format("{\\\"name\\\":\\\"%s\\\"}", each.key) : format("{\\\"name\\\":\\\"%s\\\",\\\"credential\\\":{\\\"name\\\":\\\"%s\\\"}}", each.key, var.credential_name)
  }

  provisioner "local-exec" {
    command = "az rest --method put --url ${self.triggers.url} --body ${self.triggers.body}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "az rest --method delete --url ${self.triggers.url}"
  }
}
