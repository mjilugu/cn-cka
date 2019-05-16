#!/bin/bash -e

#  https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

## Generate the kubernetes data encryption config file containing the
## encryption key:
CONTROLLER_1_PUBLIC_IP=192.168.122.50
CONTROLLER_2_PUBLIC_IP=192.168.122.55
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml << EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

## Copy the file to both controller servers

scp encryption-config.yaml cloud_user@${CONTROLLER_1_PUBLIC_IP}:~/
scp encryption-config.yaml cloud_user@${CONTROLLER_2_PUBLIC_IP}:~/
