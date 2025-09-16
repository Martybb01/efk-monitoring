# Simple outputs for EFK infrastructure

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

output "access_commands" {
  description = "Commands to access services"
  value = {
    kibana        = "kubectl port-forward -n logging svc/kibana 5601:5601"
    elasticsearch = "kubectl port-forward -n logging svc/elasticsearch 9200:9200"
    flask_app     = "kubectl port-forward -n application svc/flask-app 5000:5000"
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    🎉 EFK Stack deployed successfully!
    
    📋 Access services:
    • Kibana: kubectl port-forward -n logging svc/kibana 5601:5601
      Then open: http://localhost:5601
    
    • Flask App: kubectl port-forward -n application svc/flask-app 5000:5000
      Then open: http://localhost:5000
    
    • Elasticsearch: kubectl port-forward -n logging svc/elasticsearch 9200:9200
      Then open: http://localhost:9200
    
    🔍 Monitor logs:
    • kubectl logs -f -l app=flask-app -n application
    • kubectl logs -f -l app=fluent-bit -n logging
    
    📊 Check status:
    • kubectl get pods -A
    • kubectl get svc -A
    
    🧹 Cleanup:
    • terraform destroy
  EOT
}