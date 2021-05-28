---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: efs
  annotations:
    volume.beta.kubernetes.io/storage-class: "filestore-client"
spec:
  accessModes:
    - ReadOnlyMany
    - ReadWriteOnce
  storageClassName: filestore-client
  resources:
    requests:
      storage: 1000Mi
