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

```mermaid
graph TB
    subgraph Host["🖥️ Host Machine (macOS)"]
        subgraph Docker["🐳 Docker Desktop"]
            subgraph Kind["☸️ Kind Kubernetes Cluster"]
                subgraph CP_Group["🎛️ Control Plane"]
                    CP["<b>Control Plane</b><br/><i>my-cluster-control</i>"]
                    API["<b>API Server</b><br/><i>:6443</i>"]
                    ETCD["<b>etcd</b><br/><i>:2379</i>"]
                    SCHED["<b>Scheduler</b>"]
                    CM["<b>Controller Manager</b>"]
                end
                
                subgraph W1_Group["🔧 Worker Node 1"]
                    W1["<b>Worker Node</b><br/><i>my-cluster-worker</i>"]
                    W1_KUBELET["<b>kubelet</b>"]
                    W1_RUNTIME["<b>Container Runtime</b>"]
                    W1_PROXY["<b>kube-proxy</b>"]
                end
                
                subgraph W2_Group["🔧 Worker Node 2"]
                    W2["<b>Worker Node</b><br/><i>my-cluster-worker2</i>"]
                    W2_KUBELET["<b>kubelet</b>"]
                    W2_RUNTIME["<b>Container Runtime</b>"]
                    W2_PROXY["<b>kube-proxy</b>"]
                end
                
                subgraph Apps["🚀 Application Layer"]
                    subgraph Nginx_Deploy["🌐 Nginx Deployment"]
                        NGINX_POD["<b>Nginx Pod</b><br/><i>nginx:latest</i><br/><i>Port: 80, 443</i>"]
                        NGINX_SVC["<b>nginx-service</b><br/><i>ClusterIP</i>"]
                    end
                    
                    subgraph MySQL_Deploy["🗄️ MySQL Deployment"]
                        MYSQL_POD["<b>MySQL Pod</b><br/><i>mysql:8.0</i><br/><i>Port: 3306</i>"]
                        MYSQL_SVC["<b>mysql-service</b><br/><i>ClusterIP</i>"]
                        PV["<b>Persistent Volume</b><br/><i>/var/lib/mysql</i>"]
                    end
                end
            end
        end
    end
    
    %% External Access Points
    HOST_HTTP["<b>localhost:9080</b><br/><i>HTTP Access</i>"]
    HOST_HTTPS["<b>localhost:9443</b><br/><i>HTTPS Access</i>"]
    HOST_MYSQL["<b>localhost:30306</b><br/><i>MySQL Access</i>"]
    
    %% External connections
    HOST_HTTP ==> NGINX_SVC
    HOST_HTTPS ==> NGINX_SVC
    HOST_MYSQL ==> MYSQL_SVC
    
    %% Internal connections
    NGINX_SVC --> NGINX_POD
    MYSQL_SVC --> MYSQL_POD
    MYSQL_POD --> PV
    
    %% Styling with proper font sizes
    classDef controlPlane fill:#e1f5fe,stroke:#01579b,stroke-width:3px,font-size:12px,font-weight:bold
    classDef worker fill:#f3e5f5,stroke:#4a148c,stroke-width:3px,font-size:12px,font-weight:bold
    classDef app fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    classDef external fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    classDef storage fill:#f1f8e9,stroke:#33691e,stroke-width:3px,font-size:12px,font-weight:bold
    
    class CP,API,ETCD,SCHED,CM controlPlane
    class W1,W1_KUBELET,W1_RUNTIME,W1_PROXY,W2,W2_KUBELET,W2_RUNTIME,W2_PROXY worker
    class NGINX_POD,NGINX_SVC,MYSQL_POD,MYSQL_SVC app
    class HOST_HTTP,HOST_HTTPS,HOST_MYSQL external
    class PV storage
```

### Port Mapping Architecture

```mermaid
graph LR
    subgraph Host["🖥️ Host Machine (localhost)"]
        HTTP["<b>Port 9080</b><br/><i>HTTP</i>"]
        HTTPS["<b>Port 9443</b><br/><i>HTTPS</i>"]  
        MYSQL["<b>Port 30306</b><br/><i>MySQL</i>"]
    end
    
    subgraph Cluster["☸️ Kind Cluster"]
        subgraph Services["🔧 Services"]
            NGINX_SVC["<b>nginx-service</b><br/><i>:80, :443</i>"]
            MYSQL_SVC["<b>mysql-service</b><br/><i>:3306</i>"]
        end
        
        subgraph Pods["📦 Pods"]
            NGINX_POD["<b>Nginx Pod</b><br/><i>:80, :443</i>"]
            MYSQL_POD["<b>MySQL Pod</b><br/><i>:3306</i>"]
        end
    end
    
    %% Port forwarding connections
    HTTP -.->|"<b>Port Forward</b>"| NGINX_SVC
    HTTPS -.->|"<b>Port Forward</b>"| NGINX_SVC
    MYSQL -.->|"<b>NodePort</b>"| MYSQL_SVC
    
    %% Service to Pod connections
    NGINX_SVC ==>|"<b>Routes to</b>"| NGINX_POD
    MYSQL_SVC ==>|"<b>Routes to</b>"| MYSQL_POD
    
    %% Styling with font-size 12px and bold text
    classDef host fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    classDef service fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef pod fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    
    class HTTP,HTTPS,MYSQL host
    class NGINX_SVC,MYSQL_SVC service
    class NGINX_POD,MYSQL_POD pod
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

```mermaid
flowchart TD
    START(["<b>🚀 User Starts</b><br/><i>./setup.sh</i>"]) --> MENU["<b>📋 Interactive Menu Display</b>"]
    
    MENU --> OPT1["<b>1️⃣ Create Cluster</b>"]
    MENU --> OPT2["<b>2️⃣ List Clusters</b>"]
    MENU --> OPT3["<b>3️⃣ Delete Cluster</b>"]
    
    %% Create Cluster Path
    OPT1 --> INPUT["<b>⌨️ Get Cluster Name</b><br/><i>User Input</i>"]
    INPUT --> GENERATE["<b>📝 Generate Config</b><br/><i>kind-config.yaml</i>"]
    GENERATE --> CREATE["<b>🔨 Create Cluster</b><br/><i>kind create cluster</i>"]
    CREATE --> WAIT["<b>⏳ Wait for Ready</b><br/><i>Cluster Status Check</i>"]
    WAIT --> NGINX["<b>🌐 Deploy Nginx</b><br/><i>nginx-*.yaml</i>"]
    NGINX --> MYSQL["<b>🗄️ Deploy MySQL</b><br/><i>mysql-*.yaml</i>"]
    MYSQL --> TEST["<b>🧪 Run Tests</b><br/><i>test-cluster.sh</i>"]
    TEST --> ACCESS(["<b>✅ Display Access Info</b><br/><i>URLs & Credentials</i>"])
    
    %% List Clusters Path
    OPT2 --> LIST["<b>📊 Call list_clusters()</b><br/><i>Show All Clusters</i>"]
    
    %% Delete Cluster Path
    OPT3 --> SELECT["<b>🎯 Select Cluster</b><br/><i>Choose to Delete</i>"]
    SELECT --> CONFIRM["<b>⚠️ Confirmation</b><br/><i>Safety Prompt</i>"]
    CONFIRM --> DELETE["<b>🗑️ Delete Cluster</b><br/><i>kind delete cluster</i>"]
    
    %% Styling with bold text and proper fonts
    classDef startEnd fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    classDef process fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef decision fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    classDef action fill:#f3e5f5,stroke:#4a148c,stroke-width:3px,font-size:12px,font-weight:bold
    
    class START,ACCESS startEnd
    class MENU,INPUT,GENERATE,WAIT,LIST,SELECT,CONFIRM process
    class OPT1,OPT2,OPT3 decision
    class CREATE,NGINX,MYSQL,TEST,DELETE action
```

### 2. Testing Workflow

```mermaid
flowchart TD
    START(["<b>🧪 Start Testing</b><br/><i>test-cluster.sh [cluster-name]</i>"]) --> CHECK{"<b>🔍 Cluster Exists?</b><br/><i>kubectl verification</i>"}
    
    CHECK -->|"❌ <b>No</b>"| ERROR1["<b>❌ Error</b><br/><i>Cluster Not Found</i>"]
    CHECK -->|"✅ <b>Yes</b>"| SETUP["<b>🔧 Setup Port Forwarding</b><br/><i>Background Process</i>"]
    
    SETUP --> TEST1{"<b>🌐 Test Basic</b><br/><i>kubectl connectivity</i>"}
    TEST1 -->|"❌ <b>Fail</b>"| ERROR2["<b>❌ Error</b><br/><i>kubectl Issues</i>"]
    TEST1 -->|"✅ <b>Pass</b>"| TEST2{"<b>📡 Test Nginx HTTP</b><br/><i>Port 9080</i>"}
    
    TEST2 -->|"❌ <b>Fail</b>"| ERROR3["<b>❌ Error</b><br/><i>Nginx Not Accessible</i>"]
    TEST2 -->|"✅ <b>Pass</b>"| TEST3{"<b>🔐 Test Nginx HTTPS</b><br/><i>Port 9443</i>"}
    
    TEST3 -->|"❌ <b>Fail</b>"| ERROR4["<b>❌ Error</b><br/><i>HTTPS Certificate</i>"]
    TEST3 -->|"✅ <b>Pass</b>"| TEST4{"<b>🗄️ Test MySQL Connection</b><br/><i>Port 30306</i>"}
    
    TEST4 -->|"❌ <b>Fail</b>"| ERROR5["<b>❌ Error</b><br/><i>Database Connection</i>"]
    TEST4 -->|"✅ <b>Pass</b>"| TEST5{"<b>📊 Test Data Operations</b><br/><i>CRUD Operations</i>"}
    
    TEST5 -->|"❌ <b>Fail</b>"| ERROR6["<b>❌ Error</b><br/><i>Data Integrity</i>"]
    TEST5 -->|"✅ <b>Pass</b>"| CLEANUP["<b>🧹 Cleanup</b><br/><i>Stop Port Forwarding</i>"]
    
    CLEANUP --> RESULTS(["<b>📋 Display Results</b><br/><i>Test Summary Report</i>"])
    
    %% Styling with bold fonts and proper sizing
    classDef startEnd fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    classDef process fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef decision fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    classDef error fill:#ffebee,stroke:#c62828,stroke-width:3px,font-size:12px,font-weight:bold
    
    class START,RESULTS startEnd
    class SETUP,CLEANUP process
    class CHECK,TEST1,TEST2,TEST3,TEST4,TEST5 decision
    class ERROR1,ERROR2,ERROR3,ERROR4,ERROR5,ERROR6 error
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

```mermaid
graph TB
    subgraph Scripts["📜 Management Scripts"]
        SETUP["<b>🎛️ setup.sh</b><br/><i>Interactive Manager</i>"]
        UTILS["<b>⚙️ cluster-utils.sh</b><br/><i>CLI Utilities</i>"]
        TEST["<b>🧪 test-cluster.sh</b><br/><i>Testing Suite</i>"]
        DEMO["<b>🎬 demo.sh</b><br/><i>Feature Demo</i>"]
    end
    
    subgraph ConfigFiles["📄 Configuration Files"]
        KIND_TEMPLATE["<b>📋 kind-config.yaml</b><br/><i>Template</i>"]
        KIND_GENERATED["<b>🔧 kind-config-{name}.yaml</b><br/><i>Generated</i>"]
        NGINX_FILES["<b>🌐 nginx-*.yaml</b><br/><i>Web Server</i>"]
        MYSQL_FILES["<b>🗄️ mysql-*.yaml</b><br/><i>Database</i>"]
    end
    
    subgraph ExternalTools["🔧 External Tools"]
        DOCKER["<b>🐳 Docker API</b><br/><i>Container Management</i>"]
        KUBECTL["<b>☸️ kubectl</b><br/><i>Cluster Operations</i>"]
        CURL["<b>🌐 curl</b><br/><i>HTTP Testing</i>"]
        MYSQL_CLIENT["<b>🗄️ mysql client</b><br/><i>DB Testing</i>"]
        MYSQLDUMP["<b>💾 mysqldump</b><br/><i>Backup</i>"]
        OPENSSL["<b>🔐 openssl</b><br/><i>Certificate Testing</i>"]
        KIND_CLI["<b>🎯 kind CLI</b><br/><i>Cluster Creation</i>"]
    end
    
    %% Script relationships with bold labels
    SETUP -.->|"<b>calls</b>"| TEST
    SETUP -.->|"<b>calls</b>"| UTILS
    DEMO -.->|"<b>calls</b>"| SETUP
    DEMO -.->|"<b>calls</b>"| UTILS
    DEMO -.->|"<b>calls</b>"| TEST
    
    %% File dependencies
    SETUP ==>|"<b>generates</b>"| KIND_GENERATED
    SETUP ==>|"<b>uses</b>"| KIND_TEMPLATE
    SETUP ==>|"<b>uses</b>"| NGINX_FILES
    SETUP ==>|"<b>uses</b>"| MYSQL_FILES
    
    %% External tool usage
    SETUP ==>|"<b>uses</b>"| KIND_CLI
    UTILS ==>|"<b>uses</b>"| DOCKER
    UTILS ==>|"<b>uses</b>"| KUBECTL
    UTILS ==>|"<b>uses</b>"| MYSQLDUMP
    TEST ==>|"<b>uses</b>"| KUBECTL
    TEST ==>|"<b>uses</b>"| CURL
    TEST ==>|"<b>uses</b>"| MYSQL_CLIENT
    TEST ==>|"<b>uses</b>"| OPENSSL
    
    %% Styling with bold text and proper font sizes
    classDef script fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef config fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    classDef external fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    
    class SETUP,UTILS,TEST,DEMO script
    class KIND_TEMPLATE,KIND_GENERATED,NGINX_FILES,MYSQL_FILES config
    class DOCKER,KUBECTL,CURL,MYSQL_CLIENT,MYSQLDUMP,OPENSSL,KIND_CLI external
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

```mermaid
graph TB
    subgraph KindNetwork["🌉 Kind Network Bridge (172.18.0.0/16)"]
        subgraph ControlPlane["🎛️ Control Plane Node"]
            CP["<b>🖥️ Control Plane</b><br/><i>172.18.0.2</i>"]
            API_SRV["<b>🔌 kube-apiserver</b><br/><i>:6443</i>"]
            ETCD_SRV["<b>💾 etcd</b><br/><i>:2379</i>"]
        end
        
        subgraph Worker1["🔧 Worker Node 1"]
            W1["<b>🖥️ Worker 1</b><br/><i>172.18.0.3</i>"]
            W1_KUBELET["<b>⚙️ kubelet</b>"]
            W1_PROXY["<b>🔀 kube-proxy</b>"]
        end
        
        subgraph Worker2["🔧 Worker Node 2"]
            W2["<b>🖥️ Worker 2</b><br/><i>172.18.0.4</i>"]
            W2_KUBELET["<b>⚙️ kubelet</b>"]
            W2_PROXY["<b>🔀 kube-proxy</b>"]
        end
    end
    
    subgraph ServiceNetwork["🔧 Service Network (10.96.0.0/16)"]
        NGINX_SVC["<b>🌐 nginx-service</b><br/><i>10.96.1.100</i><br/><i>:80, :443</i>"]
        MYSQL_SVC["<b>🗄️ mysql-service</b><br/><i>10.96.1.200</i><br/><i>:3306</i>"]
        K8S_SVC["<b>☸️ kubernetes</b><br/><i>10.96.0.1</i><br/><i>:443</i>"]
    end
    
    subgraph PodNetwork["📦 Pod Network (10.244.0.0/16)"]
        NGINX_POD["<b>🌐 nginx-pod</b><br/><i>10.244.1.10</i><br/><i>:80, :443</i>"]
        MYSQL_POD["<b>🗄️ mysql-pod</b><br/><i>10.244.2.10</i><br/><i>:3306</i>"]
    end
    
    %% Service to Pod connections
    NGINX_SVC -.->|"<b>routes to</b>"| NGINX_POD
    MYSQL_SVC -.->|"<b>routes to</b>"| MYSQL_POD
    
    %% Node connections
    CP -.->|"<b>manages</b>"| W1
    CP -.->|"<b>manages</b>"| W2
    
    %% Styling with bold and proper font sizes
    classDef controlPlane fill:#e1f5fe,stroke:#01579b,stroke-width:3px,font-size:12px,font-weight:bold
    classDef worker fill:#f3e5f5,stroke:#4a148c,stroke-width:3px,font-size:12px,font-weight:bold
    classDef service fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef pod fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    
    class CP,API_SRV,ETCD_SRV controlPlane
    class W1,W1_KUBELET,W1_PROXY,W2,W2_KUBELET,W2_PROXY worker
    class NGINX_SVC,MYSQL_SVC,K8S_SVC service
    class NGINX_POD,MYSQL_POD pod
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

```mermaid
graph LR
    subgraph HostMachine["🖥️ Host Machine"]
        subgraph DockerVM["🐳 Docker Desktop VM"]
            subgraph DockerVolume["💾 Docker Volume"]
                VOLUME["<b>📁 Volume Path</b><br/><i>/var/lib/docker/volumes/</i><br/><i>mysql-data-{cluster}/_data</i>"]
                
                subgraph PersistentData["💾 Persistent Data"]
                    MYSQL_SYS["<b>🗄️ mysql/</b><br/><i>system tables</i>"]
                    PERF_SCHEMA["<b>📊 performance_schema/</b><br/><i>metrics</i>"]
                    SYS_SCHEMA["<b>⚙️ sys/</b><br/><i>system views</i>"]
                    APP_DB["<b>📱 testdb/</b><br/><i>app database</i>"]
                    BINLOGS["<b>📝 binlog.*</b><br/><i>binary logs</i>"]
                end
            end
        end
    end
    
    subgraph K8sCluster["☸️ Kubernetes Cluster"]
        subgraph MySQLContainer["🗄️ MySQL Container"]
            MOUNT["<b>📂 Mount Point</b><br/><i>/var/lib/mysql</i>"]
            
            subgraph DatabaseFiles["📄 Database Files"]
                IBDATA["<b>📊 ibdata1</b><br/><i>tablespace</i>"]
                REDOLOGS["<b>📝 ib_logfile*</b><br/><i>redo logs</i>"]
                MYSQL_IBD["<b>🗄️ mysql.ibd</b><br/><i>system data</i>"]
                UNDO["<b>🔄 undo_001, undo_002</b><br/><i>undo logs</i>"]
                TESTDB["<b>📱 testdb/</b><br/><i>application DB</i>"]
                BIN_REPLICA["<b>📝 binlog.*</b><br/><i>replication</i>"]
            end
        end
    end
    
    %% Volume mounting
    VOLUME ==>|"<b>🔗 Volume Mount</b>"| MOUNT
    
    %% Data synchronization
    MYSQL_SYS -.->|"<b>sync</b>"| IBDATA
    PERF_SCHEMA -.->|"<b>sync</b>"| REDOLOGS
    SYS_SCHEMA -.->|"<b>sync</b>"| MYSQL_IBD
    APP_DB -.->|"<b>sync</b>"| TESTDB
    BINLOGS -.->|"<b>sync</b>"| BIN_REPLICA
    
    %% Styling with bold text and proper font sizes
    classDef host fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    classDef volume fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef container fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    classDef data fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,font-size:11px,font-weight:bold
    
    class VOLUME host
    class MYSQL_SYS,PERF_SCHEMA,SYS_SCHEMA,APP_DB,BINLOGS volume
    class MOUNT container
    class IBDATA,REDOLOGS,MYSQL_IBD,UNDO,TESTDB,BIN_REPLICA data
```

### Configuration Data Flow

```mermaid
graph LR
    subgraph TemplateFiles["📋 Template Files"]
        TEMPLATE["<b>📄 kind-config.yaml</b><br/><i>template</i>"]
        STATIC_NGINX["<b>🌐 nginx-*.yaml</b><br/><i>static configs</i>"]
        STATIC_MYSQL["<b>🗄️ mysql-*.yaml</b><br/><i>static configs</i>"]
    end
    
    subgraph GeneratedFiles["🔧 Generated Files"]
        GENERATED["<b>📄 kind-config-{name}.yaml</b><br/><i>cluster-specific</i>"]
        SSL_CERTS["<b>🔐 SSL Certificates</b><br/><i>nginx.crt, nginx.key</i>"]
        CONFIG_MAPS["<b>⚙️ ConfigMaps</b><br/><i>nginx-config</i>"]
        SECRETS["<b>🔒 Secrets</b><br/><i>mysql-secret</i>"]
    end
    
    subgraph Runtime["🚀 Runtime"]
        K8S_CLUSTER["<b>☸️ Kubernetes Cluster</b><br/><i>running cluster</i>"]
        NGINX_PODS["<b>🌐 Nginx Pods</b><br/><i>web server</i>"]
        MYSQL_PODS["<b>🗄️ MySQL Pods</b><br/><i>database</i>"]
        SERVICES["<b>🔧 Services</b><br/><i>networking</i>"]
    end
    
    %% Template to Generated with bold labels
    TEMPLATE ==>|"<b>🔨 generate</b>"| GENERATED
    STATIC_NGINX ==>|"<b>🔨 process</b>"| SSL_CERTS
    STATIC_NGINX ==>|"<b>🔨 process</b>"| CONFIG_MAPS
    STATIC_MYSQL ==>|"<b>🔨 process</b>"| SECRETS
    
    %% Generated to Runtime
    GENERATED ==>|"<b>🚀 apply</b>"| K8S_CLUSTER
    SSL_CERTS ==>|"<b>📂 mount</b>"| NGINX_PODS
    CONFIG_MAPS ==>|"<b>📂 mount</b>"| NGINX_PODS
    SECRETS ==>|"<b>📂 mount</b>"| MYSQL_PODS
    
    %% Runtime connections
    K8S_CLUSTER -.->|"<b>creates</b>"| SERVICES
    SERVICES -.->|"<b>routes to</b>"| NGINX_PODS
    SERVICES -.->|"<b>routes to</b>"| MYSQL_PODS
    
    %% Styling with bold text and proper font sizes
    classDef template fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    classDef generated fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef runtime fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    
    class TEMPLATE,STATIC_NGINX,STATIC_MYSQL template
    class GENERATED,SSL_CERTS,CONFIG_MAPS,SECRETS generated
    class K8S_CLUSTER,NGINX_PODS,MYSQL_PODS,SERVICES runtime
```

## 💽 Storage Architecture

### Persistent Volume Architecture

```mermaid
graph TB
    subgraph HostLevel["🖥️ Host Machine Level"]
        subgraph DockerDesktop["🐳 Docker Desktop"]
            subgraph VolumeManagement["💾 Docker Volume Management"]
                DOCKER_VOLUME["<b>📁 Docker Volume</b><br/><i>mysql-data-{cluster-name}</i><br/><i>Type: local, Driver: local</i>"]
                VOLUME_PATH["<b>📂 Volume Location</b><br/><i>/var/lib/docker/volumes/</i><br/><i>mysql-data-{cluster}/</i>"]
                
                subgraph K8sAbstraction["☸️ Kubernetes Abstraction"]
                    PV_RESOURCE["<b>💾 PersistentVolume (PV)</b><br/><i>Name: mysql-pv-{cluster}</i><br/><i>Capacity: 10Gi</i><br/><i>Access: ReadWriteOnce</i><br/><i>Policy: Retain</i>"]
                    
                    PVC_RESOURCE["<b>📋 PersistentVolumeClaim</b><br/><i>Name: mysql-pvc</i><br/><i>Request: 10Gi</i><br/><i>Access: ReadWriteOnce</i><br/><i>Bound to: mysql-pv-{cluster}</i>"]
                    
                    MYSQL_POD_STORAGE["<b>🗄️ MySQL Pod</b><br/><i>Volume Mount: /var/lib/mysql</i><br/><i>Container: mysql:8.0</i><br/><i>Bound PVC: mysql-pvc</i>"]
                end
            end
        end
    end
    
    %% Storage relationships
    DOCKER_VOLUME ==> VOLUME_PATH
    VOLUME_PATH ==> PV_RESOURCE
    PV_RESOURCE ==> PVC_RESOURCE
    PVC_RESOURCE ==> MYSQL_POD_STORAGE
    
    %% Styling with bold text and proper font sizes
    classDef host fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    classDef docker fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef k8s fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    classDef pod fill:#f3e5f5,stroke:#4a148c,stroke-width:3px,font-size:12px,font-weight:bold
    
    class DOCKER_VOLUME,VOLUME_PATH docker
    class PV_RESOURCE,PVC_RESOURCE k8s
    class MYSQL_POD_STORAGE pod
```

### Data Lifecycle Flow

```mermaid
graph LR
    subgraph Creation["🚀 Cluster Creation"]
        CREATE_PV["<b>💾 Create PV/PVC</b><br/><i>Storage Setup</i>"]
        MOUNT_VOL["<b>📂 Mount Volume</b><br/><i>Container Binding</i>"]
        INIT_DB["<b>🗄️ Initialize DB</b><br/><i>Schema & Users</i>"]
    end
    
    subgraph Operations["⚙️ Data Operations"]
        MYSQL_WRITES["<b>✍️ MySQL Writes</b><br/><i>to /var/lib/mysql</i>"]
        PERSISTENT_STORAGE["<b>💾 Persistent Storage</b><br/><i>Survives Pod Restarts</i>"]
    end
    
    subgraph Deletion["🗑️ Cluster Deletion"]
        STOP_CLUSTER["<b>⏹️ Stop Cluster</b><br/><i>Data Persists in Docker Vol</i>"]
        DATA_AVAILABLE["<b>📦 Data Available</b><br/><i>for Restart or Recovery</i>"]
    end
    
    %% Lifecycle flow
    CREATE_PV ==> MOUNT_VOL
    MOUNT_VOL ==> INIT_DB
    INIT_DB ==> MYSQL_WRITES
    MYSQL_WRITES ==> PERSISTENT_STORAGE
    PERSISTENT_STORAGE ==> STOP_CLUSTER
    STOP_CLUSTER ==> DATA_AVAILABLE
    
    %% States below each phase
    subgraph CreationState["📊 Creation State"]
        EMPTY_DB["<b>📊 Empty Database</b><br/><i>Schema Created</i><br/><i>Users Created</i><br/><i>Sample Data</i>"]
    end
    
    subgraph OperationState["📊 Operation State"]
        PERSISTENT_STATE["<b>💾 Persistent Storage</b><br/><i>Data Survives Pod Restarts</i><br/><i>Consistent State</i>"]
    end
    
    subgraph RecoveryState["📊 Recovery State"]
        RECOVERY_DATA["<b>🔄 Recovery Ready</b><br/><i>All Data Intact</i><br/><i>Ready for Restart</i>"]
    end
    
    INIT_DB -.-> EMPTY_DB
    PERSISTENT_STORAGE -.-> PERSISTENT_STATE
    DATA_AVAILABLE -.-> RECOVERY_DATA
    
    %% Styling
    classDef creation fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    classDef operation fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef deletion fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    classDef state fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,font-size:11px,font-weight:bold
    
    class CREATE_PV,MOUNT_VOL,INIT_DB creation
    class MYSQL_WRITES,PERSISTENT_STORAGE operation
    class STOP_CLUSTER,DATA_AVAILABLE deletion
    class EMPTY_DB,PERSISTENT_STATE,RECOVERY_DATA state
```

## 🔒 Security Model

### Security Architecture

```mermaid
graph TB
    subgraph SecurityLayers["🔐 Security Layers"]
        subgraph ClusterSecurity["☸️ Cluster Security"]
            RBAC["<b>🔑 Kubernetes RBAC</b><br/><i>Default Service Accounts</i>"]
            TLS_CLUSTER["<b>🔒 TLS Encryption</b><br/><i>Cluster Communication</i>"]
            NAMESPACES["<b>🏠 Network Isolation</b><br/><i>Namespace Separation</i>"]
            DOCKER_SEC["<b>🐳 Container Security</b><br/><i>Docker Runtime</i>"]
        end
        
        subgraph AppSecurity["🚀 Application Security"]
            subgraph NginxSec["🌐 Nginx Security"]
                SSL_CERTS["<b>🔐 SSL Certificates</b><br/><i>Self-signed TLS</i>"]
                HTTP_REDIRECT["<b>🔄 HTTP Redirect</b><br/><i>Force HTTPS</i>"]
                NON_ROOT["<b>👤 Non-root User</b><br/><i>Container Security</i>"]
                READ_ONLY["<b>📖 Read-only FS</b><br/><i>Except temp dirs</i>"]
            end
            
            subgraph MySQLSec["🗄️ MySQL Security"]
                ROOT_PASS["<b>🔑 Root Password</b><br/><i>Auto-generated</i>"]
                APP_USER["<b>👤 App User</b><br/><i>Limited Privileges</i>"]
                DB_ACCESS["<b>🎯 Database ACL</b><br/><i>Specific Access</i>"]
                INTERNAL_NET["<b>🔒 Internal Network</b><br/><i>Cluster Only</i>"]
                TLS_CONN["<b>🔐 Encrypted Connections</b><br/><i>SSL/TLS</i>"]
            end
        end
        
        subgraph NetworkSecurity["🌐 Network Security"]
            SERVICE_ISOLATION["<b>🏠 Service Isolation</b><br/><i>Cluster Networks</i>"]
            NODEPORT_ONLY["<b>🚪 Controlled Access</b><br/><i>Defined NodePorts</i>"]
            NO_DIRECT_ACCESS["<b>🚫 No Direct Pod Access</b><br/><i>Service Layer Required</i>"]
            DNS_COMM["<b>📡 Service DNS</b><br/><i>Inter-service Communication</i>"]
        end
    end
    
    %% Security flow connections
    RBAC -.->|"<b>secures</b>"| SERVICE_ISOLATION
    TLS_CLUSTER -.->|"<b>encrypts</b>"| DNS_COMM
    SSL_CERTS -.->|"<b>secures</b>"| HTTP_REDIRECT
    ROOT_PASS -.->|"<b>protects</b>"| DB_ACCESS
    
    %% Styling with bold text
    classDef cluster fill:#e1f5fe,stroke:#01579b,stroke-width:3px,font-size:12px,font-weight:bold
    classDef nginx fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    classDef mysql fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    classDef network fill:#f3e5f5,stroke:#4a148c,stroke-width:3px,font-size:12px,font-weight:bold
    
    class RBAC,TLS_CLUSTER,NAMESPACES,DOCKER_SEC cluster
    class SSL_CERTS,HTTP_REDIRECT,NON_ROOT,READ_ONLY nginx
    class ROOT_PASS,APP_USER,DB_ACCESS,INTERNAL_NET,TLS_CONN mysql
    class SERVICE_ISOLATION,NODEPORT_ONLY,NO_DIRECT_ACCESS,DNS_COMM network
```

### Access Control Matrix

| **Component** | **Internal Access** | **External Access** | **Security** |
|---------------|-------------------|-------------------|--------------|
| **🌐 Nginx Web Server** | `nginx-service:80,443` | `localhost:9080,9443` | `HTTP/HTTPS, SSL/TLS` |
| **🗄️ MySQL Database** | `mysql-service:3306` | `localhost:30306` | `User Auth, SSL/TLS` |
| **☸️ Kubernetes API** | `internal cluster API` | `kubectl via context` | `RBAC, TLS` |
| **🛠️ Management Scripts** | `Docker socket` | `Host shell access` | `File permissions` |

### Certificate Management Workflow

```mermaid
flowchart TD
    START(["<b>🔐 SSL Certificate Generation</b><br/><i>nginx-tls-setup.sh</i>"]) --> GENKEY["<b>🔑 Generate Private Key</b><br/><i>nginx.key (RSA 2048)</i>"]
    
    GENKEY --> CSR["<b>📝 Create Certificate Request</b><br/><i>CSR with SAN fields</i>"]
    
    CSR --> SELFSIGN["<b>✍️ Self-sign Certificate</b><br/><i>nginx.crt (Valid 365 days)</i>"]
    
    SELFSIGN --> K8S_SECRET["<b>☸️ Create Kubernetes Secret</b><br/><i>nginx-ssl-secret</i>"]
    
    K8S_SECRET --> MOUNT_POD["<b>📂 Mount in Nginx Pod</b><br/><i>/etc/ssl/certs/</i><br/><i>/etc/ssl/private/</i>"]
    
    MOUNT_POD --> ENABLE_HTTPS["<b>🔒 Enable HTTPS</b><br/><i>Nginx Configuration</i>"]
    
    %% Styling
    classDef cert fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px,font-size:12px,font-weight:bold
    classDef k8s fill:#e3f2fd,stroke:#0277bd,stroke-width:3px,font-size:12px,font-weight:bold
    classDef config fill:#fff3e0,stroke:#e65100,stroke-width:3px,font-size:12px,font-weight:bold
    
    class START,GENKEY,CSR,SELFSIGN cert
    class K8S_SECRET,MOUNT_POD k8s
    class ENABLE_HTTPS config
```

---

## 🔧 Implementation Details

### Container Resource Allocation

| **Component** | **CPU Limit** | **Memory Limit** | **Purpose** |
|---------------|---------------|------------------|-------------|
| **🎛️ Control Plane** | `200m` | `512Mi` | `Cluster Management` |
| **🔧 Worker Node 1** | `100m` | `512Mi` | `Application Hosting` |
| **🔧 Worker Node 2** | `100m` | `512Mi` | `Application Hosting` |
| **🌐 Nginx Pod** | `50m` | `64Mi` | `Web Server` |
| **🗄️ MySQL Pod** | `200m` | `512Mi` | `Database Server` |

### Performance Characteristics

- **🚀 Startup Time**: ~60-90 seconds for full cluster + applications
- **💾 Storage**: Persistent MySQL data survives cluster restarts
- **🔄 Scaling**: Supports multiple named clusters simultaneously
- **🧪 Testing**: Comprehensive health checks with detailed diagnostics
- **🔧 Management**: Full lifecycle management (create, start, stop, delete)

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
