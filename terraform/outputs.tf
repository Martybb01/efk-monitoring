output "cluster_name" {
  description = "Name of the Minikube cluster"
  value       = var.cluster_name
}

output "namespaces" {
  description = "Created namespaces"
  value = {
    application = kubernetes_namespace.application.metadata[0].name
    logging     = kubernetes_namespace.logging.metadata[0].name
  }
}

output "helm_releases" {
  description = "Deployed Helm releases"
  value = {
    elasticsearch = {
      name      = helm_release.elasticsearch.name
      namespace = helm_release.elasticsearch.namespace
      status    = helm_release.elasticsearch.status
    }
    kibana = {
      name      = helm_release.kibana.name
      namespace = helm_release.kibana.namespace
      status    = helm_release.kibana.status
    }
    fluent_bit = {
      name      = helm_release.fluent_bit.name
      namespace = helm_release.fluent_bit.namespace
      status    = helm_release.fluent_bit.status
    }
    flask_app = {
      name      = helm_release.flask_app.name
      namespace = helm_release.flask_app.namespace
      status    = helm_release.flask_app.status
    }
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    EFK Stack deployed successfully!
    
    Monitor logs:
    • kubectl logs -f -l app=flask-app -n application
    • kubectl logs -f -l app=fluent-bit -n logging
  EOT
}