## template: jinja
#cloud-config

# Aggressively update
package_update: true
package_upgrade: true
package_reboot_if_required: true

# Install needed packages
packages:
  - rsync
  - curl

runcmd:
  - curl https://dl.min.io/server/minio/release/linux-amd64/minio -o /usr/local/bin/minio
  - chmod +x /usr/local/bin/minio
  - systemctl enable minio.service

fqdn: {{ds.meta_data.hostname}}.${dns_suffix}

disk_setup:

fs_setup:

mounts:
 - [ vdb, null ]

write_files:
  - path: /etc/default/minio
    content: |
      # Volume to be used for MinIO server.
      MINIO_VOLUMES="${minio_volume_path}"
      # Access Key of the server.
      MINIO_ACCESS_KEY=${minio_access_key}
      # Secret key of the server.
      MINIO_SECRET_KEY=${minio_secret_key}

  - path: /etc/systemd/system/minio.service
    content: |
      [Unit]
      Description=MinIO
      Documentation=https://docs.min.io
      Wants=network-online.target
      After=network-online.target
      AssertFileIsExecutable=/usr/local/bin/minio

      [Service]
      WorkingDirectory=/usr/local/

      User=minio
      Group=minio

      EnvironmentFile=/etc/default/minio
      ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"

      ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

      # Let systemd restart this service always
      Restart=always

      # Specifies the maximum file descriptor number that can be opened by this process
      LimitNOFILE=65536

      # Disable timeout logic and wait until process is stopped
      TimeoutStopSec=infinity
      SendSIGKILL=no

      [Install]
      WantedBy=multi-user.target

groups:
  - name: minio

users:
  - default
  - name: minio
    shell: /sbin/nologin
    groups: minio
    primary_group: minio
    system: true
  - name: johnt
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_import_id:
        - gh:john-terrell
