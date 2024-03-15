# I/O Test
The default 8k block size has been chosen to emulate a PostgreSQL workload.

# Tools
FIO: https://github.com/wallnerryan/fio-tools

# Deploy on K8S
```
kubectl cnp fio fio-job \
  -n fio  \
  --storageClass iomesh-psql-sc \
  --pvcSize 10Gi
```

# Configmap
```
[read]
    direct=1
    bs=8k
    size=8G
    time_based=1
    runtime=300
    ioengine=libaio
    iodepth=64
    end_fsync=1
    log_avg_msec=1000
    directory=/data
    rw=read
    rw=randwrite
    write_bw_log=read
    write_lat_log=read
    write_iops_log=read
    write_iops_log=write
    write_bw_log=write
    write_lat_log=write
```
# Result
## iomesh Storage Class
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
  resourceVersion: "10514671"
  uid: 950eec29-4eb7-4ff6-925d-be222cd25582
parameters:
  csi.storage.k8s.io/fstype: ext4
  replicaFactor: "2"
  thinProvision: "true"
provisioner: com.iomesh.csi-driver
reclaimPolicy: Retain
volumeBindingMode: Immediate

```
![image](https://github.com/paul6668/test/assets/105109093/26deeee3-ca24-4ec8-b61c-4090dc3d4149)

## ODF
![image](https://github.com/paul6668/test/assets/105109093/8bb4fdaa-a8b7-4f3a-9e3f-cc0b15fca5f1)


## local Storage Class
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    cas.openebs.io/config: |
      - name: StorageType
        value: "hostpath"
      - name: BasePath
        value: "/var/openebs/local"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{"cas.openebs.io/config":"- name: StorageType\n  value: \"hostpath\"\n- name: BasePath\n  value: \"/var/openebs/local\"\n","openebs.io/cas-type":"local","storageclass.beta.kubernetes.io/is-default-class":"true","storageclass.kubesphere.io/supported-access-modes":"[\"ReadWriteOnce\"]"},"name":"local"},"provisioner":"openebs.io/local","reclaimPolicy":"Delete","volumeBindingMode":"WaitForFirstConsumer"}
    openebs.io/cas-type: local
    storageclass.beta.kubernetes.io/is-default-class: "true"
    storageclass.kubesphere.io/supported-access-modes: '["ReadWriteOnce"]'
  creationTimestamp: "2023-11-10T09:18:37Z"
  name: local
  resourceVersion: "783"
  uid: 7c1295bc-d7e7-49f1-961e-e4f81a3214cc
provisioner: openebs.io/local
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```
![image](https://github.com/paul6668/test/assets/105109093/75e80fb6-4468-4aeb-8618-b78d9bfa43cd)

## Portworx
```
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
![image](https://github.com/paul6668/test/assets/105109093/2d75a13f-0b11-4d2e-86db-8f4c761fd11e)
