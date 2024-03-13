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
## iomesh
![image](https://github.com/paul6668/test/assets/105109093/26deeee3-ca24-4ec8-b61c-4090dc3d4149)

## local
![image](https://github.com/paul6668/test/assets/105109093/75e80fb6-4468-4aeb-8618-b78d9bfa43cd)
