---
date: 2025-06-03T00:50:00Z
title: Using an External Ceph Cluster with Rook in Kubernetes
description: Learn how to integrate an external Ceph cluster from Proxmox with Kubernetes using Rook for reliable, hyperconverged storage.
draft: true
tags:
- kubernetes
- proxmox
- hands-on
categories:
- kubernetes
---

Setting up Kubernetes to use an external Ceph cluster can be daunting,
especially when combining tools like Rook and Proxmox in a hyperconverged setup.
In this post, I’ll walk you through how I integrated an external Ceph cluster
(running on Proxmox) with a Kubernetes environment using
[Rook](https://rook.io/).

---

## Why I Use Rook with an External Ceph Cluster?

In my case, I already had a working Ceph cluster as part of my Proxmox setup.
Since I’m running a homelab, I don’t have the luxury of spinning up a separate
infrastructure just for Kubernetes storage but I was in need of a distributed
storage solution for it.

---

## Prerequisite

For this Hands-On you will need the following:

- Kubernetes Cluster
- Ceph Operator deployment (inside Kubernetes)

---

## ⚠️ Important: RFC 1123 DNS label standard

**Pool names must be RFC 1123 DNS label compliant.** I lost a lot of time
troubleshooting issues caused by a pool name with an uppercase letter. This one
should already be familiar as Kubernetes Object Names also adhere to it –
[Kubernetes - RFC 1123 Label Names](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/).

---

## Step 1: Create Ceph Pools in Proxmox

Before Rook can use Ceph, you need to create the required pools on your Proxmox
cluster.

1. **Log into the Proxmox UI**.
2. Navigate to **Node → Ceph → Pools**.
3. Create two new pools:

   - `kubernetes-rbd` (for block storage)
   - `kubernetes-cephfs` (for shared filesystem)

4. Once the pools are created, make sure CephFS is also set up with the
   appropriate data and metadata pools (which Proxmox will handle if configured
   via the GUI).

---

## Step 2: Deploy the Rook Cluster for using an external Ceph

Rook needs a special "external" configuration for the cluster deployment.
Luckily they already prepared a `values.yaml` file for that.

```bash
helm install rook-ceph-cluster rook-release/rook-ceph-cluster \
  --namespace rook-ceph \
  -f https://raw.githubusercontent.com/rook/rook/release-1.16/deploy/charts/rook-ceph-cluster/values-external.yaml
```

---

## Step 4: Export External Ceph Cluster Details (Provider Side)

From a node in your Ceph cluster (typically a Proxmox node with access to `ceph`
commands):

1. Download the export script:

```bash
curl -O https://raw.githubusercontent.com/rook/rook/release-1.16/deploy/examples/create-external-cluster-resources.py
chmod +x create-external-cluster-resources.py
```

2. Run the script with the appropriate flags (update names to match your pools
   and cluster):

```bash
python3 create-external-cluster-resources.py \
  --rbd-data-pool-name kubernetes-rbd \
  --cephfs-filesystem-name kubernetes-cephfs \
  --k8s-cluster-name talos-proxmox-cluster \
  --restricted-auth-permission true \
  --skip-monitoring-endpoint \
  --format bash
```

This will generate an output containing secrets, connection info, and
configurations needed by Rook in Kubernetes.

---

## Step 5: Import External Ceph Cluster (Consumer Side)

Back in your Kubernetes environment:

1. Copy the output from the export script (the `export` statements).
2. Paste it into a new shell script, e.g., `import-script.sh`:

```bash
#!/bin/bash
# Contents from the script output
export ROOK_CEPH_MON_HOST=...
export ROOK_CEPH_SECRET=...
...
```

3. Run the script in your shell:

```bash
source import-script.sh
```

Rook will now use this information to connect your Kubernetes cluster to the
external Ceph provider.

---

## Final Thoughts

This setup allows you to decouple your Kubernetes storage layer from your
cluster lifecycle, which is especially helpful in homelab and hyperconverged
environments like Proxmox. Plus, it lets you leverage powerful Ceph
features—like RBD and CephFS—without managing Ceph inside Kubernetes.

Make sure your pool names are compliant, monitor your RBD provisioners, and
verify Ceph access using `kubectl get sc` and PVCs once everything is set up.

If you run into issues, check:

- The Ceph dashboard for logs
- Rook operator logs via `kubectl -n rook-ceph logs deploy/rook-ceph-operator`

---
