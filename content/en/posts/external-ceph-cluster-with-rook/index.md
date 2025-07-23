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

Setting up Kubernetes to use an external Ceph cluster can be challenging when combining tools like Rook and Proxmox in a hyperconverged setup. In this post, I'll walk you through how I integrated an external Ceph cluster running on Proxmox with a Kubernetes environment using [Rook](https://rook.io/).

By the end of this tutorial, you'll have a working Kubernetes cluster that can provision persistent volumes using your existing Ceph storage, enabling both block storage (RBD) and shared filesystem (CephFS) capabilities.

## Why I Use Rook with an External Ceph Cluster

In my homelab setup, I already had a working Ceph cluster as part of my Proxmox infrastructure. Rather than deploying a separate Ceph cluster within Kubernetes, I wanted to leverage this existing storage while maintaining the benefits of Rook's Kubernetes-native management. This approach provides distributed storage for my Kubernetes workloads without duplicating infrastructure resources.

## Prerequisites

Before starting this tutorial, ensure you have:

- **Kubernetes cluster** (v1.20 or later) with administrative access
- **Existing Ceph cluster** (running on Proxmox or standalone)
- **Rook Operator** deployed in your Kubernetes cluster
- **Network connectivity** between Kubernetes nodes and Ceph monitors
- **Administrative access** to your Ceph cluster for creating pools and users
- **Basic familiarity** with kubectl, Helm, and Ceph concepts

---

## Important: RFC 1123 DNS Label Standard

**Pool names must be RFC 1123 DNS label compliant.** This is a critical requirement because the script used to import the external cluster configuration uses the Ceph pool name to generate the corresponding Kubernetes `StorageClass` name. Since `StorageClass` objects are Kubernetes resources, their names must adhere to the RFC 1123 DNS label standard, which only allows lowercase letters, numbers, and hyphens.

I lost considerable time troubleshooting this issue because one of my pool names contained an uppercase letter, leading to an invalid `StorageClass` and failed storage provisioning.

On the import script it is possible to overwrite the storageClass names with `RBD_STORAGE_CLASS_NAME` and `CEPHFS_STORAGE_CLASS_NAME`.

---

## Step 1: Create Ceph Pools in Proxmox

Before Rook can provision storage, you need to create dedicated pools in your Ceph cluster. These pools will serve as the storage backend for Kubernetes persistent volumes.

1. **Log into the Proxmox web interface** and select your cluster.
2. Navigate to **Datacenter → Node → Ceph → Pools**.
3. Create two new pools with RFC 1123 compliant names:

   - `kubernetes-rbd` (for block storage volumes)
   - `kubernetes-cephfs` (for shared filesystem access)

4. **Configure pool settings:**

   - Set appropriate placement group (PG) count based on your cluster size
   - Choose a suitable replication factor (typically 3 for production)
   - Enable application tags: `rbd` for the RBD pool, `cephfs` for the CephFS pool

5. **Set up CephFS filesystem** (if using shared storage):
   - Navigate to **Ceph → CephFS**
   - Create a new filesystem using `kubernetes-cephfs` as the data pool
   - Proxmox will automatically create the required metadata pool

The pools are now ready to receive data from your Kubernetes workloads.

---

## Step 2: Deploy the Rook Cluster for External Ceph

Rook requires a special configuration when connecting to an external Ceph cluster instead of managing its own. The Rook project provides a pre-configured values file that disables internal Ceph deployment and prepares the cluster for external connectivity.

```bash
helm install rook-ceph-cluster rook-release/rook-ceph-cluster \
  --namespace rook-ceph \
  -f https://raw.githubusercontent.com/rook/rook/release-1.17/deploy/charts/rook-ceph-cluster/values-external.yaml
```

This command installs the Rook cluster configuration with external mode enabled. The values file configures Rook to expect connection details and authentication information from external sources rather than bootstrapping its own Ceph cluster.

**Expected output:**

```
NAME: rook-ceph-cluster
LAST DEPLOYED: [timestamp]
NAMESPACE: rook-ceph
STATUS: deployed
```

## Step 3: Verify Rook Operator Status

Before proceeding with the external cluster configuration, ensure the Rook operator is running correctly.

```bash
kubectl -n rook-ceph get pods
```

You should see the rook-ceph-operator pod in a Running state. If the operator isn't ready, wait for it to start before continuing to the next step.

---

## Step 4: Export External Ceph Cluster Details (Provider Side)

Now you need to extract connection details and authentication information from your Ceph cluster. This step must be performed on a node with administrative access to your Ceph cluster (typically a Proxmox node).

1. **Download the Rook export script:**

```bash
curl -O https://raw.githubusercontent.com/rook/rook/release-1.17/deploy/examples/create-external-cluster-resources.py
chmod +x create-external-cluster-resources.py
```

This script automates the process of gathering Ceph monitor addresses, authentication keys, and pool information required by Rook.

2. **Run the export script with your specific configuration:**

```bash
python3 create-external-cluster-resources.py \
  --rbd-data-pool-name kubernetes-rbd \
  --cephfs-filesystem-name kubernetes-cephfs \
  --k8s-cluster-name talos-proxmox-cluster \
  --restricted-auth-permission true \
  --skip-monitoring-endpoint \
  --format bash
```

**Parameter explanation:**

- `--rbd-data-pool-name`: The RBD pool created in Step 1
- `--cephfs-filesystem-name`: The CephFS filesystem name
- `--k8s-cluster-name`: A unique identifier for your Kubernetes cluster
- `--restricted-auth-permission`: Creates limited-privilege Ceph users for security
- `--skip-monitoring-endpoint`: Excludes monitoring configuration (optional)
- `--format bash`: Outputs shell export statements

**Expected output:**
The script generates a series of export statements containing monitor addresses, authentication keys, and configuration data that Rook needs to connect to your external Ceph cluster.

---

## Step 5: Import External Ceph Cluster (Consumer Side)

With the connection details exported from your Ceph cluster, you now need to import this information into your Kubernetes environment where Rook is running.

1. **Download the import script** from https://github.com/rook/rook/blob/release-1.17/deploy/examples/import-external-cluster.sh

2. Paste the output into the terminal and run the import script.
   For non RFC compliant pool names it is possible to overwrite the storageClass names with `RBD_STORAGE_CLASS_NAME` and `CEPHFS_STORAGE_CLASS_NAME`.

```bash
export ROOK_EXTERNAL_USER_SECRET="AQD..."
export ROOK_EXTERNAL_USERNAME="client.kubernetes"
export ROOK_EXTERNAL_FSID="12345678-1234-1234-1234-123456789abc"
...
./import-external-cluster.sh
EOF
```

The script creates all the necessary Secrets, StorageClass and other CustomResource Objects.
Replace the example values with the actual output from your export script.

---

## Verification and Testing

After completing the setup, verify that Rook can successfully connect to your external Ceph cluster:

1. **Check storage classes:**

```bash
kubectl get storageclass
```

You should see Rook-managed storage classes for both RBD and CephFS.

2. **Test persistent volume creation:**

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-rbd-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ceph-rbd
EOF
```

3. **Verify the PVC is bound:**

```bash
kubectl get pvc test-rbd-pvc
```

The status should show "Bound" if the connection to your external Ceph cluster is working correctly.

## Troubleshooting

If you encounter issues, check these common areas:

- **Rook operator logs:** `kubectl -n rook-ceph logs deploy/rook-ceph-operator`
- **Ceph cluster health:** Access your Proxmox Ceph dashboard for cluster status
- **Network connectivity:** Ensure Kubernetes nodes can reach Ceph monitor addresses
- **Authentication:** Verify that the imported secrets match your Ceph cluster configuration
- **Pool names:** Confirm all pool names are RFC 1123 compliant (lowercase, no special characters)

## Conclusion

This setup decouples your Kubernetes storage layer from your cluster lifecycle, which is particularly valuable in homelab and hyperconverged environments like Proxmox. You can now leverage powerful Ceph features—including RBD block storage and CephFS shared filesystems—without managing a separate Ceph cluster within Kubernetes.

The external Ceph integration provides persistent storage that survives Kubernetes cluster rebuilds while maintaining the operational benefits of Rook's Kubernetes-native management interface.

---
