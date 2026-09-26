resource "azuredevops_agent_pool" "shared" {
  name           = var.ado_pool
  auto_provision = true
  pool_type      = "automation"
  auto_update    = true
}

resource "terraform_data" "aks_pod" {
  input = {
    resource_group_name = var.name_rg
    cluster_name        = var.cluster_name
    pod_name            = var.pod_name
    pod_namespace       = var.pod_namespace
  }

  triggers_replace = [
    local.pod_image_reference,
    local.agent_image_source_hash,
    var.pod_name,
    var.pod_namespace,
    var.pod_container_name,
    var.ado_url,
    var.ado_pool,
    var.ado_agent,
    jsonencode(var.pod_labels),
    var.pod_cpu_request,
    var.pod_memory_request,
    var.pod_cpu_limit,
    var.pod_memory_limit,
  ]

  depends_on = [terraform_data.acr_image, azuredevops_agent_pool.shared]

  provisioner "local-exec" {
    command = "& '${path.module}/deploy-pod.ps1' -Action Apply -ResourceGroupName '${var.name_rg}' -ClusterName '${var.cluster_name}' -PodName '${var.pod_name}' -PodNamespace '${var.pod_namespace}' -ContainerName '${var.pod_container_name}' -Image '${local.pod_image_reference}' -AdoUrl '${var.ado_url}' -AdoPool '${var.ado_pool}' -AdoAgent '${var.ado_agent}' -LabelsJson '${jsonencode(var.pod_labels)}' -CpuRequest '${var.pod_cpu_request}' -MemoryRequest '${var.pod_memory_request}' -CpuLimit '${var.pod_cpu_limit}' -MemoryLimit '${var.pod_memory_limit}'"

    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

    environment = {
      for name, value in { ADO_PAT = var.ado_pat } : name => value
      if value != ""
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "& '${path.module}/deploy-pod.ps1' -Action Delete -ResourceGroupName '${self.input.resource_group_name}' -ClusterName '${self.input.cluster_name}' -PodName '${self.input.pod_name}' -PodNamespace '${self.input.pod_namespace}'"

    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
  }
}

output "pod_name" {
  value = var.pod_name
}