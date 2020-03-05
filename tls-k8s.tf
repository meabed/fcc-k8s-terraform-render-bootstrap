locals {
  # Kubernetes TLS assets map
  kubernetes_tls = {
    "tls/k8s/ca.crt"              = tls_self_signed_cert.kube-ca.cert_pem,
    "tls/k8s/ca.key"              = tls_private_key.kube-ca.private_key_pem,
    "tls/k8s/apiserver.crt"       = tls_locally_signed_cert.apiserver.cert_pem,
    "tls/k8s/apiserver.key"       = tls_private_key.apiserver.private_key_pem,
    "tls/k8s/service-account.pub" = tls_private_key.service-account.public_key_pem
    "tls/k8s/service-account.key" = tls_private_key.service-account.private_key_pem
  }
}

# Kubernetes CA (tls/{ca.crt,ca.key})

resource "tls_private_key" "kube-ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "kube-ca" {
  key_algorithm   = tls_private_key.kube-ca.algorithm
  private_key_pem = tls_private_key.kube-ca.private_key_pem

  subject {
    common_name  = "kubernetes-ca"
    organization = "typhoon"
  }

  is_ca_certificate     = true
  validity_period_hours = 24000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "local_file" "kube-ca-key" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.kube-ca.private_key_pem
  filename = "${var.asset_dir}/tls/ca.key"
}

resource "local_file" "kube-ca-crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_self_signed_cert.kube-ca.cert_pem
  filename = "${var.asset_dir}/tls/ca.crt"
}

# Kubernetes API Server (tls/{apiserver.key,apiserver.crt})

resource "tls_private_key" "apiserver" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "apiserver" {
  key_algorithm   = tls_private_key.apiserver.algorithm
  private_key_pem = tls_private_key.apiserver.private_key_pem

  subject {
    common_name  = "kube-apiserver"
    organization = "system:masters"
  }

  dns_names = flatten([
    var.api_servers,
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.${var.cluster_domain_suffix}",
  ])

  ip_addresses = [
    cidrhost(var.service_cidr, 1),
  ]
}

resource "tls_locally_signed_cert" "apiserver" {
  cert_request_pem = tls_cert_request.apiserver.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.kube-ca.key_algorithm
  ca_private_key_pem = tls_private_key.kube-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.kube-ca.cert_pem

  validity_period_hours = 24000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "local_file" "apiserver-key" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.apiserver.private_key_pem
  filename = "${var.asset_dir}/tls/apiserver.key"
}

resource "local_file" "apiserver-crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_locally_signed_cert.apiserver.cert_pem
  filename = "${var.asset_dir}/tls/apiserver.crt"
}

# Kubernetes Admin (tls/{admin.key,admin.crt})

resource "tls_private_key" "admin" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "admin" {
  key_algorithm   = tls_private_key.admin.algorithm
  private_key_pem = tls_private_key.admin.private_key_pem

  subject {
    common_name  = "kubernetes-admin"
    organization = "system:masters"
  }
}

resource "tls_locally_signed_cert" "admin" {
  cert_request_pem = tls_cert_request.admin.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.kube-ca.key_algorithm
  ca_private_key_pem = tls_private_key.kube-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.kube-ca.cert_pem

  validity_period_hours = 24000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "local_file" "admin-key" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.admin.private_key_pem
  filename = "${var.asset_dir}/tls/admin.key"
}

resource "local_file" "admin-crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_locally_signed_cert.admin.cert_pem
  filename = "${var.asset_dir}/tls/admin.crt"
}

# Kubernete's Service Account (tls/{service-account.key,service-account.pub})

resource "tls_private_key" "service-account" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "service-account-key" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.service-account.private_key_pem
  filename = "${var.asset_dir}/tls/service-account.key"
}

resource "local_file" "service-account-crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.service-account.public_key_pem
  filename = "${var.asset_dir}/tls/service-account.pub"
}

# Kubelet

resource "tls_private_key" "kubelet" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "kubelet" {
  key_algorithm   = tls_private_key.kubelet.algorithm
  private_key_pem = tls_private_key.kubelet.private_key_pem

  subject {
    common_name  = "kubelet"
    organization = "system:nodes"
  }
}

resource "tls_locally_signed_cert" "kubelet" {
  cert_request_pem = tls_cert_request.kubelet.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.kube-ca.key_algorithm
  ca_private_key_pem = tls_private_key.kube-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.kube-ca.cert_pem

  validity_period_hours = 24000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "local_file" "kubelet-key" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.kubelet.private_key_pem
  filename = "${var.asset_dir}/tls/kubelet.key"
}

resource "local_file" "kubelet-crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_locally_signed_cert.kubelet.cert_pem
  filename = "${var.asset_dir}/tls/kubelet.crt"
}

