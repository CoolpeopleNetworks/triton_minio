locals {
    minio_data_path = "/mnt/minio"
}

resource "random_string" "access_key" {
    length           = 32
    special          = false
}

resource "random_string" "secret_key" {
    length           = 32
    special          = false
}

data "triton_image" "os" {
    name = "debian-9-cloudinit"
    version = "1.0.0"
}

resource "triton_machine" "minio" {
    count = var.server_replicas
    name = "minio-${count.index}"
    package = var.server_package

    image = data.triton_image.os.id

    cns {
        services = ["minio"]
    }

    networks = [
        data.triton_network.public.id,
        data.triton_network.private.id
    ]
    
    cloud_config = templatefile("${path.module}/cloud-config.yml.tpl", {
        dns_suffix = var.dns_suffix,
        server_replicas = var.server_replicas
        minio_volume_path = "/mnt/"
        minio_access_key = ""
        minio_secret_key = ""
    })
}

# resource "smartcluster_machine" "minio" {
#     for_each = var.module_config.nodes
#     node_name = each.key

#     alias          = "minio"
#     brand          = "lx"
#     kernel_version = "3.16.0"
#     cpu_cap        = each.value.cpu_cap

#     customer_metadata = {
#         "root_authorized_keys" = file("authorized_keys.txt")
#         "user-script"          = "/usr/sbin/mdata-get root_authorized_keys > ~root/.ssh/authorized_keys"
#     }

#     image_uuid          = data.smartcluster_image.minio[each.key].id
#     maintain_resolvers  = true
#     max_physical_memory = each.value.ram

#     nics {
#         nic_tag                   = var.config.network.nic_tag
#         ips                       = ["${cidrhost(local.cidr, each.value.host_number)}/${var.config.network.netbits}"]
#         gateways                  = var.config.network.gateways
#         interface                 = "net0"
#         vlan_id                   = var.config.network.vlan_id
#     }

#     quota = each.value.quota

#     resolvers = var.config.network.resolvers

#     connection {
#         host = each.value.ip
#     }

#     provisioner "remote-exec" {
#         inline = [
#             "addgroup minio",
#             "adduser minio --ingroup minio --no-create-home --disabled-password --gecos 'Minio User'",

#             "mkdir -p ${local.minio_data_path}",
#             "chown minio ${local.minio_data_path}",
#             "chgrp minio ${local.minio_data_path}",

#             (length(var.module_config.nodes) > 1 ? "mkdir -p ${local.minio_data_path}/data1" : "echo"),
#             (length(var.module_config.nodes) > 1 ? "mkdir -p ${local.minio_data_path}/data2" : "echo"),
#             (length(var.module_config.nodes) > 1 ? "mkdir -p ${local.minio_data_path}/data3" : "echo"),
#             (length(var.module_config.nodes) > 1 ? "mkdir -p ${local.minio_data_path}/data4" : "echo"),
#         ]
#     }

#     provisioner "file" {
#         content = templatefile("${path.module}/templates/default.tmpl", {
#             volume_path = (length(var.module_config.nodes) > 1 ? "http://minio-node{1...${length(var.module_config.nodes)}}.coolpeoplenetworks.com${local.minio_data_path}/data{1...4}" : "${local.minio_data_path}")
#             access_key = random_string.access_key.result
#             secret_key = random_string.secret_key.result
#         })
#         destination = "/etc/default/minio"
#     }

#     provisioner "remote-exec" {
#         inline = [
#             "apt-get -y update",
#             "apt-get -y install rsync",
#             "cd /tmp ; wget https://dl.min.io/server/minio/release/linux-amd64/minio",
#             "cd /tmp ; chmod +x minio",
#             "mv /tmp/minio /usr/local/bin",
#         ]
#     }

#     provisioner "file" {
#         source = "${path.module}/minio.service"
#         destination = "/etc/systemd/system/minio.service"
#     }

#     provisioner "remote-exec" {
#         inline = [
#             "cd /etc/systemd/system ; systemctl enable minio.service",
#             "cd /etc/systemd/system ; systemctl start minio.service",
#         ]
#     }
# }
