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
- Create Postgres Cluster with 1 primary and 2 standby nodes 
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
![image](https://github.com/paul6668/test/assets/105109093/cd940b65-0ec6-430e-987f-d7a08738bbbf)

```
kubectl get cluster.postgresql.k8s.enterprisedb.io
NAME        AGE     INSTANCES   READY   STATUS                     PRIMARY
psql-db01   6h11m   3           3       Cluster in healthy state   psql-db01-1


kubectl get pvc
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
iomesh-mysql-pvc   Bound    pvc-4cf15dcd-e7ae-4b15-a380-91ff717dc3e6   10Gi       RWO            iomesh-mysql-sc   15d
psql-db01-1        Bound    pvc-86583f77-357a-4bea-aacc-7f78f338c1cc   20Gi       RWO            iomesh-psql-sc    6h12m
psql-db01-2        Bound    pvc-90d5d668-e7a6-4ff9-b88c-3b7675837340   20Gi       RWO            iomesh-psql-sc    6h10m
psql-db01-3        Bound    pvc-3dab210b-4cb1-4591-b36b-8742752b20b9   20Gi       RWO            iomesh-psql-sc    6h8m

```
# Benchmarking 
## Testing Part1 - With OCP runing, iomesh + PSQL 1 primary / 2 standby
This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Taken 28 mintues
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

## Testing Part2 - Without OCP runing, iomesh + PSQL 1 primary / 2 standby
This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Taken 22.4 minutes
![image](https://github.com/paul6668/test/assets/105109093/0e7068a9-1a6e-4e6f-b4c7-5a7d15d34ba7)

- db01
![image](https://github.com/paul6668/test/assets/105109093/e8636367-5c6f-439e-8d65-99393c12128d)

- db02
![image](https://github.com/paul6668/test/assets/105109093/29dfb944-0b40-4d50-a3de-0e75e6ef7277)

- db03
![image](https://github.com/paul6668/test/assets/105109093/113cd6a1-e862-4740-9f8f-8b9bd06dce74)

![image](https://github.com/paul6668/test/assets/105109093/890e1a57-dc5c-41af-9a19-42be1514aeef)

![image](https://github.com/paul6668/test/assets/105109093/4f5b5d59-12a0-409e-8e7f-02984275d743)

![image](https://github.com/paul6668/test/assets/105109093/c13415c4-7e1b-4738-924e-ddbd486146d8)

## Testing Part3 - Without OCP runing, iomesh + PSQL single node 
![image](https://github.com/paul6668/test/assets/105109093/de3d6398-d03b-442e-b8e9-42741b971866)

This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Taken 9 minutes
![image](https://github.com/paul6668/test/assets/105109093/55e797f5-3eac-4bbd-8c4d-ec5333c1a696)

- db01
![image](https://github.com/paul6668/test/assets/105109093/8b959e1f-7cf9-42da-9247-1fbf6d7165cf)

![image](https://github.com/paul6668/test/assets/105109093/3190f94e-c94a-43b4-922b-4f90080b4b66)
![image](https://github.com/paul6668/test/assets/105109093/3e9212ac-dcc0-4837-b30e-21200ce4300f)
![image](https://github.com/paul6668/test/assets/105109093/f9185f5f-95ef-49b8-93d5-86010cde511e)

## Testing Part4 - Without OCP, local disk + PSQL 1 primary / 2 standby
![image](https://github.com/paul6668/test/assets/105109093/d20eb1b9-fbde-488b-beee-fefca5d76d5b)
![image](https://github.com/paul6668/test/assets/105109093/f6a9be26-588d-4117-87a3-19323678cfe2)
![image](https://github.com/paul6668/test/assets/105109093/e9c7a8ef-913c-416a-8bdc-fa28213006b1)

This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Taken 9.2 mintues
![image](https://github.com/paul6668/test/assets/105109093/8d911626-9c6f-4d6c-852b-ea5a4f21f08c)

- db01
![image](https://github.com/paul6668/test/assets/105109093/2629a8af-a1ac-4167-8067-18b758f69e55)
- db02
![image](https://github.com/paul6668/test/assets/105109093/43a2a014-1e56-4e92-ac25-c5ba5a58022f)
- db03
![image](https://github.com/paul6668/test/assets/105109093/f1b026f7-0434-4082-8c9b-6d689b392980)

![image](https://github.com/paul6668/test/assets/105109093/d235f92e-82f6-41a7-8503-754f2195638e)
![image](https://github.com/paul6668/test/assets/105109093/af204c54-2f7c-4b01-bc9b-71ad77f94da5)
![image](https://github.com/paul6668/test/assets/105109093/1310d21d-6b70-4ddf-8818-02d58dac75e7)


## Testing Part5 - Without OCP, local disk + PSQL single node

This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Taken 5 minutes

![image](https://github.com/paul6668/test/assets/105109093/27085129-97bc-49ee-8942-b0d529c8569c)

- db01
![image](https://github.com/paul6668/test/assets/105109093/e9b708dc-c94a-41be-91f2-c42e20ffac0f)

![image](https://github.com/paul6668/test/assets/105109093/00471503-d4a8-4c6e-b286-728bca73f2d5)
![image](https://github.com/paul6668/test/assets/105109093/3b7e342f-325f-4423-a3d9-bdb531d6e74f)
![image](https://github.com/paul6668/test/assets/105109093/e92e16f7-4d75-4ead-8421-b73ba0cdc8d5)
