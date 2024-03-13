# Environment
- HyerVisor: Esxi 7.0.2, 17867351
- OS: Ubuntu 22.04.3 LTS
- K8S: KubeSphere v3.3.2, 1 Master and 3 Worker nodes, k8s version v1.23.10
- Database : EDB Postgresfor Kubernetes, operator version 1.22.1 / quay.io/enterprisedb/postgresql:16.0
- Storage: Virtual NVME disk formed with SSD disk + iomesh v5.3.0-rc13

# Setup
- Create Storage Class for Postgres, Replica factor at least 2
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
- Create Postgres Cluster with 1 primary and 2 replica nodes 
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
```
kubectl get cluster.postgresql.k8s.enterprisedb.io
NAME        AGE     INSTANCES   READY   STATUS                     PRIMARY
psql-db01   6h11m   3           3       Cluster in healthy state   psql-db01-1

![image](https://github.com/paul6668/test/assets/105109093/cd940b65-0ec6-430e-987f-d7a08738bbbf)


kubectl get pvc
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
iomesh-mysql-pvc   Bound    pvc-4cf15dcd-e7ae-4b15-a380-91ff717dc3e6   10Gi       RWO            iomesh-mysql-sc   15d
psql-db01-1        Bound    pvc-86583f77-357a-4bea-aacc-7f78f338c1cc   20Gi       RWO            iomesh-psql-sc    6h12m
psql-db01-2        Bound    pvc-90d5d668-e7a6-4ff9-b88c-3b7675837340   20Gi       RWO            iomesh-psql-sc    6h10m
psql-db01-3        Bound    pvc-3dab210b-4cb1-4591-b36b-8742752b20b9   20Gi       RWO            iomesh-psql-sc    6h8m

```
# Benchmarking - Part1 with OCP runing  
#Testing
This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
![image](https://github.com/paul6668/test/assets/105109093/03540107-2851-499f-9f65-506e779c4f66)

![image](https://github.com/paul6668/test/assets/105109093/0743dff8-51c3-4e44-8df2-8e1aed2ea8f1)



## Resources Usage
- db01
![image](https://github.com/paul6668/test/assets/105109093/acfd1669-80e6-4076-a034-a9dea2746b0a)
- db02
![image](https://github.com/paul6668/test/assets/105109093/6b45feb1-1a00-44e8-aff4-7a210f82c389)
- db03
![image](https://github.com/paul6668/test/assets/105109093/ae0d3028-ad8f-420f-ad61-5b578a73b779)

![image](https://github.com/paul6668/test/assets/105109093/96f254aa-bf51-43c8-9eae-e39faad1274c)

![image](https://github.com/paul6668/test/assets/105109093/ffe23ad5-c68f-486f-aab5-0376545af042)

![image](https://github.com/paul6668/test/assets/105109093/669083d5-682e-4182-baa3-772de35b7ba7)



