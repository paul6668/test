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
 - Make sure the benchmarking performed on each ESXi nodes

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
  affinity:
    enablePodAntiAffinity: true #default value
    topologyKey: kubernetes.io/hostname #defaul value
    podAntiAffinityType: required
  storage:
    pvcTemplate:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 30Gi
      storageClassName: px-rep1-sc
      volumeMode: Filesystem


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


kubectl get cluster.postgresql.k8s.enterprisedb.io
NAME   AGE   INSTANCES   READY   STATUS                     PRIMARY
psql   39m   2           2       Cluster in healthy state   psql-1

Instances status
Name    Database Size  Current LSN  Replication role  Status  QoS         Manager Version  Node
----    -------------  -----------  ----------------  ------  ---         ---------------  ----
psql-1  15 GB          3/5000000    Primary           OK      BestEffort  1.21.0           worker02
psql-2  15 GB          3/5000000    Standby (async)   OK      BestEffort  1.21.0           worker03


kubectl get pvc
NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
psql-1   Bound    pvc-714c3dc4-0d24-4605-bfde-e299930e0d6f   30Gi       RWO            px-rep1-sc     40m
psql-2   Bound    pvc-d93048e9-cc21-4cb7-b3a0-8ca292d74bcb   30Gi       RWO            px-rep1-sc     39m


```
Time taken:
| PSQL Primary Node | 1st (Mins) |  2nd (Mins) |  3rd (Mins) |
|-------------------|------------|-------------|-------------|
|worker02           |6.6         |6.4          |             |
|worker03           |            |             |6            |


### Testing Part2 - PSQL single node
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
  instances: 1

  # Example of rolling update strategy:
  # - unsupervised: automated update of the primary once all
  #                 replicas have been upgraded (default)
  # - supervised: requires manual supervision to perform
  #               the switchover of the primary
  primaryUpdateStrategy: unsupervised

  # Require 1Gi of space
  affinity:
    enablePodAntiAffinity: true #default value
    topologyKey: kubernetes.io/hostname #defaul value
    podAntiAffinityType: required
  storage:
    pvcTemplate:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 30Gi
      storageClassName: px-rep1-sc
      volumeMode: Filesystem


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


kubectl get cluster.postgresql.k8s.enterprisedb.io
NAME   AGE   INSTANCES   READY   STATUS                     PRIMARY
psql   31s   1           1       Cluster in healthy state   psql-1

Instances status
Name    Database Size  Current LSN  Replication role  Status  QoS         Manager Version  Node
----    -------------  -----------  ----------------  ------  ---         ---------------  ----
psql-1  29 MB          0/200F6E0    Primary           OK      BestEffort  1.21.0           worker03


kubectl get pvc
NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
psql-1   Bound    pvc-48539f34-dba2-4706-af70-f4534e80df96   30Gi       RWO            px-rep1-sc     76s

failover
Name    Database Size  Current LSN  Replication role  Status  QoS         Manager Version  Node
----    -------------  -----------  ----------------  ------  ---         ---------------  ----
psql-1  15 GB          6/200E298    Primary           OK      BestEffort  1.21.0           worker02


```
Time taken:
| PSQL Primary Node | 1st (Mins) |  2nd (Mins) |  3rd (Mins) |
|-------------------|------------|-------------|-------------|
|worker03           |6.3         |6.2          |             |
|worker02           |            |             |11.5         |




## IOMesh
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
  affinity:
    enablePodAntiAffinity: true #default value
    topologyKey: kubernetes.io/hostname #defaul value
    podAntiAffinityType: required
  storage:
    pvcTemplate:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 30Gi
      storageClassName: iomesh-psql-sc
      volumeMode: Filesystem


kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: iomesh-psql-sc
provisioner: com.iomesh.csi-driver # The driver name in `iomesh.yaml`.
reclaimPolicy: Retain
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: "ext4"
  replicaFactor: "2"
  thinProvision: "true"
volumeBindingMode: Immediate



kubectl get cluster.postgresql.k8s.enterprisedb.io
NAME   AGE   INSTANCES   READY   STATUS                     PRIMARY
psql   105s   2           2       Cluster in healthy state   psql-1

Instances status
Name    Database Size  Current LSN  Replication role  Status  QoS         Manager Version  Node
----    -------------  -----------  ----------------  ------  ---         ---------------  ----
psql-1  29 MB          0/4000060    Primary           OK      BestEffort  1.21.0           worker03
psql-2  29 MB          0/4000060    Standby (async)   OK      BestEffort  1.21.0           worker01



kubectl get pvc
NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
iomesh-psql-sc                    com.iomesh.csi-driver               Retain          Immediate              true                   54s



```
Time taken:
| PSQL Primary Node | 1st (Mins) |  2nd (Mins) |  3rd (Mins) |
|-------------------|------------|-------------|-------------|
|worker03           |11.3        |13           |             |
|worker01           |            |             |13.4         |

### Testing Part2 - PSQL single node
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
  instances: 1

  # Example of rolling update strategy:
  # - unsupervised: automated update of the primary once all
  #                 replicas have been upgraded (default)
  # - supervised: requires manual supervision to perform
  #               the switchover of the primary
  primaryUpdateStrategy: unsupervised

  # Require 1Gi of space
  affinity:
    enablePodAntiAffinity: true #default value
    topologyKey: kubernetes.io/hostname #defaul value
    podAntiAffinityType: required
  storage:
    pvcTemplate:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 30Gi
      storageClassName: iomesh-psql-sc
      volumeMode: Filesystem

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: iomesh-psql-sc
provisioner: com.iomesh.csi-driver # The driver name in `iomesh.yaml`.
reclaimPolicy: Retain
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: "ext4"
  replicaFactor: "2"
  thinProvision: "true"
volumeBindingMode: Immediate



kubectl get cluster.postgresql.k8s.enterprisedb.io
NAME   AGE   INSTANCES   READY   STATUS                     PRIMARY
psql   86s   1           1       Cluster in healthy state   psql-1

Instances status
Name    Database Size  Current LSN  Replication role  Status  QoS         Manager Version  Node
----    -------------  -----------  ----------------  ------  ---         ---------------  ----
psql-1  29 MB          0/205E120    Primary           OK      BestEffort  1.21.0           worker03


kubectl get pvc
NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
psql-1   Bound    pvc-79af95bf-41d4-46ea-8e10-9630721492d7   30Gi       RWO            iomesh-psql-sc   2m7s

failover
Name    Database Size  Current LSN  Replication role  Status  QoS         Manager Version  Node
----    -------------  -----------  ----------------  ------  ---         ---------------  ----
psql-1  15 GB          6/200E298    Primary           OK      BestEffort  1.21.0           worker01


```
Time taken:
| PSQL Primary Node | 1st (Mins) |  2nd (Mins) |  3rd (Mins) |
|-------------------|------------|-------------|-------------|
|worker03           |8.8         |8.8          |             |
|worker01           |            |             |10           |