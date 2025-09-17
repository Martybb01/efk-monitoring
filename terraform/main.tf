terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "minikube" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Starting Minikube cluster..."
      minikube start --profile=${var.cluster_name} --nodes=${var.nodes} --memory=${var.memory} --cpus=${var.cpus}
      
      echo "Waiting for cluster to be ready..."
      sleep 30
      
      echo "Verifying cluster status..."
      kubectl cluster-info --context=${var.cluster_name}
      
      echo "Minikube cluster is ready!"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "minikube delete --profile=${self.triggers.cluster_name}"
  }

  triggers = {
    cluster_name = var.cluster_name
    nodes        = var.nodes
    memory       = var.memory
    cpus         = var.cpus
  }
}

resource "null_resource" "kubectl_config" {
  depends_on = [null_resource.minikube]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Configuring kubectl context..."
      kubectl config use-context ${var.cluster_name}
      
      echo "Waiting for API server to be ready..."
      sleep 15
      
      echo "Testing API server connection..."
      kubectl get nodes --context=${var.cluster_name}
      
      echo "kubectl context configured successfully!"
    EOT
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "application" {
  depends_on = [null_resource.kubectl_config]
  metadata {
    name = "application"
  }
}

resource "kubernetes_namespace" "logging" {
  depends_on = [null_resource.kubectl_config]
  metadata {
    name = "logging"
  }
}

resource "kubernetes_service_account" "fluent_bit" {
  depends_on = [kubernetes_namespace.logging]
  metadata {
    name      = "fluent-bit"
    namespace = "logging"
  }
}

resource "kubernetes_cluster_role" "fluent_bit" {
  depends_on = [ kubernetes_namespace.logging ]
  metadata {
    name = "fluent-bit"
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "fluent_bit" {
  depends_on = [ kubernetes_namespace.logging ]
  metadata {
    name = "fluent-bit"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "fluent-bit"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "fluent-bit"
    namespace = "logging"
  }
}

resource "null_resource" "build_flask_image" {
  depends_on = [null_resource.minikube]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Building Flask app Docker image..."
      
      # Set Docker environment and build in one command
      eval $(minikube docker-env --profile=${var.cluster_name}) && \
      cd ../app/flask-app && \
      docker build -t flask-demo-app:latest . && \
      cd ../../terraform
      
      echo "Flask app image built successfully"
    EOT
  }

  triggers = {
    dockerfile_hash = filemd5("../app/flask-app/Dockerfile")
    app_hash        = filemd5("../app/flask-app/app.py")
  }
}

resource "helm_release" "elasticsearch" {
  depends_on = [kubernetes_namespace.logging, kubernetes_service_account.fluent_bit]

  name             = "elasticsearch"
  namespace        = "logging"
  chart            = "../helm-charts/elasticsearch"
  create_namespace = true

  values = [
    yamlencode({
      storage = {
        size = "5Gi"
      }
    })
  ]

  timeout = 600
}

resource "helm_release" "kibana" {
  depends_on = [helm_release.elasticsearch]

  name             = "kibana"
  namespace        = "logging"
  chart            = "../helm-charts/kibana"
  create_namespace = true

  timeout = 600
}

resource "helm_release" "fluent_bit" {
  depends_on = [helm_release.elasticsearch]

  name             = "fluent-bit"
  namespace        = "logging"
  chart            = "../helm-charts/fluent-bit"
  create_namespace = true

  timeout = 600
}

resource "helm_release" "flask_app" {
  depends_on = [null_resource.build_flask_image, kubernetes_namespace.application]

  name             = "flask-app"
  namespace        = "application"
  chart            = "../helm-charts/flask-app"
  create_namespace = true

  values = [
    yamlencode({
      image = {
        repository = "flask-demo-app"
        tag        = "latest"
        pullPolicy = "IfNotPresent"
      }
    })
  ]

  timeout = 600
}
