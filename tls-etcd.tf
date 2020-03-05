locals {
  # etcd TLS assets map
  etcd_tls = {
    "tls/etcd/etcd-client-ca.crt" = tls_self_signed_cert.etcd-ca.cert_pem,
    "tls/etcd/etcd-client.crt"    = tls_locally_signed_cert.client.cert_pem,
    "tls/etcd/etcd-client.key"    = tls_private_key.client.private_key_pem
    "tls/etcd/server-ca.crt"      = tls_self_signed_cert.etcd-ca.cert_pem,
    "tls/etcd/server.crt"         = tls_locally_signed_cert.server.cert_pem
    "tls/etcd/server.key"         = tls_private_key.server.private_key_pem
    "tls/etcd/peer-ca.crt"        = tls_self_signed_cert.etcd-ca.cert_pem,
    "tls/etcd/peer.crt"           = tls_locally_signed_cert.peer.cert_pem
    "tls/etcd/peer.key"           = tls_private_key.peer.private_key_pem
  }
}

# etcd CA

resource "tls_private_key" "etcd-ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "etcd-ca" {
  key_algorithm   = tls_private_key.etcd-ca.algorithm
  private_key_pem = tls_private_key.etcd-ca.private_key_pem

  subject {
    common_name  = "etcd-ca"
    organization = "etcd"
  }

  is_ca_certificate     = true
  validity_period_hours = 24000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

# etcd-ca.crt
resource "local_file" "etcd_ca_crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_self_signed_cert.etcd-ca.cert_pem
  filename = "${var.asset_dir}/tls/etcd-ca.crt"
}

# etcd-client-ca.crt
resource "local_file" "etcd_client_ca_crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_self_signed_cert.etcd-ca.cert_pem
  filename = "${var.asset_dir}/tls/etcd-client-ca.crt"
}

# etcd-ca.key
resource "local_file" "etcd_ca_key" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.etcd-ca.private_key_pem
  filename = "${var.asset_dir}/tls/etcd-ca.key"
}

# etcd Client (apiserver to etcd communication)

resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "client" {
  key_algorithm   = tls_private_key.client.algorithm
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name  = "etcd-client"
    organization = "etcd"
  }

  ip_addresses = [
    "127.0.0.1",
  ]

  dns_names = concat(var.etcd_servers, ["localhost"])
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem = tls_cert_request.client.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.etcd-ca.key_algorithm
  ca_private_key_pem = tls_private_key.etcd-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.etcd-ca.cert_pem

  validity_period_hours = 24000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

# etcd-client.crt
resource "local_file" "etcd_client_crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_locally_signed_cert.client.cert_pem
  filename = "${var.asset_dir}/tls/etcd-client.crt"
}

# etcd-client.key
resource "local_file" "etcd_client_key" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.client.private_key_pem
  filename = "${var.asset_dir}/tls/etcd-client.key"
}

# etcd Server

resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "server" {
  key_algorithm   = tls_private_key.server.algorithm
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name  = "etcd-server"
    organization = "etcd"
  }

  ip_addresses = [
    "127.0.0.1",
  ]

  dns_names = concat(var.etcd_servers, ["localhost"])
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem = tls_cert_request.server.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.etcd-ca.key_algorithm
  ca_private_key_pem = tls_private_key.etcd-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.etcd-ca.cert_pem

  validity_period_hours = 24000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

# server-ca.crt
resource "local_file" "etcd_server_ca_crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_self_signed_cert.etcd-ca.cert_pem
  filename = "${var.asset_dir}/tls/etcd/server-ca.crt"
}

# server.crt
resource "local_file" "etcd_server_crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_locally_signed_cert.server.cert_pem
  filename = "${var.asset_dir}/tls/etcd/server.crt"
}

# server.key
resource "local_file" "etcd_server_key" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.server.private_key_pem
  filename = "${var.asset_dir}/tls/etcd/server.key"
}

# etcd Peer

resource "tls_private_key" "peer" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "peer" {
  key_algorithm   = tls_private_key.peer.algorithm
  private_key_pem = tls_private_key.peer.private_key_pem

  subject {
    common_name  = "etcd-peer"
    organization = "etcd"
  }

  dns_names = var.etcd_servers
}

resource "tls_locally_signed_cert" "peer" {
  cert_request_pem = tls_cert_request.peer.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.etcd-ca.key_algorithm
  ca_private_key_pem = tls_private_key.etcd-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.etcd-ca.cert_pem

  validity_period_hours = 24000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

# peer-ca.crt
resource "local_file" "etcd_peer_ca_crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_self_signed_cert.etcd-ca.cert_pem
  filename = "${var.asset_dir}/tls/etcd/peer-ca.crt"
}

# peer.crt
resource "local_file" "etcd_peer_crt" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_locally_signed_cert.peer.cert_pem
  filename = "${var.asset_dir}/tls/etcd/peer.crt"
}

# peer.key
resource "local_file" "etcd_peer_key" {
  count = var.asset_dir == "" ? 0 : 1

  content  = tls_private_key.peer.private_key_pem
  filename = "${var.asset_dir}/tls/etcd/peer.key"
}

