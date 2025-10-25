# 🏗️ Kind Kubernetes Cluster Manager - Architecture Documentation

## 📋 Table of Contents

- [System Architecture](#system-architecture)
- [Component Architecture](#component-architecture)
- [Workflow Diagrams](#workflow-diagrams)
- [Script Interactions](#script-interactions)
- [Network Architecture](#network-architecture)
- [Data Flow](#data-flow)
- [Storage Architecture](#storage-architecture)
- [Security Model](#security-model)

## 🏗️ System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Host Machine (macOS)                         │
├─────────────────────────────────────────────────────────────────────────┤
│                          Docker Desktop                                │
├─────────────────────────────────────────────────────────────────────────┤
│                     Kind Kubernetes Cluster                            │
│                                                                         │
│  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐   │
│  │ Control Plane     │  │   Worker Node 1   │  │   Worker Node 2   │   │
│  │ my-cluster-control│  │ my-cluster-worker │  │ my-cluster-worker2│   │
│  │                   │  │                   │  │                   │   │
│  │ • API Server      │  │ • kubelet         │  │ • kubelet         │   │
│  │ • etcd            │  │ • Container       │  │ • Container       │   │
│  │ • Scheduler       │  │   Runtime         │  │   Runtime         │   │
│  │ • Controller Mgr  │  │ • kube-proxy      │  │ • kube-proxy      │   │
│  │ • kubelet         │  │                   │  │                   │   │
│  └───────────────────┘  └───────────────────┘  └───────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                        Application Layer                           │ │
│  │                                                                     │ │
│  │  ┌─────────────────┐                 ┌─────────────────────────────┐ │ │
│  │  │ Nginx Deployment│                 │      MySQL Deployment       │ │ │
│  │  │                 │                 │                             │ │ │
│  │  │ ┌─────────────┐ │                 │ ┌─────────────────────────┐ │ │ │
│  │  │ │    Pod 1    │ │                 │ │         Pod 1           │ │ │ │
│  │  │ │ nginx:latest│ │                 │ │    mysql:8.0            │ │ │ │
│  │  │ │             │ │                 │ │                         │ │ │ │
│  │  │ │ Port: 80    │ │                 │ │ Port: 3306              │ │ │ │
│  │  │ │ Port: 443   │ │                 │ │                         │ │ │ │
│  │  │ └─────────────┘ │                 │ │ Persistent Volume       │ │ │ │
│  │  │                 │                 │ │ /var/lib/mysql          │ │ │ │
│  │  │ Service:        │                 │ └─────────────────────────┘ │ │ │
│  │  │ nginx-service   │                 │                             │ │ │
│  │  │ ClusterIP       │                 │ Service:                    │ │ │
│  │  └─────────────────┘                 │ mysql-service               │ │ │
│  │                                      │ ClusterIP                   │ │ │
│  │                                      └─────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### Port Mapping Architecture

```
Host Machine (localhost)                    Kind Cluster
┌─────────────────────────┐                ┌────────────────────────┐
│                         │                │                        │
│ Port 9080  ──────────────┼────────────────┼─→ nginx-service:80     │
│ (HTTP)                  │                │   (Nginx Pod)          │
│                         │                │                        │
│ Port 9443  ──────────────┼────────────────┼─→ nginx-service:443    │
│ (HTTPS)                 │                │   (Nginx Pod)          │
│                         │                │                        │
│ Port 30306 ──────────────┼────────────────┼─→ mysql-service:3306   │
│ (MySQL)                 │                │   (MySQL Pod)          │
│                         │                │                        │
└─────────────────────────┘                └────────────────────────┘
```

## 🔧 Component Architecture

### Script Component Hierarchy

```
Project Root
├── setup.sh              (Interactive Cluster Manager)
│   ├── create_cluster()  ──→ Uses kind-config-{name}.yaml
│   ├── deploy_apps()     ──→ Uses nginx-*.yaml, mysql-*.yaml
│   ├── test_cluster()    ──→ Calls test-cluster.sh
│   └── cleanup()         ──→ Calls kind delete
│
├── cluster-utils.sh       (Command-line Utilities)
│   ├── list_clusters()   ──→ Docker container inspection
│   ├── start_cluster()   ──→ docker start containers
│   ├── stop_cluster()    ──→ docker stop containers
│   ├── status()          ──→ kubectl + docker status
│   ├── logs()            ──→ kubectl logs aggregation
│   └── backup()          ──→ MySQL dump + config backup
│
├── test-cluster.sh        (Testing & Validation)
│   ├── test_basics()     ──→ kubectl connectivity
│   ├── test_nginx()      ──→ HTTP/HTTPS endpoint testing
│   ├── test_mysql()      ──→ Database connectivity
│   └── port_forward()    ──→ Service exposure
│
└── demo.sh               (Feature Demonstration)
    ├── demo_cluster()    ──→ Complete workflow demo
    ├── demo_features()   ──→ Feature showcase
    └── interactive_tour() ──→ Guided walkthrough
```

## 📊 Workflow Diagrams

### 1. Cluster Creation Workflow

```
┌─────────────────┐
│   User Starts   │
│   ./setup.sh    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Interactive     │
│ Menu Display    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Option 1:       │    │ Option 2:       │    │ Option 3:       │
│ Create Cluster  │    │ List Clusters   │    │ Delete Cluster  │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Get Cluster     │    │ Call            │    │ Select Cluster  │
│ Name (Input)    │    │ list_clusters() │    │ to Delete       │
└─────────┬───────┘    └─────────────────┘    └─────────┬───────┘
          │                                             │
          ▼                                             ▼
┌─────────────────┐                           ┌─────────────────┐
│ Generate        │                           │ Confirmation    │
│ kind-config.yaml│                           │ Prompt          │
└─────────┬───────┘                           └─────────┬───────┘
          │                                             │
          ▼                                             ▼
┌─────────────────┐                           ┌─────────────────┐
│ kind create     │                           │ kind delete     │
│ cluster         │                           │ cluster         │
└─────────┬───────┘                           └─────────────────┘
          │
          ▼
┌─────────────────┐
│ Wait for        │
│ Cluster Ready   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Deploy Nginx    │
│ (nginx-*.yaml)  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Deploy MySQL    │
│ (mysql-*.yaml)  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Run Tests       │
│ (test-cluster.sh)│
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Display Access  │
│ Information     │
└─────────────────┘
```

### 2. Testing Workflow

```
┌─────────────────┐
│ test-cluster.sh │
│ [cluster-name]  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐     ❌     ┌─────────────────┐
│ Cluster Exists? │ ─────────→ │ Error: Cluster  │
│ (kubectl)       │            │ Not Found       │
└─────────┬───────┘            └─────────────────┘
          │ ✅
          ▼
┌─────────────────┐
│ Setup Port      │
│ Forwarding      │
│ (Background)    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐     ❌     ┌─────────────────┐
│ Test Basic      │ ─────────→ │ Error: kubectl  │
│ Connectivity    │            │ Issues          │
└─────────┬───────┘            └─────────────────┘
          │ ✅
          ▼
┌─────────────────┐     ❌     ┌─────────────────┐
│ Test Nginx      │ ─────────→ │ Error: Nginx    │
│ HTTP Endpoint   │            │ Not Accessible  │
└─────────┬───────┘            └─────────────────┘
          │ ✅
          ▼
┌─────────────────┐     ❌     ┌─────────────────┐
│ Test Nginx      │ ─────────→ │ Error: HTTPS    │
│ HTTPS Endpoint  │            │ Certificate     │
└─────────┬───────┘            └─────────────────┘
          │ ✅
          ▼
┌─────────────────┐     ❌     ┌─────────────────┐
│ Test MySQL      │ ─────────→ │ Error: Database │
│ Connection      │            │ Connection      │
└─────────┬───────┘            └─────────────────┘
          │ ✅
          ▼
┌─────────────────┐     ❌     ┌─────────────────┐
│ Test Data       │ ─────────→ │ Error: Data     │
│ Operations      │            │ Integrity       │
└─────────┬───────┘            └─────────────────┘
          │ ✅
          ▼
┌─────────────────┐
│ Cleanup Port    │
│ Forwarding      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Display Test    │
│ Results Summary │
└─────────────────┘
```

### 3. Cluster State Management

```
┌─────────────────┐
│ cluster-utils.sh│
│ status <name>   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Check Docker    │
│ Containers      │
│ (Label Filter)  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Count Running   │
│ vs Total        │
│ Containers      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ All Running?    │    │ Some Running?   │    │ None Running?   │
│ Status: Running │    │ Status: Partial │    │ Status: Stopped │
└─────────────────┘    └─────────────────┘    └─────────┬───────┘
                                                        │
                                                        ▼
                                              ┌─────────────────┐
                                              │ No Containers?  │
                                              │ Status: Missing │
                                              └─────────────────┘
```

### 4. Start/Stop Operations

```
STOP CLUSTER:
┌─────────────────┐
│ cluster-utils.sh│
│ stop <name>     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Get Container   │
│ Names by Label  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ docker stop     │
│ <containers>    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Verify Stopped  │
│ Status          │
└─────────────────┘

START CLUSTER:
┌─────────────────┐
│ cluster-utils.sh│
│ start <name>    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Get Container   │
│ Names by Label  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ docker start    │
│ <containers>    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Wait for        │
│ Ready State     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Verify Running  │
│ Status          │
└─────────────────┘
```

## 🔗 Script Interactions

### Dependency Graph

```
setup.sh
├── Uses: kind-config-{name}.yaml (generated)
├── Uses: nginx-deployment.yaml
├── Uses: nginx-service.yaml  
├── Uses: mysql-*.yaml files
├── Calls: test-cluster.sh
└── Calls: cluster-utils.sh (for listing)

cluster-utils.sh
├── Uses: Docker API (container management)
├── Uses: kubectl (cluster operations)
├── Calls: mysqldump (for backups)
└── Independent operation

test-cluster.sh  
├── Uses: kubectl (testing)
├── Uses: curl (HTTP testing)
├── Uses: mysql client (DB testing)
├── Uses: openssl (certificate testing)
└── Called by: setup.sh

demo.sh
├── Calls: setup.sh (simulated)
├── Calls: cluster-utils.sh
├── Calls: test-cluster.sh
└── Interactive demonstration mode
```

### Data Exchange

```
setup.sh ─────────── CLUSTER_NAME ──────────→ test-cluster.sh
    │                                              │
    │                                              ▼
    ├─────── Generated Config Files ─────→ kind create cluster
    │                                              │
    ▼                                              ▼
cluster-utils.sh ←──── Docker Containers ────── Kind Runtime
    │                                              │
    │                                              ▼
    └─────── Container States ──────────→ Status Reporting
```

## 🌐 Network Architecture

### Internal Cluster Networking

```
┌─────────────────────────────────────────────────────────────┐
│                    Kind Network Bridge                      │
│                     (172.18.0.0/16)                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Control Plane Node          Worker Node 1     Worker Node 2│
│  ┌─────────────────┐         ┌─────────────┐   ┌─────────────┐│
│  │ 172.18.0.2      │         │ 172.18.0.3  │   │ 172.18.0.4  ││
│  │                 │         │             │   │             ││
│  │ kube-apiserver  │         │ kubelet     │   │ kubelet     ││
│  │ :6443           │         │ kube-proxy  │   │ kube-proxy  ││
│  │                 │         │             │   │             ││
│  │ etcd :2379      │         │             │   │             ││
│  └─────────────────┘         └─────────────┘   └─────────────┘│
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    Service Network                          │
│                     (10.96.0.0/16)                         │
│                                                             │
│  nginx-service        mysql-service        kubernetes       │
│  10.96.1.100         10.96.1.200          10.96.0.1        │
│  :80, :443           :3306                :443              │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                     Pod Network                             │
│                    (10.244.0.0/16)                         │
│                                                             │
│  nginx-pod           mysql-pod                              │
│  10.244.1.10         10.244.2.10                           │
│  :80, :443           :3306                                  │
└─────────────────────────────────────────────────────────────┘
```

### External Access Pattern

```
Internet/Host
      │
      ▼
┌─────────────────┐
│ Host Machine    │
│ localhost       │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Docker Desktop  │
│ Port Mapping    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Kind Cluster    │
│ Node Ports      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Kubernetes      │
│ Services        │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Application     │
│ Pods            │
└─────────────────┘
```

## 💾 Data Flow

### MySQL Data Persistence

```
Host Volume Mount                     Container Volume Mount
┌─────────────────────────────────┐  ┌─────────────────────────────────┐
│ Docker Desktop VM               │  │ MySQL Container                 │
│                                 │  │                                 │
│ /var/lib/docker/volumes/        │  │ /var/lib/mysql                  │
│ mysql-data-{cluster}/_data      │ ←→ │                                 │
│                                 │  │ ┌─────────────────────────────┐ │
│ ┌─────────────────────────────┐ │  │ │ • ibdata1 (tablespace)     │ │
│ │ • mysql/ (system tables)   │ │  │ │ • ib_logfile* (redo logs)   │ │
│ │ • performance_schema/       │ │  │ │ • mysql.ibd                 │ │
│ │ • sys/                      │ │  │ │ • undo_001, undo_002       │ │
│ │ • testdb/ (app database)    │ │  │ │ • testdb/ (application DB)  │ │
│ │ • binlog.* (binary logs)    │ │  │ │ • binlog.* (replication)    │ │
│ └─────────────────────────────┘ │  │ └─────────────────────────────┘ │
└─────────────────────────────────┘  └─────────────────────────────────┘
```

### Configuration Data Flow

```
Template Files                    Generated Files               Runtime
┌─────────────────┐              ┌─────────────────┐           ┌─────────────────┐
│ kind-config.yaml│              │kind-config-     │           │ Kubernetes      │
│ (template)      │ ──generate──→│ {name}.yaml     │ ──apply──→│ Cluster         │
└─────────────────┘              └─────────────────┘           └─────────────────┘

┌─────────────────┐              ┌─────────────────┐           ┌─────────────────┐
│ nginx-*.yaml    │              │ SSL Certificates│           │ Nginx Pods      │
│ mysql-*.yaml    │ ──process───→│ Config Maps     │ ──mount──→│ MySQL Pods      │
│ (static)        │              │ Secrets         │           │ Services        │
└─────────────────┘              └─────────────────┘           └─────────────────┘
```

## 💽 Storage Architecture

### Persistent Volume Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Host Machine                               │
├─────────────────────────────────────────────────────────────────────────┤
│                            Docker Desktop                               │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                    Docker Volume Management                         │ │
│  │                                                                     │ │
│  │  Volume: mysql-data-{cluster-name}                                  │ │
│  │  Location: /var/lib/docker/volumes/mysql-data-{cluster}/           │ │
│  │  Type: local                                                        │ │
│  │  Driver: local                                                      │ │
│  │                                                                     │ │
│  │  ┌─────────────────────────────────────────────────────────────┐    │ │
│  │  │                Kubernetes Abstraction                       │    │ │
│  │  │                                                             │    │ │
│  │  │  PersistentVolume (PV)                                      │    │ │
│  │  │  ├── Name: mysql-pv-{cluster}                               │    │ │
│  │  │  ├── Capacity: 10Gi                                         │    │ │
│  │  │  ├── Access Mode: ReadWriteOnce                             │    │ │
│  │  │  ├── Reclaim Policy: Retain                                 │    │ │
│  │  │  └── Host Path: /mnt/data                                   │    │ │
│  │  │                                                             │    │ │
│  │  │  PersistentVolumeClaim (PVC)                                │    │ │
│  │  │  ├── Name: mysql-pvc                                        │    │ │
│  │  │  ├── Request: 10Gi                                          │    │ │
│  │  │  ├── Access Mode: ReadWriteOnce                             │    │ │
│  │  │  └── Bound to: mysql-pv-{cluster}                          │    │ │
│  │  │                                                             │    │ │
│  │  │  MySQL Pod                                                  │    │ │
│  │  │  ├── Volume Mount: /var/lib/mysql                           │    │ │
│  │  │  ├── Bound PVC: mysql-pvc                                   │    │ │
│  │  │  └── Container: mysql:8.0                                   │    │ │
│  │  └─────────────────────────────────────────────────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Lifecycle

```
Cluster Creation                   Data Operations                  Cluster Deletion
┌─────────────────┐               ┌─────────────────┐               ┌─────────────────┐
│ Create PV/PVC   │               │ MySQL Writes    │               │ Stop Cluster    │
│ Mount Volume    │ ────────────→ │ to /var/lib/    │ ────────────→ │ (Data Persists) │
│ Initialize DB   │               │ mysql           │               │ in Docker Vol   │
└─────────────────┘               └─────────────────┘               └─────────────────┘
         │                                 │                                │
         ▼                                 ▼                                ▼
┌─────────────────┐               ┌─────────────────┐               ┌─────────────────┐
│ Empty Database  │               │ Persistent      │               │ Data Available  │
│ Schema Created  │               │ Storage         │               │ for Restart     │
│ Users Created   │               │ (Survives Pod   │               │ or Recovery     │
│ Sample Data     │               │ Restarts)       │               │                 │
└─────────────────┘               └─────────────────┘               └─────────────────┘
```

## 🔒 Security Model

### Authentication & Authorization

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Security Layers                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                        Cluster Security                            │ │
│  │                                                                     │ │
│  │  • Kubernetes RBAC (default service accounts)                      │ │
│  │  • TLS encryption for cluster communication                        │ │
│  │  • Isolated network namespaces                                     │ │
│  │  • Container runtime security (Docker)                             │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                      Application Security                           │ │
│  │                                                                     │ │
│  │  Nginx (Web Server):                                               │ │
│  │  ├── Self-signed SSL certificates                                  │ │
│  │  ├── HTTP redirect to HTTPS                                        │ │
│  │  ├── Non-root container user                                       │ │
│  │  └── Read-only filesystem (except temp dirs)                       │ │
│  │                                                                     │ │
│  │  MySQL (Database):                                                 │ │
│  │  ├── Root password (auto-generated)                                │ │
│  │  ├── Application user with limited privileges                      │ │
│  │  ├── Database-specific access controls                             │ │
│  │  ├── Internal cluster networking only                              │ │
│  │  └── Encrypted connections (SSL/TLS)                               │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                        Network Security                             │ │
│  │                                                                     │ │
│  │  • Services isolated within cluster network                        │ │
│  │  • External access only through defined NodePorts                  │ │
│  │  • No direct pod-to-host communication                             │ │
│  │  • Inter-service communication via service DNS                     │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### Certificate Management

```
SSL Certificate Generation (nginx-tls-setup.sh):
┌─────────────────┐
│ Generate        │
│ Private Key     │
│ (nginx.key)     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Create          │
│ Certificate     │
│ Request (CSR)   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Self-sign       │
│ Certificate     │
│ (nginx.crt)     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Create          │
│ Kubernetes      │
│ Secret          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Mount in        │
│ Nginx Pod       │
│ (/etc/ssl/)     │
└─────────────────┘
```

### Access Control Matrix

```
Component      │ Internal Access        │ External Access       │ Security
─────────────────────────────────────────────────────────────────────────
Nginx Web      │ Service: nginx-service │ Host: localhost:9080  │ HTTP/HTTPS
Server         │ Port: 80, 443         │      localhost:9443  │ SSL/TLS
─────────────────────────────────────────────────────────────────────────
MySQL          │ Service: mysql-service │ Host: localhost:30306 │ User Auth
Database       │ Port: 3306            │                       │ SSL/TLS
─────────────────────────────────────────────────────────────────────────
Kubernetes     │ Internal cluster API   │ kubectl via context   │ RBAC
API            │ service discovery     │ admin credentials     │ TLS
─────────────────────────────────────────────────────────────────────────
Management     │ Docker socket         │ Host shell access     │ File perms
Scripts        │ kubectl config        │ script execution      │ User context
```

---

## 🔧 Implementation Details

### Container Resource Allocation

```
Resource Limits per Component:
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Control Plane   │  │   Worker 1      │  │   Worker 2      │
│                 │  │                 │  │                 │
│ CPU: 100m       │  │ CPU: 100m       │  │ CPU: 100m       │
│ Memory: 512Mi   │  │ Memory: 512Mi   │  │ Memory: 512Mi   │
│                 │  │                 │  │                 │
│ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │
│ │ System Pods │ │  │ │ Nginx Pod   │ │  │ │ MySQL Pod   │ │
│ │             │ │  │ │             │ │  │ │             │ │
│ │ CPU: 50m    │ │  │ │ CPU: 50m    │ │  │ │ CPU: 100m   │ │
│ │ Memory:128Mi│ │  │ │ Memory:64Mi │ │  │ │ Memory:256Mi│ │
│ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

This architecture documentation provides a comprehensive view of the Kind Kubernetes cluster management system, detailing how each component interacts, data flows through the system, and security is maintained across all layers.
