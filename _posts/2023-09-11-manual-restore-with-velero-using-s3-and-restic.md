---
title: Manual restore with velero using s3 and restic
description: How to restore something from a s3-restic-repo created using velero, when velero is unable to do it automatically.
categories:
  - velero
tags:
  - restic
  - s3
  - velero
  - talos
---

# Manual restore with velero using s3 and restic

Let me set the scene.

You have a cluster, you back it up using velero to a local S3-installation (minio), and remote offsite-backup's.

The cluster runs fine-ish, untill you do an upgrade, which ends up wiping all local storage (this was entirely my fault, not the storage's fault).

You begin to check out your restore-documentation, and work towards starting velero restore, only to find out that your local S3-installation was deleted during that move you started last week, but didn't quite finish doing yet.
You begin checking out your offsite-backups, which were rsync'ed copies of the before-mentioned S3-installation - only to find out that the rsync is either inconsistent, or just as bad as the S3-installation you moved away from (which had other issues, which again was my fault).

You start to give up, realising that all those files are just gone, and/or inconsistent.

## Offsite-backups to the rescue

I then realized I had another S3-installation offsite, from back when I experimented with using velero to write to different S3-installations at the same time.
The idea was that using rsync'ed S3-buckets wasn't all that great (go figure.), so I wanted a differeny copy, from the same source.

I managed to sneakernet the files from the original bucket back to my onsite MinIO-instance, and pointed Velero to the dedicated bucket, abtly named "Velero-Offsite", using Helm against the Velero-chart, this is accomlished with:
````yaml
- name: velero-offsite
  bucket: "velero-offsite"
  default: false
  provider: aws
  accessMode: ReadOnly
  config:
    region: "${VELERO_S3_REGION}"
    s3ForcePathStyle: true
    s3Url: "${S3_URL}"
    publicUrl: "${VELERO_S3_PUBLIC_URL}"
````

As of Helm-release 5.0.2, this is defined as a list under `configuration.backupStorageLocation`.

After import, Velero listed all those remote backups (all three of them...) but as "PartiallyFailed" (there was probably more than one reason for me giving up on the project).

I tried running a normal restore with Velero, that failed, it never actually restored anything from restic, just all the k8s-resources I could just as easily reproduce with flux...

One key difference between this offsite-backup, and the rsync'ed copy of the onsite-backup, was the size of the folders (where these folders are the actuall namespaces from the originating k8s-cluster) under the `/restic`-folder in the bucket - this one actually had a reasonably accurate size according to what I expected, whereas the rsync'ed copy had ~125K as reported foldersize.

### Digging through the internet for an answer

Determined that this bucket actually had the files I wanted, I went searching for an answer.
Using restic directly against the files in the bucket, was worthless.
````bash
# restic ls latest -r .
enter password for repository:
Load(<key/a7424b783b>, 0, 0) returned error, retrying after 552.330144ms: read keys/a7424b783b93bf66c9036982766365e9cb1aa41b698d069c0879473a94d0574a: is a directory
[...]

````
(btw, Velero uses a static password of `static-passw0rd` - might not be that safe, but I'm sure as hell glad they had something I could find!)

Much digging later, I got a clue when I found people that tried to restore single files from a restic-repo created by Velero, and more importantly - they reported success! (1) (2)

BUT HOW DID THEY DO IT?!

This is how I eventually figured it all out:
- velero-offsite is consistently used as the name for the LOCAL bucket, which originated from the offsite-location.
- velero is the namespace Velero is installed into.


1) Have Velero access the buckets like mentioned previously.
2) Ensure Velero can actually read the buckets, and enumerate the backups in there:
````bash
 $ velero get backup | grep velero-offsite
velero-daily-offsite-backup-20230724231041   PartiallyFailed   66       0          2023-07-24 23:10:41 +0200 CEST   19d ago   velero-offsite         <none>
````
3) As part of that backup-enumerate-import-thingy, Velero will also import a set of PodVolumeBackup, find those:
````bash
 $ kubectl -n velero get PodVolumeBackup | grep velero-offsite
velero-daily-offsite-backup-20230710231009-w5blz   Completed   63d       archivebox        archivebox-7b7bf94fd4-rl5hm                     config           s3:http://10.0.2.11:9000/velero-offsite/restic/archivebox         restic          offsite            107m
[...]
````
4. Figure out the `RepoIdentifier` and the `snapshotID` of the given repo.
````bash
 $ kubectl -n velero get PodVolumeBackup velero-daily-offsite-backup-20230710231009-w5blz -oyaml | grep -e repoIdentifier -e snapshotID
  repoIdentifier: s3:http://10.0.2.11:9000/velero-offsite/restic/archivebox
  snapshotID: 4779cab4
````

The S3-address will be the address to the previous (offsite) location, and you need to ensure it's still correct - I had to switch the IP to the local MinIO-instance.

We now have all we need to start the actuall restore - but I couldnt get the restore to work directly against the files from the bucket, I had to abuse a `velero-node-agent`.


5. This part might differ for you, I use Talos, so I have to do some tricks.
First I have to find the node running the pod I am going to restore too.
````bash
$ kubectl -n archivebox get pods  -o wide
NAME                                            READY   STATUS      RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
archivebox-7b6c66c695-mlnpk                      1/1     Running     0          57m   10.244.0.22   rand     <none>           <none>
````
Rand is a node, with IP `10.0.1.66`

6. Now we need to find where that Pod is mounted under the host_path.
````bash
$ for i in $(talosctl -n 10.0.1.66 ls /var/lib/kubelet/pods/ | sed 's/10.0.1.66   //g' | grep -v -e NODE); do echo $i; talosctl -n 10.0.1.66 ls /var/lib/kubelet/pods/$i/volumes/kubernetes.io~csi/; done > archivebox
````
(probably not the most elegant, but I was tired and it worked.)

7. Find the ID of the PVC.
````bash
$ kubectl -n archivebox get pvc
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
archivebox   Bound    pvc-40109437-464e-4617-8f93-ae3794d3ba0f   20Gi       RWX            ceph-filesystem   51m
````

8. Grep the output from command 6, for the PVC-number found in command 7.
````bash
$ grep -B5 pvc-40109437-464e-4617-8f93-ae3794d3ba0f archivebox
10.0.1.66   .
10.0.1.66   pvc-04e281b8-3039-42b9-bc88-143d38f1cb49
afa37c6c-34e9-40b7-bc27-3f791e44bae0
NODE        NAME
10.0.1.66   .
10.0.1.66   pvc-40109437-464e-4617-8f93-ae3794d3ba0f
````
You have now found the pod-id (afa37c6c-34e9-40b7-bc27-3f791e44bae0)

9. Almost there... Find the node-agent running on the same host.
````bash
$ kubectl -n velero get pods -o wide | grep rand
node-agent-k8q9v         1/1     Running   0          126m   10.244.0.16   rand       <none>           <none>
````

10. As a verification, the following should list the contents of the PVC you are about to restore too:
````bash
$ talosctl -n 10.0.1.66 ls /var/lib/kubelet/pods/<POD-ID-FOUND-IN-8>/volumes/kubernetes.io~csi/<PVC-ID-FOUD-IN-7>/mount/
$ talosctl -n 10.0.1.66 ls /var/lib/kubelet/pods/afa37c6c-34e9-40b7-bc27-3f791e44bae0/volumes/kubernetes.io~csi/pvc-40109437-464e-4617-8f93-ae3794d3ba0f/mount/
NODE        NAME
10.0.1.66   .
10.0.1.66   archivebox
````

11. If all that looks familiar, we are ready to restore!
````bash
$ kubectl -n velero exec -it <NODE-AGENT-FOUND-IN-9> -- restic restore <SNAPSHOT-ID-FOUND-INITALLY-IN-4> -r s3:http://10.0.1.78:9000/velero-offsite/restic/archivebox --target /host_pods/<POD-ID-FOUND-IN-8>/volumes/kubernetes.io~csi/<PVC-ID-FOUD-IN-7>/mount/restore/

$ kubectl -n velero exec -it node-agent-k8q9v -- restic restore 4779cab4 -r s3:http://10.0.1.78:9000/velero-offsite/restic/archivebox --target /host_pods/afa37c6c-34e9-40b7-bc27-3f791e44bae0/volumes/kubernetes.io~csi/pvc-40109437-464e-4617-8f93-ae3794d3ba0f/mount/restore/
enter password for repository:
repository 16397b86 opened (version 2, compression level auto)
restoring <Snapshot 4779cab4 of [/host_pods/2e2ed9ef-20f6-43bd-8844-cddd4f5580ca/volumes/kubernetes.io~csi/pvc-bdeb5be2-8ea9-491f-9bbe-4f58de1de88a/mount] at 2023-07-10 23:58:31.344943183 +0200 CEST by root@velero> to /host_pods/afa37c6c-34e9-40b7-bc27-3f791e44bae0/volumes/kubernetes.io~csi/pvc-40109437-464e-4617-8f93-ae3794d3ba0f/mount/restore/
````
/host_pods/ is where velero-node-agent mounts /var/lib/kubelet/pods
The password is still `static-passw0rd`.

12. Marvelous.


#### Lessons learned:
- Don't backup a backup.
  Multiple backups from same source is the key.
  If not possible, I would switch tools until it is.
- Probably ensure backups work before I do upgrades,
  but that's probably not going to happen...

Sources:

(1): https://github.com/vmware-tanzu/velero/issues/1210

(2): https://github.com/vmware-tanzu/velero/discussions/5860

