# Environment
- HyerVisor: Esxi 7.0.2, 17867351
- OS: Ubuntu 22.04.3 LTS
- K8S: KubeSphere v3.3.2, 1 Master and 3 Worker nodes, k8s version v1.23.10
- Database : EDB Postgresfor Kubernetes, operator version 1.22.1 / quay.io/enterprisedb/postgresql:16.0
- Storage: Virtual NVME disk formed with SSD disk + iomesh v5.3.0-rc13
- Openshift 4.12.31
- ODF 4.12.7-rhodf
- Portworx 3.1


# Infra Setup

## ESXi
2 hosts with local attached SSD disk

ESXi01
 - CPU: 64 @ 2.1GHz
 - Memory: 383 GB

ESXi02
 - CPU: 64 @ 2.1GHz
 - Memory: 256 GB

## K8S
NAME       STATUS   ROLES                  AGE    VERSION
master01   Ready    control-plane,master   129d   v1.23.10
worker01   Ready    worker                 129d   v1.23.10
worker02   Ready    worker                 129d   v1.23.10
worker03   Ready    worker                 129d   v1.23.10

Worker node Spec:
CPU: 8 vcpu
Memory: 16 GB
Storage: 100 GB for storage pool steup


# Benchmarking
Perform ten million write transaction for 3 times using the pgbench tools.

### Cluster
 - Make sure the psql node distrubute accross different ESXi node
 - Perform psql failover during the last test

### Single Node
 - Make sure the benchmarking happen on each ESXi nodes

## PortWorx
### Testing Part1 - PSQL 1 primary / 1 standby
This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
### Setup
```
apiVersion: postgresql.k8s.enterprisedb.io/v1
kind: Cluster
metadata:
  name: psql
spec:
  instances: 2

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
          storage: 30Gi
      storageClassName: "sroage-class"
      volumeMode: Filesystem

kubectl get cluster.postgresql.k8s.enterprisedb.io
NAME   AGE   INSTANCES   READY   STATUS                     PRIMARY
psql   39m   2           2       Cluster in healthy state   psql-1

Instances status
Name    Database Size  Current LSN  Replication role  Status  QoS         Manager Version  Node
----    -------------  -----------  ----------------  ------  ---         ---------------  ----
psql-1  15 GB          3/5000000    Primary           OK      BestEffort  1.21.0           worker02
psql-2  15 GB          3/5000000    Standby (async)   OK      BestEffort  1.21.0           worker03


kubectl get pvc
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
psql-1   Bound    pvc-714c3dc4-0d24-4605-bfde-e299930e0d6f   30Gi       RWO            px-rep1-sc     40m
psql-2   Bound    pvc-d93048e9-cc21-4cb7-b3a0-8ca292d74bcb   30Gi       RWO            px-rep1-sc     39m


```
Time taken:
| 1st (Mins) |  2nd (Mins) |  3rd (Mins) |
|------------|-------------|-------------|
|6.6         |6.4          |6            |



## Testing Part2 - OCP off, iomesh + PSQL 1 primary / 2 standby
This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Time taken: 22.4 minutes
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

## Testing Part3 - OCP off, iomesh + PSQL single node 
![image](https://github.com/paul6668/test/assets/105109093/de3d6398-d03b-442e-b8e9-42741b971866)

This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Time taken: 9 minutes
![image](https://github.com/paul6668/test/assets/105109093/55e797f5-3eac-4bbd-8c4d-ec5333c1a696)

- db01
![image](https://github.com/paul6668/test/assets/105109093/8b959e1f-7cf9-42da-9247-1fbf6d7165cf)

![image](https://github.com/paul6668/test/assets/105109093/3190f94e-c94a-43b4-922b-4f90080b4b66)
![image](https://github.com/paul6668/test/assets/105109093/3e9212ac-dcc0-4837-b30e-21200ce4300f)
![image](https://github.com/paul6668/test/assets/105109093/f9185f5f-95ef-49b8-93d5-86010cde511e)

## Testing Part4 - OCP off, local disk + PSQL 1 primary / 2 standby
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
Time taken: 9.2 mintues
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


## Testing Part5 - OCP off, local disk + PSQL single node

This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Time taken: 5 minutes

![image](https://github.com/paul6668/test/assets/105109093/27085129-97bc-49ee-8942-b0d529c8569c)

- db01
![image](https://github.com/paul6668/test/assets/105109093/e9b708dc-c94a-41be-91f2-c42e20ffac0f)

![image](https://github.com/paul6668/test/assets/105109093/00471503-d4a8-4c6e-b286-728bca73f2d5)
![image](https://github.com/paul6668/test/assets/105109093/3b7e342f-325f-4423-a3d9-bdb531d6e74f)
![image](https://github.com/paul6668/test/assets/105109093/e92e16f7-4d75-4ead-8421-b73ba0cdc8d5)

## Testing Part6 -  OCP,  + ODF + PSQL 1 primary / 2 standby

This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Time taken: 17.8 minutes
![image](https://github.com/paul6668/test/assets/105109093/ea8643bc-ca40-4c04-99af-dc209935dc48)

- db01
![image](https://github.com/paul6668/test/assets/105109093/38aa49b4-50f5-459e-870d-9c267b88c76c)
![image](https://github.com/paul6668/test/assets/105109093/88bfb1f7-6cca-45dc-95d5-f41b780a5fe7)
![image](https://github.com/paul6668/test/assets/105109093/e03e8ada-4aa7-459c-bdbd-fcbaec4ed60e)

- db02
![image](https://github.com/paul6668/test/assets/105109093/92afe9d7-2d81-4d84-a21a-0684d5c9aa66)
![image](https://github.com/paul6668/test/assets/105109093/106dc054-bb1d-4641-8cb6-90359f3907e1)
![image](https://github.com/paul6668/test/assets/105109093/c3d53320-9255-43bd-9047-c82aff797a27)

- db03
![image](https://github.com/paul6668/test/assets/105109093/261441a2-e7f9-4a0b-94c5-8172cf9bba5b)
![image](https://github.com/paul6668/test/assets/105109093/6bfc6e45-469b-4152-971d-b493d66a2c7a)
![image](https://github.com/paul6668/test/assets/105109093/f8b14914-5c6e-4f01-8eae-b2da4bb02d49)

- ODF

![image](https://github.com/paul6668/test/assets/105109093/983a97bf-5a3d-415b-81b8-8f231c2fe86a)

![image](https://github.com/paul6668/test/assets/105109093/dac542fe-0b65-443a-a70d-0e5bb42b2c82)

## Testing Part6 -  OCP,  + ODF + PSQL single node

This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

```
Time taken: 15.5 minutes
- db01
![image](https://github.com/paul6668/test/assets/105109093/2db4f838-0940-4dd0-98a7-fdeabce5f082)
![image](https://github.com/paul6668/test/assets/105109093/201055a7-73fc-4365-9d47-0947d25dbcb6)
![image](https://github.com/paul6668/test/assets/105109093/03648319-b276-4b2a-8e1a-98f611505110)

- ODF
  
![image](https://github.com/paul6668/test/assets/105109093/1fce5f96-c2d4-4d77-82ab-b264b5335b13)

## Testing Part7 -  OCP off + Portworx + PSQL 1 primary / 2 standby

This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubesphere.io/allow-clone: "true"
    storageclass.kubesphere.io/allow-snapshot: "true"
  creationTimestamp: "2024-03-15T02:13:12Z"
  name: px-rep1-sc
  resourceVersion: "11124261"
  uid: 095956d4-7fa9-4c74-a9d0-35b4660006c3
parameters:
  io_profile: db
  priority_io: high
  repl: "1"
provisioner: pxd.portworx.com
reclaimPolicy: Delete
volumeBindingMode: Immediate

```
Time taken: 6.3 minutes

## Testing Part8 -  OCP off + Portworx + PSQL single node

This example creates a job called pgbench-init that initializes for pgbench OLTP-like purposes the app database in a Cluster named cluster-example, using a scale factor of 1000:
```
kubectl cnp pgbench \
  --job-name pgbench-init \
  cluster-example \
  -- --initialize --scale 1000

allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubesphere.io/allow-clone: "true"
    storageclass.kubesphere.io/allow-snapshot: "true"
  creationTimestamp: "2024-03-15T02:13:12Z"
  name: px-rep1-sc
  resourceVersion: "11124261"
  uid: 095956d4-7fa9-4c74-a9d0-35b4660006c3
parameters:
  io_profile: db
  priority_io: high
  repl: "1"
provisioner: pxd.portworx.com
reclaimPolicy: Delete
volumeBindingMode: Immediate

```
Time taken: 5.9 minutes

# Summary
Since the testing environment dont't have 10G backbone network and enterprise NVME SSD disk, the test intended to do the proof of concept.
It is not recommend run the psql cluster on top of iomesh, due to the mininal "replicaFactor" can only either 2 or 3 for the iomesh storage class, when you sart a psql cluster with one primay and 2 standy nodes, the data will be synchronous to the stanby nodes on database level, while each node have it own PVC with 2 replica, data write on each PVC also synchronous to it's replica, at such scenario, huge I/O will be generated and over load the storage. 
Compare with iomesh, portworx and ODF, portworx accept 1 replica factor while the iomesh is 2 or 3 and ODF default is 3 

| Test Scenario                                          | 1st (Mins) |  2nd (Mins) |  3rd (Mins) |
|-------------------------------------------------------|-------------------|---------|---------|
| OCP running + iomesh + PSQL 1 primary / 2 standby     | 28                |          |        |
| OCP off + iomesh + PSQL 1 primary / 2 standby | 22.4                      |          |        |
| OCP off + local disk + PSQL 1 primary / 2 standby | 9.2                   |          |        |
| OCP off + iomesh + PSQL single node               | 9                     |          |        |
| OCP off + local disk + PSQL single node           | 5                     |          |        |
| OCP + ODF + PSQL 1 primary / 2 standby          | 17.8                    |          |        |
| OCP + ODF + PSQL single node          | 15.5                              |          |        |
| OCP off + Portworx + PSQL 1 primary / 2 standby     | 6.3                 |8.8       |    7.2 |
| OCP off + Portworx + PSQL single node          | 5.9                      | 6.2      |   5.9  |

https://docs.iomesh.com/volume-operations/create-storageclass
![image](https://github.com/paul6668/test/assets/105109093/b8f87bb1-16cf-434e-aed4-a7420c982fbd)
