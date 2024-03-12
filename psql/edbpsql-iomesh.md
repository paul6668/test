# Artichecture
- OS: Ubuntu 22.04.3 LTS
- K8S: KubeSphere v3.3.2, 1 Master and 3 Worker nodes, k8s version v1.23.10
- Database : EDB Postgresfor Kubernetes, operator version 1.22.1 / quay.io/enterprisedb/postgresql:16.0
- Storage: Virtual NVME disk formed with SSD disk + iomesh v5.3.0-rc13

# Setup
- Create Storage Class for Postgres
```
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubesphere.io/allow-clone: "true"
    storageclass.kubesphere.io/allow-snapshot: "true"
  creationTimestamp: "2024-03-12T03:16:28Z"
  name: iomesh-psql-sc
  resourceVersion: "9597139"
  uid: 950eec29-4eb7-4ff6-925d-be222cd25582
parameters:
  csi.storage.k8s.io/fstype: ext4
  replicaFactor: "2"
  thinProvision: "true"
provisioner: com.iomesh.csi-driver
reclaimPolicy: Retain
volumeBindingMode: Immediate
```
- Create Postgres Cluster
```
apiVersion: postgresql.k8s.enterprisedb.io/v1
kind: Cluster
metadata:
  name: psql-db01
spec:
  instances: 3

  # Example of rolling update strategy:
  # - unsupervised: automated update of the primary once all
  #                 replicas have been upgraded (default)
  # - supervised: requires manual supervision to perform
  #               the switchover of the primary
  primaryUpdateStrategy: unsupervised

  # Require 1Gi of space
  storage:
    pvcTemplate:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
      storageClassName: iomesh-psql-sc
      volumeMode: Filesystem
```
