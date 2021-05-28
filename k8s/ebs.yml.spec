kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: testground-daemon-datadir-pvc
  labels:
    type: aws-ebs
spec:
  storageClassName: "gp2-retain"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

---

kind: PersistentVolume
apiVersion: v1
metadata:
  name: testground-daemon-datadir-pv
  labels:
    type: aws-ebs
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: "gp2-retain"
  awsElasticBlockStore:
    volumeID: ${TG_EBS_DATADIR_VOLUME_ID}
    fsType: ext4

---

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: gp2-retain
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Retain
mountOptions:
  - debug
volumeBindingMode: Immediate
