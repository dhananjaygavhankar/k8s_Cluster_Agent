locals {
  docker_context_path = var.docker_context_path != "" ? abspath(var.docker_context_path) : "${path.module}/image"
  agent_image_source_hash = sha256(join("", [
    filesha256("${local.docker_context_path}/Dockerfile"),
    filesha256("${local.docker_context_path}/configure_agent.py"),
  ]))
  pod_image_reference = "${module.aks.acr_login_server}/${var.pod_image}"
}

resource "terraform_data" "acr_image" {
  input = local.pod_image_reference

  triggers_replace = [
    local.agent_image_source_hash,
    filesha256("${path.module}/build-push.ps1"),
    local.docker_context_path,
    local.pod_image_reference,
    module.aks.acr_id,
  ]

  depends_on = [module.aks]

  provisioner "local-exec" {
    command = "& '${path.module}/build-push.ps1' -RegistryName '${var.acr_name}' -RegistryLoginServer '${module.aks.acr_login_server}' -ImageName '${var.pod_image}' -DockerContextPath '${local.docker_context_path}'"

    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
  }
}