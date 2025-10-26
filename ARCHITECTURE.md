# 🏗️ Kind Kubernetes Cluster Manager - Architecture Documentation

This document provides comprehensive architecture diagrams using Mermaid to visualize the complete Kubernetes cluster system.

## 📋 Table of Contents

- [System Architecture](#system-architecture)
- [Workflow Diagrams](#workflow-diagrams)
- [Script Interactions](#script-interactions)  
- [Network Architecture](#network-architecture)
- [Data Flow](#data-flow)
- [Storage Architecture](#storage-architecture)
- [Security Model](#security-model)

## 🏗️ System Architecture

### High-Level Overview

```mermaid
graph TB
    subgraph "🖥️ Host Machine macOS"
        subgraph "🐳 Docker Desktop" 
            subgraph "☸️ Kind Kubernetes Cluster"
                CP["🎛️ Control Plane<br/>my-cluster-control<br/>API Server :6443"]
                W1["🔧 Worker Node 1<br/>my-cluster-worker<br/>kubelet + runtime"]
                W2["🔧 Worker Node 2<br/>my-cluster-worker2<br/>kubelet + runtime"]
                
                subgraph "🚀 Application Layer"
                    NGINX["🌐 Nginx Service<br/>nginx:latest<br/>Ports: 80,443"]
                    MYSQL["🗄️ MySQL Service<br/>mysql:8.0<br/>Port: 3306"]
                    PV["💾 Persistent Volume<br/>/var/lib/mysql"]
                end
            end
        end
        
        HTTP["🌍 localhost:9080<br/>HTTP Access"]
        HTTPS["🔒 localhost:9443<br/>HTTPS Access"] 
        MYSQLEXT["🔌 localhost:30306<br/>MySQL Access"]
    end
    
    HTTP --> NGINX
    HTTPS --> NGINX
    MYSQLEXT --> MYSQL
    MYSQL --> PV
    
    classDef controlPlane fill:#e1f5fe,stroke:#01579b,stroke-width:3px,font-size:16px,font-weight:bold
    classDef worker fill:#f3e5f5,stroke:#4a148c,stroke-width:3px,font-size:16px,font-weight:bold
    classDef app fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:16px,font-weight:bold
    classDef external fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:16px,font-weight:bold
    classDef storage fill:#f1f8e9,stroke:#33691e,stroke-width:3px,font-size:16px,font-weight:bold
    
    class CP controlPlane
    class W1,W2 worker
    class NGINX,MYSQL app
    class HTTP,HTTPS,MYSQLEXT external
    class PV storage
```

### Port Mapping Architecture

```mermaid
graph LR
    subgraph "🖥️ Host localhost"
        HP1["Port 9080<br/>HTTP"]
        HP2["Port 9443<br/>HTTPS"]
        HP3["Port 30306<br/>MySQL"]
    end
    
    subgraph "☸️ Kind Cluster"
        NS["nginx-service<br/>ClusterIP:80,443"]
        MS["mysql-service<br/>ClusterIP:3306"]
    end
    
    HP1 --> NS
    HP2 --> NS  
    HP3 --> MS
    
    classDef host fill:#fff3e0,stroke:#e65100,stroke-width:2px,font-size:16px,font-weight:bold
    classDef service fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px,font-size:16px,font-weight:bold
    
    class HP1,HP2,HP3 host
    class NS,MS service
```

## 📊 Workflow Diagrams

### 1. Cluster Creation Workflow

```mermaid
flowchart TD
    START["🚀 User Starts<br/>./setup.sh"] --> MENU["📋 Interactive Menu"]
    
    MENU --> OPT1["1️⃣ Create Cluster"]
    MENU --> OPT2["2️⃣ List Clusters"] 
    MENU --> OPT3["3️⃣ Delete Cluster"]
    
    OPT1 --> INPUT["⌨️ Get Cluster Name<br/>User Input Validation"]
    INPUT --> GENERATE["📝 Generate Config<br/>kind-config.yaml"]
    GENERATE --> CREATE["🔨 Create Cluster<br/>kind create cluster"]
    CREATE --> WAIT["⏳ Wait for Ready<br/>Status Verification"]
    WAIT --> NGINX["🌐 Deploy Nginx<br/>Apply YAML manifests"]
    NGINX --> MYSQL["🗄️ Deploy MySQL<br/>Apply YAML manifests"]
    MYSQL --> TEST["🧪 Run Tests<br/>test-cluster.sh"]
    TEST --> ACCESS["✅ Display Access Info<br/>URLs & Credentials"]
    
    OPT2 --> LIST["📊 Show All Clusters<br/>Docker inspection"]
    OPT3 --> SELECT["🎯 Select Cluster"] --> DELETE["🗑️ Delete Cluster"]
    
    classDef start fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px,font-size:16px,font-weight:bold
    classDef process fill:#e3f2fd,stroke:#0277bd,stroke-width:2px,font-size:16px,font-weight:bold
    classDef action fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,font-size:16px,font-weight:bold
    
    class START,ACCESS start
    class MENU,INPUT,GENERATE,WAIT,LIST,SELECT process
    class CREATE,NGINX,MYSQL,TEST,DELETE action
```

### 2. Testing Workflow

```mermaid
flowchart TD
    START["�� Start Testing<br/>test-cluster.sh"] --> CHECK{"�� Cluster Exists?"}
    
    CHECK -->|No| ERROR1["❌ Cluster Not Found"]
    CHECK -->|Yes| SETUP["�� Setup Port Forwarding"]
    
    SETUP --> TEST1{"🌐 Test Basic<br/>kubectl connectivity"}
    TEST1 -->|Fail| ERROR2["❌ kubectl Issues"]
    TEST1 -->|Pass| TEST2{"📡 Test Nginx HTTP<br/>Port 9080"}
    
    TEST2 -->|Fail| ERROR3["❌ Nginx Not Accessible"]  
    TEST2 -->|Pass| TEST3{"🔐 Test Nginx HTTPS<br/>Port 9443"}
    
    TEST3 -->|Fail| ERROR4["❌ HTTPS Certificate"]
    TEST3 -->|Pass| TEST4{"🗄️ Test MySQL<br/>Port 30306"}
    
    TEST4 -->|Fail| ERROR5["❌ Database Connection"]
    TEST4 -->|Pass| CLEANUP["🧹 Cleanup<br/>Stop Port Forwarding"]
    
    CLEANUP --> RESULTS["📋 Test Results<br/>Summary Report"]
    
    classDef start fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px,font-size:16px,font-weight:bold
    classDef test fill:#e3f2fd,stroke:#0277bd,stroke-width:2px  
    classDef error fill:#ffebee,stroke:#c62828,stroke-width:2px,font-size:16px,font-weight:bold
    
    class START,RESULTS start
    class CHECK,TEST1,TEST2,TEST3,TEST4,SETUP,CLEANUP test
    class ERROR1,ERROR2,ERROR3,ERROR4,ERROR5 error
```

## 🔧 Script Interactions

### Script Dependency Graph

```mermaid
graph TB
    subgraph "🎯 User Entry Points"
        SETUP["setup.sh<br/>Interactive Manager<br/>20KB"]
        UTILS["cluster-utils.sh<br/>CLI Utilities<br/>12KB"]
        TEST["test-cluster.sh<br/>Testing Suite<br/>5KB"]
        DEMO["demo.sh<br/>Feature Demo<br/>6KB"]
    end
    
    subgraph "📁 Configuration Files"
        KIND_CONFIG["kind-config-*.yaml<br/>Cluster Definition"]
        NGINX_CONFIGS["nginx-*.yaml<br/>Web Server"]
        MYSQL_CONFIGS["mysql-*.yaml<br/>Database"]
        HTML["helloworld.html<br/>Sample Content"]
    end
    
    subgraph "🔧 External Tools"
        KIND["kind CLI<br/>Cluster Management"]
        KUBECTL["kubectl<br/>K8s Operations"]
        DOCKER["docker<br/>Container Runtime"]
        MYSQL_CLIENT["mysql client<br/>Database Access"]
    end
    
    SETUP --> KIND_CONFIG
    SETUP --> NGINX_CONFIGS
    SETUP --> MYSQL_CONFIGS
    SETUP --> TEST
    
    UTILS --> KIND
    UTILS --> KUBECTL
    UTILS --> DOCKER
    
    TEST --> KUBECTL
    TEST --> MYSQL_CLIENT
    
    DEMO --> SETUP
    DEMO --> UTILS
    DEMO --> TEST
    
    KIND_CONFIG --> KIND
    NGINX_CONFIGS --> KUBECTL
    MYSQL_CONFIGS --> KUBECTL
    HTML --> NGINX_CONFIGS
    
    classDef script fill:#e3f2fd,stroke:#0277bd,stroke-width:2px,font-size:16px,font-weight:bold
    classDef config fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,font-size:16px,font-weight:bold
    classDef tool fill:#fff3e0,stroke:#e65100,stroke-width:2px,font-size:16px,font-weight:bold
    
    class SETUP,UTILS,TEST,DEMO script
    class KIND_CONFIG,NGINX_CONFIGS,MYSQL_CONFIGS,HTML config
    class KIND,KUBECTL,DOCKER,MYSQL_CLIENT tool
```

## 🌐 Network Architecture

### Internal Kubernetes Networking

```mermaid
graph TB
    subgraph "🖥️ Host Network"
        HOST_IP["Host: localhost<br/>Docker Bridge"]
    end
    
    subgraph "☸️ Cluster Network 172.18.0.0/16"
        subgraph "🎛️ Control Plane"
            CP_NODE["Control Plane<br/>172.18.0.2:6443"]
        end
        
        subgraph "🔧 Worker Nodes"
            W1_NODE["Worker 1<br/>172.18.0.3"]
            W2_NODE["Worker 2<br/>172.18.0.4"]
        end
        
        subgraph "🏗️ Pod Network 10.244.0.0/16"
            subgraph "🌐 Nginx Pods"
                NGINX_POD1["nginx-pod<br/>10.244.1.10:80"]
                NGINX_POD2["nginx-pod<br/>10.244.2.10:80"]
            end
            
            subgraph "🗄️ MySQL Pods"
                MYSQL_POD["mysql-pod<br/>10.244.1.20:3306"]
            end
        end
        
        subgraph "🔧 Services 10.96.0.0/12"
            NGINX_SVC["nginx-service<br/>10.96.100.10:80,443"]
            MYSQL_SVC["mysql-service<br/>10.96.200.20:3306"]
        end
    end
    
    HOST_IP --> CP_NODE
    CP_NODE --> W1_NODE
    CP_NODE --> W2_NODE
    
    NGINX_SVC --> NGINX_POD1
    NGINX_SVC --> NGINX_POD2
    MYSQL_SVC --> MYSQL_POD
    
    classDef host fill:#fff3e0,stroke:#e65100,stroke-width:2px,font-size:16px,font-weight:bold
    classDef control fill:#e1f5fe,stroke:#01579b,stroke-width:2px,font-size:16px,font-weight:bold
    classDef worker fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,font-size:16px,font-weight:bold
    classDef pod fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px,font-size:16px,font-weight:bold
    classDef service fill:#f1f8e9,stroke:#33691e,stroke-width:2px,font-size:16px,font-weight:bold
    
    class HOST_IP host
    class CP_NODE control
    class W1_NODE,W2_NODE worker
    class NGINX_POD1,NGINX_POD2,MYSQL_POD pod
    class NGINX_SVC,MYSQL_SVC service
```

## 💾 Data Flow

### MySQL Data Persistence

```mermaid
graph LR
    subgraph "🖥️ Host Machine"
        subgraph "🐳 Docker Desktop VM"
            VOLUME["💾 Docker Volume<br/>mysql-data-{cluster}"]
        end
    end
    
    subgraph "☸️ Kubernetes Cluster"
        subgraph "🗄️ MySQL Container"
            MOUNT["📂 Mount Point<br/>/var/lib/mysql"]
            
            subgraph "📄 Database Files"
                TABLES["🗄️ Tables & Data"]
                LOGS["�� Transaction Logs"]
                CONFIG["⚙️ Config Files"]
            end
        end
    end
    
    VOLUME --> MOUNT
    MOUNT --> TABLES
    MOUNT --> LOGS
    MOUNT --> CONFIG
    
    classDef host fill:#fff3e0,stroke:#e65100,stroke-width:2px,font-size:16px,font-weight:bold
    classDef volume fill:#e3f2fd,stroke:#0277bd,stroke-width:2px,font-size:16px,font-weight:bold
    classDef container fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px,font-size:16px,font-weight:bold
    classDef data fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,font-size:16px,font-weight:bold
    
    class VOLUME volume
    class MOUNT container
    class TABLES,LOGS,CONFIG data
```

## 💽 Storage Architecture

### Persistent Volume Architecture

```mermaid
graph TB
    subgraph "🖥️ Host Machine Level"
        subgraph "🐳 Docker Desktop"
            DOCKER_VOLUME["💾 Docker Volume<br/>mysql-data-{cluster-name}<br/>Type: local"]
            
            subgraph "☸️ Kubernetes Abstraction"
                PV_RESOURCE["💾 PersistentVolume (PV)<br/>Capacity: 10Gi<br/>Access: ReadWriteOnce"]
                
                PVC_RESOURCE["📋 PersistentVolumeClaim<br/>Request: 10Gi<br/>Bound to PV"]
                
                MYSQL_POD_STORAGE["🗄️ MySQL Pod<br/>Mount: /var/lib/mysql<br/>Container: mysql:8.0"]
            end
        end
    end
    
    DOCKER_VOLUME --> PV_RESOURCE
    PV_RESOURCE --> PVC_RESOURCE
    PVC_RESOURCE --> MYSQL_POD_STORAGE
    
    classDef docker fill:#e3f2fd,stroke:#0277bd,stroke-width:2px,font-size:16px,font-weight:bold
    classDef k8s fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef pod fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,font-size:16px,font-weight:bold
    
    class DOCKER_VOLUME docker
    class PV_RESOURCE,PVC_RESOURCE k8s
    class MYSQL_POD_STORAGE pod
```

## 🔒 Security Model

### Security Architecture

```mermaid
graph TB
    subgraph "🔐 Security Layers"
        subgraph "☸️ Cluster Security"
            RBAC["🔑 Kubernetes RBAC<br/>Service Accounts"]
            TLS["🔒 TLS Encryption<br/>Cluster Communication"]
            ISOLATION["🏠 Network Isolation<br/>Namespace Separation"]
        end
        
        subgraph "🚀 Application Security"
            subgraph "🌐 Nginx Security"
                SSL_CERTS["🔐 SSL Certificates<br/>Self-signed TLS"]
                HTTPS_ONLY["🔄 HTTPS Redirect<br/>Force Secure"]
            end
            
            subgraph "🗄️ MySQL Security"
                ROOT_PASS["🔑 Root Password<br/>Auto-generated"]
                APP_USER["👤 App User<br/>Limited Privileges"]
                INTERNAL_NET["🔒 Internal Access<br/>Cluster Only"]
            end
        end
        
        subgraph "🌐 Network Security"
            SERVICE_LAYER["🏠 Service Isolation<br/>Cluster Networks"]
            CONTROLLED_ACCESS["🚪 NodePort Access<br/>Defined Ports Only"]
        end
    end
    
    RBAC --> SERVICE_LAYER
    SSL_CERTS --> HTTPS_ONLY
    ROOT_PASS --> APP_USER
    TLS --> CONTROLLED_ACCESS
    
    classDef cluster fill:#e1f5fe,stroke:#01579b,stroke-width:2px,font-size:16px,font-weight:bold
    classDef nginx fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px,font-size:16px,font-weight:bold
    classDef mysql fill:#fff3e0,stroke:#e65100,stroke-width:2px,font-size:16px,font-weight:bold
    classDef network fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,font-size:16px,font-weight:bold
    
    class RBAC,TLS,ISOLATION cluster
    class SSL_CERTS,HTTPS_ONLY nginx
    class ROOT_PASS,APP_USER,INTERNAL_NET mysql
    class SERVICE_LAYER,CONTROLLED_ACCESS network
```

### Access Control Matrix

| **Component** | **Internal Access** | **External Access** | **Security** |
|---------------|-------------------|-------------------|--------------|
| **🌐 Nginx Web Server** | `nginx-service:80,443` | `localhost:9080,9443` | `HTTP/HTTPS, SSL/TLS` |
| **🗄️ MySQL Database** | `mysql-service:3306` | `localhost:30306` | `User Auth, SSL/TLS` |
| **☸️ Kubernetes API** | `internal cluster API` | `kubectl via context` | `RBAC, TLS` |
| **🛠️ Management Scripts** | `Docker socket` | `Host shell access` | `File permissions` |

---

## 📊 Summary

This architecture documentation provides a comprehensive view of the Kind Kubernetes cluster management system, featuring:

- **🏗️ Complete Infrastructure**: 1 control plane + 2 workers with persistent storage
- **🚀 Production Applications**: Nginx web server + MySQL database with SSL/TLS
- **🛠️ Management Tools**: Interactive scripts and command-line utilities
- **🔒 Security**: Multi-layer security with proper authentication and encryption
- **📊 Monitoring**: Comprehensive testing and status reporting
- **💾 Data Persistence**: Survives cluster restarts and provides recovery options

**Perfect for development, testing, and learning Kubernetes in a local environment!** 🌟
