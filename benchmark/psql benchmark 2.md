# Environment
- HyerVisor: Esxi 7.0.2, 17867351
- OS: Ubuntu 22.04.3 LTS
- K8S: KubeSphere v3.3.2, 1 Master and 3 Worker nodes, k8s version v1.23.10
- Database : EDB Postgresfor Kubernetes, operator version 1.22.1 / quay.io/enterprisedb/postgresql:16.0, Crunchy Postgres-operator 5.5 with psql 16
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

Transaction rate:
| Test     | Mins       |  TPS        |
|----------|------------|-------------|
| 1st      |6.6         | 252,525.25  |
| 2nd      |6.4         | 260,416.67  |
| 3rd      |6           | 277,777.78  |

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
|worker02           |            |             |6.3          |

Transaction rate:
| Test     | Mins       |  TPS        |
|----------|------------|-------------|
| 1st      |6.3         | 264,550.26  |
| 2nd      |6.2         | 268,817.20  |
| 3rd      |6.3         | 264,550.26  |


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

Transaction rate:
| Test     | Mins       |  TPS        |
|----------|------------|-------------|
| 1st      |11.3        | 147,492.6   |
| 2nd      |13          | 128,205.13  |
| 3rd      |13.4        | 124,378.11  |

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

Transaction rate:
| Test     | Mins       |  TPS        |
|----------|------------|-------------|
| 1st      | 8.8        | 189,393.94  |
| 2nd      | 8.8        | 189,393.93  |
| 3rd      | 10         | 166,666.67  |


# Smmary
## Cluster
| PSQL Primary Node | 1st (Mins) |  2nd (Mins) |  3rd (Mins) |
|-------------------|------------|-------------|-------------|
|PortWorx-----------|------------|-------------|-------------|
|worker02           |6.6         |6.4          |             |
|worker03           |            |             |6            |
|IOMesh-------------|------------|-------------|-------------|
|worker03           |11.3        |13           |             |
|worker01           |            |             |13.4         |

Transaction rate:
| Test     | Mins       |  TPS        |
|----------|------------|-------------|
|PortWorx--|------------|-------------|
| 1st      |6.6         | 252,525.25  |
| 2nd      |6.4         | 260,416.67  |
| 3rd      |6           | 277,777.78  |
|IOMesh----|------------|-------------|
| 1st      |11.3        | 147,492.6   |
| 2nd      |13          | 128,205.13  |
| 3rd      |13.4        | 124,378.11  |

## Single Node
| PSQL Primary Node | 1st (Mins) |  2nd (Mins) |  3rd (Mins) |
|PortWorx-----------|------------|-------------|-------------|
|-------------------|------------|-------------|-------------|
|worker03           |6.3         |6.2          |             |
|worker02           |            |             |6.3          |
|IOMesh-------------|------------|-------------|-------------|
|worker03           |8.8         |8.8          |             |
|worker01           |            |             |10           |

Transaction rate:
| Test     | Mins       |  TPS        |
|----------|------------|-------------|
|PortWorx--|------------|-------------|
| 1st      |6.3         | 264,550.26  |
| 2nd      |6.2         | 268,817.20  |
| 3rd      |6.3         | 264,550.26  |
|IOMesh----|------------|-------------|
| 1st      | 8.8        | 189,393.94  |
| 2nd      | 8.8        | 189,393.93  |
| 3rd      | 10         | 166,666.67  |


# Crunchydata Benchmark on Portworx
## Cluster
### Postgres Cluster Congiguration
```
apiVersion: postgres-operator.crunchydata.com/v1beta1
kind: PostgresCluster
metadata:
  name: hippo
spec:
  image: registry.developers.crunchydata.com/crunchydata/crunchy-postgres:ubi8-16.2-0
  postgresVersion: 16
  instances:
    - name: psql
      replicas: 2
      dataVolumeClaimSpec:
        storageClassName: px-psql-rep1-sc
        accessModes:
        - "ReadWriteOnce"
        resources:
          requests:
            storage: 20Gi
  backups:
    pgbackrest:
      image: registry.developers.crunchydata.com/crunchydata/crunchy-pgbackrest:ubi8-2.49-0
      repos:
      - name: repo1
        volume:
          volumeClaimSpec:
            storageClassName: px-psql-rep1-sc
            accessModes:
            - "ReadWriteOnce"
            resources:
              requests:
                storage: 20Gi
  userInterface:
    pgAdmin:
      image: registry.developers.crunchydata.com/crunchydata/crunchy-pgadmin4:ubi8-4.30-22
      dataVolumeClaimSpec:
        accessModes:
          - 'ReadWriteOnce'
        resources:
          requests:
            storage: 5Gi
```
### PSQL PODs
```
hippo-psql-ct9l-0         4/4     Running     0          40m     10.233.108.34   worker02   <none>           <none>
hippo-psql-m5st-0         4/4     Running     0          40m     10.233.84.16    worker01   <none>           <none>
```

### Check PSQL Primary Node
```
kubectl -n postgres-operator get pods \
  --selector=postgres-operator.crunchydata.com/role=master \
  -o jsonpath='{.items[*].metadata.labels.postgres-operator\.crunchydata\.com/instance}'

hippo-psql-m5st-0
```

### Failover
```
kubectl -n postgres-operator get pods \
  --selector=postgres-operator.crunchydata.com/role=master \
  -o jsonpath='{.items[*].metadata.labels.postgres-operator\.crunchydata\.com/instance}'
hippo-psql-ct9l

hippo-psql-ct9l-0         4/4     Running     0          61m    10.233.108.34   worker02   <none>           <none>
hippo-psql-m5st-0         4/4     Running     0          3m7s   10.233.84.18    worker01   <none>           <none>
```

### Pgbench
```
pgbench -i -s 1000 hippo
.
.
.
.
99400000 of 100000000 tuples (99%) done (elapsed 352.09 s,
99500000 of 100000000 tuples (99%) done (elapsed 352.21 s,
99600000 of 100000000 tuples (99%) done (elapsed 355.45 s,
99700000 of 100000000 tuples (99%) done (elapsed 355.66 s,
99800000 of 100000000 tuples (99%) done (elapsed 356.10 s,
99900000 of 100000000 tuples (99%) done (elapsed 356.61 s,
100000000 of 100000000 tuples (100%) done (elapsed 356.88
s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 523.47 s (drop tables 0.00 s, create tables 0.06 s, client-side generate 358.08 s, vacuum 2.49 s, primary keys 162.84 s).
```
Time taken:
| PSQL Primary Node | 1st (Mins) |  2nd (Mins) |  3rd (Mins) |
|-------------------|------------|-------------|-------------|
|worker01           |8.72        | 7           |             |
|worker02           |            |             |    8.9      |

Transaction rate:
| Test     | Mins       |  TPS        |
|----------|------------|-------------|
| 1st      | 8.72       | 191,131.50  |
| 2nd      | 7          | 238,095.23  |
| 3rd      | 8.9        | 187,265.92  |