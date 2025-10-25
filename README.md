# 🚀 Kind Kubernetes Cluster Manager

A complete, interactive Kubernetes development environment using Kind (Kubernetes in Docker) with automated setup, testing, and management capabilities.

## 📋 Table of Contents

- [What This Project Does](#what-this-project-does)
- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
- [Architecture Overview](#architecture-overview)
- [How to Use](#how-to-use)
- [Understanding the Scripts](#understanding-the-scripts)
- [Testing Your Setup](#testing-your-setup)
- [Troubleshooting](#troubleshooting)
- [For Beginners](#for-beginners)

## 🎯 What This Project Does

This project creates a **complete Kubernetes development environment** on your Mac with:

### 🏗️ **Infrastructure**
- **1 Control Plane node** (manages the cluster)
- **2 Worker nodes** (run your applications)
- **Persistent storage** for data that survives restarts

### 🌐 **Web Application**
- **Nginx web server** serving a Hello World page
- **HTTP access** (port 9080) and **HTTPS access** (port 9443)
- **SSL certificates** automatically generated

### 🗄️ **Database**
- **MySQL 8.0 database** with persistent storage
- **Root user** access for administration
- **Application user** with limited permissions
- **Sample data** pre-loaded for testing

### 🛠️ **Management Tools**
- **Interactive menus** for easy cluster management
- **Automated testing** to verify everything works
- **Start/stop clusters** without losing data
- **Multiple cluster support** with custom names

## 💻 System Requirements

### **Hardware Requirements**
- **Memory**: Minimum 8GB RAM (16GB recommended)
- **CPU**: 2+ cores (4+ cores recommended)
- **Storage**: 10GB free disk space
- **Architecture**: Intel (x86_64) or Apple Silicon (arm64)

### **Software Requirements**

#### **Required (Automatically Installed)**
- **Docker Desktop** - Runs Kubernetes containers
- **Kind** - Creates Kubernetes clusters in Docker
- **kubectl** - Command-line tool for Kubernetes

#### **Pre-installed on macOS**
- **Bash** - Shell for running scripts
- **curl** - For downloading tools and testing web services
- **openssl** - For generating SSL certificates

#### **Optional (For Database Access)**
- **MySQL Client** - To connect directly to the database
  ```bash
  brew install mysql-client
  ```

### **macOS Compatibility**
- **macOS 11 (Big Sur)** or later
- **Tested on**: macOS Monterey, Ventura, Sonoma, Sequoia

## ⚡ Quick Start

### 1. **Prepare Your Mac**
```bash
# 1. Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop/

# 2. Start Docker Desktop and ensure it's running
# Look for the Docker whale icon in your menu bar

# 3. Clone or download this project
cd /path/to/your/projects
```

### 2. **Create Your First Cluster**
```bash
# Make scripts executable
chmod +x *.sh

# Run the interactive setup
./setup.sh
```

**Choose option 1** from the menu and enter a cluster name (e.g., "my-first-cluster")

### 3. **Test Everything Works**
```bash
# Test your cluster
./test-cluster.sh my-first-cluster

# Check cluster status
./cluster-utils.sh list
```

### 4. **Access Your Applications**
- **Web Server**: http://localhost:9080
- **MySQL Database**: Connect using the credentials shown in test results

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Your Mac                             │
├─────────────────────────────────────────────────────────────┤
│                    Docker Desktop                           │
├─────────────────────────────────────────────────────────────┤
│                  Kind Kubernetes Cluster                    │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ Control Plane   │  │   Worker Node   │  │ Worker Node  │ │
│  │   (Manager)     │  │      #1         │  │     #2       │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 Applications                            │ │
│  │  ┌─────────────┐              ┌─────────────────────┐   │ │
│  │  │   Nginx     │              │      MySQL          │   │ │
│  │  │ Web Server  │              │     Database        │   │ │
│  │  │             │              │                     │   │ │
│  │  │ Port: 80    │              │ Port: 3306          │   │ │
│  │  │ Port: 443   │              │ Persistent Storage  │   │ │
│  │  └─────────────┘              └─────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
             │                              │
             ▼                              ▼
    http://localhost:9080         mysql://localhost:30306
    https://localhost:9443
```

For detailed architecture and workflow diagrams, see [ARCHITECTURE.md](ARCHITECTURE.md).

## 🎮 How to Use

### **Interactive Management (Recommended for Beginners)**

```bash
./setup.sh
```

**Menu Options:**
1. **Create New Cluster** - Set up a complete new environment
2. **List Existing Clusters** - See all your clusters
3. **Delete Cluster** - Remove a cluster safely
4. **Deploy Applications** - Add apps to existing cluster
5. **Test Cluster** - Verify everything works
6. **Show Information** - Get detailed cluster status
7. **Stop/Start Cluster** - Pause/resume without data loss
8. **Cleanup All** - Remove everything (use carefully!)

### **Command Line (For Advanced Users)**

```bash
# Cluster management
./cluster-utils.sh list                    # Show all clusters
./cluster-utils.sh start my-cluster        # Start a cluster
./cluster-utils.sh stop my-cluster         # Stop a cluster
./cluster-utils.sh status my-cluster       # Detailed status

# Testing and monitoring
./test-cluster.sh my-cluster               # Comprehensive tests
./cluster-utils.sh quick-test my-cluster   # Fast connectivity check
./cluster-utils.sh logs my-cluster         # View application logs

# Development tools
./cluster-utils.sh port-forward my-cluster # Setup local access
./cluster-utils.sh shell my-cluster        # Get shell in container
./cluster-utils.sh backup my-cluster       # Backup configuration
```

## 📜 Understanding the Scripts

### **setup.sh** - Main Controller
- **Purpose**: Interactive cluster management
- **Best for**: Creating, deleting, and major operations
- **Safety**: Built-in confirmations for destructive actions

### **cluster-utils.sh** - Daily Operations
- **Purpose**: Quick command-line utilities
- **Best for**: Start/stop, status checks, monitoring
- **Features**: Works with multiple clusters simultaneously

### **test-cluster.sh** - Validation Tool
- **Purpose**: Comprehensive testing and diagnostics
- **Tests**: HTTP/HTTPS connectivity, database access, cluster health
- **Output**: Detailed reports with troubleshooting information

### **demo.sh** - Learning Tool
- **Purpose**: Interactive demonstration of features
- **Usage**: `./demo.sh --demo`
- **Best for**: Understanding capabilities before using

## 🧪 Testing Your Setup

### **Automatic Testing**
```bash
# Complete test suite
./test-cluster.sh my-cluster
```

**What gets tested:**
- ✅ Cluster nodes are healthy (1 control plane + 2 workers)
- ✅ Nginx web server responds on HTTP and HTTPS
- ✅ MySQL database accepts connections
- ✅ Application user can access sample data
- ✅ All pods are running correctly

### **Manual Testing**
```bash
# Test web server
curl http://localhost:9080
curl -k https://localhost:9443

# Test database (requires mysql client)
mysql -h 127.0.0.1 -P 30306 -u root -prootpassword123
```

### **Understanding Test Results**

**✅ Green = Success** - Everything working correctly
**❌ Red = Failed** - Issue found, check diagnostic information
**🔍 Yellow = Diagnostic** - Additional information to help debug

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **"Port already in use" errors**
```bash
# Check what's using the ports
./cluster-utils.sh list
./cluster-utils.sh stop conflicting-cluster-name
```

#### **"No clusters found" error**
```bash
# Create your first cluster
./setup.sh
# Choose option 1: Create New Cluster
```

#### **MySQL connection fails**
```bash
# Check if MySQL pod is ready
kubectl get pods -l app=mysql

# View MySQL logs for errors
./cluster-utils.sh logs your-cluster-name
```

#### **Tests fail after cluster restart**
```bash
# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all --timeout=300s

# Run tests again
./test-cluster.sh your-cluster-name
```

#### **Docker-related issues**
```bash
# Restart Docker Desktop
# Check Docker is running: docker version

# Clean up if needed
docker system prune -f
```

### **Getting Help**

1. **Check cluster status**: `./cluster-utils.sh status cluster-name`
2. **View logs**: `./cluster-utils.sh logs cluster-name`
3. **Run diagnostics**: `./test-cluster.sh cluster-name`
4. **Start fresh**: Delete and recreate the cluster

## 👶 For Beginners

### **What is Kubernetes?**
Kubernetes is like a **smart manager** for running applications. Instead of manually starting programs on your computer, Kubernetes:
- **Automatically starts** your applications
- **Restarts them** if they crash
- **Distributes work** across multiple computers
- **Manages networking** between applications

### **What is Kind?**
Kind lets you run Kubernetes **on your laptop** using Docker containers instead of separate physical computers. It's perfect for:
- **Learning** Kubernetes concepts
- **Developing** applications locally
- **Testing** before deploying to production

### **Understanding the Components**

#### **Control Plane** (The Manager)
- Decides where to run applications
- Monitors health of everything
- Handles API requests

#### **Worker Nodes** (The Workers)
- Actually run your applications
- Report status back to control plane
- Can be added or removed as needed

#### **Pods** (Application Containers)
- Smallest deployable units
- Usually contain one application
- Can be replicated for high availability

#### **Services** (Network Access)
- Provide stable network addresses
- Load balance between multiple pods
- Enable external access to applications

### **Your Learning Path**

1. **Start Here**: Use `./setup.sh` to create your first cluster
2. **Explore**: Run `./test-cluster.sh` to see what got created
3. **Experiment**: Stop and start clusters with `./cluster-utils.sh`
4. **Learn**: Try the demo with `./demo.sh --demo`
5. **Practice**: Create multiple clusters with different names

### **Key Concepts Made Simple**

- **Cluster** = Your entire Kubernetes environment
- **Node** = A computer (or container) in your cluster
- **Pod** = A running application
- **Service** = A way to access your application
- **Deployment** = Instructions for running multiple copies of an app

### **What You've Built**

After running this project, you have:
- A **real Kubernetes cluster** (just like production!)
- A **web application** you can access in your browser
- A **database** for storing information
- **Tools** to manage everything easily
- **Skills** to start building your own applications

---

## 📞 Quick Reference

### **Essential Commands**
```bash
# Interactive management
./setup.sh

# Check all clusters
./cluster-utils.sh list

# Test a cluster
./test-cluster.sh cluster-name

# Get help with any script
./script-name.sh --help
```

### **Access Information**
- **Web Server**: http://localhost:9080 (HTTP) or https://localhost:9443 (HTTPS)
- **Database**: `mysql -h 127.0.0.1 -P 30306 -u root -prootpassword123`
- **Kubernetes Dashboard**: `kubectl proxy` (if needed)

### **Emergency Commands**
```bash
# Stop everything
./cluster-utils.sh list | grep Running | awk '{print $1}' | xargs -I {} ./cluster-utils.sh stop {}

# Delete everything (careful!)
./setup.sh
# Choose option 8: Cleanup All Resources
```

---

**🎉 Congratulations! You now have a professional Kubernetes development environment running on your Mac!**

*This setup is perfect for learning, development, and testing. When you're ready for production, the concepts and configurations transfer directly to cloud Kubernetes services like EKS, GKE, or AKS.*

## 📋 Menu Options Explained

### 1. Create New Cluster
- Interactive cluster name input
- Automatic dependency installation (Kind, kubectl)
- Dynamic configuration generation
- SSL certificate setup
- Complete application deployment
- Real-time progress monitoring

### 2. List Existing Clusters
- Display all Kind clusters
- Quick overview of cluster status

### 3. Delete Cluster
- Select cluster from available list
- Safety confirmation prompts
- Complete resource cleanup
- Configuration file removal

### 4. Deploy Applications to Existing Cluster
- Deploy to any existing cluster
- Context switching
- SSL certificate generation
- Application deployment and validation

### 5. Test Cluster & Applications
- Comprehensive connectivity tests
- HTTP/HTTPS validation
- MySQL connection testing
- Node and pod status verification
- Performance and health checks

### 6. Show Cluster Information
- Detailed cluster overview
- Node status and specifications
- Pod deployment information
- Service configurations
- Persistent volume status

### 7. Cleanup All Resources
- Remove ALL Kind clusters
- Clean configuration files
- Stop port forwarding processes
- Complete environment reset

### 8. Exit
- Safe script termination

## Access Information

### Nginx Web Server
- **HTTP**: http://localhost:9080
- **HTTPS**: https://localhost:9443

### MySQL Database

#### Root User Access
```bash
mysql -h 127.0.0.1 -P 30306 -u root -prootpassword123
```

#### Application User Access
```bash
mysql -h 127.0.0.1 -P 30306 -u appuser -papppassword123 myapp
```

#### Connection Details
- **Host**: localhost (127.0.0.1)
- **Port**: 30306
- **Root User**: root
- **Root Password**: rootpassword123
- **App User**: appuser  
- **App Password**: apppassword123
- **Database**: myapp

## File Structure

```
mysql-k8s-clus/
├── kind-config.yaml          # Kind cluster configuration
├── helloworld.html          # Static HTML file
├── nginx-configmap.yaml     # Nginx configuration
├── nginx-deployment.yaml    # Nginx deployment and service
├── mysql-secret.yaml        # MySQL passwords (base64 encoded)
├── mysql-configmap.yaml     # MySQL initialization script
├── mysql-storage.yaml       # Persistent volume for MySQL
├── mysql-deployment.yaml    # MySQL deployment and service
├── setup.sh                 # Automated setup script
└── README.md               # This file
```

## Testing the Setup

### 1. Test Nginx Web Server
```bash
curl http://localhost:9080
curl -k https://localhost:9443
```

### 2. Test MySQL Connectivity
```bash
# Test root connection
mysql -h 127.0.0.1 -P 30306 -u root -prootpassword123 -e "SHOW DATABASES;"

# Test app user connection
mysql -h 127.0.0.1 -P 30306 -u appuser -papppassword123 myapp -e "SELECT * FROM users;"
```

### 3. View Cluster Status
```bash
kubectl get pods
kubectl get services
kubectl get nodes
```

## Troubleshooting

### Check Pod Logs
```bash
kubectl logs -l app=nginx
kubectl logs -l app=mysql
```

### Check Pod Status
```bash
kubectl describe pod <pod-name>
```

### Port Forward (Alternative Access)
```bash
# Forward Nginx
kubectl port-forward service/nginx-service 8080:80

# Forward MySQL
kubectl port-forward service/mysql-service 3306:3306
```

### Restart Deployments
```bash
kubectl rollout restart deployment nginx-deployment
kubectl rollout restart deployment mysql-deployment
```

## Cleanup

To delete the entire cluster:
```bash
kind delete cluster --name my-k8s-cluster
```

## Security Notes

- This setup uses self-signed SSL certificates for demonstration
- Passwords are stored in Kubernetes secrets (base64 encoded)
- For production use, consider:
  - Using proper SSL certificates
  - Implementing network policies
  - Using external secret management
  - Setting up proper RBAC

## Features

### Nginx
- ✅ Serves on both HTTP (80) and HTTPS (443)
- ✅ Self-signed SSL certificate
- ✅ Health check endpoints
- ✅ Custom HTML content
- ✅ ConfigMap for configuration
- ✅ Resource limits and requests

### MySQL
- ✅ Persistent storage
- ✅ Root user access
- ✅ Custom application user
- ✅ Pre-initialized database with sample data
- ✅ Health checks (liveness and readiness probes)
- ✅ Resource limits and requests

### Kind Cluster
- ✅ 1 Control plane + 2 worker nodes
- ✅ Port mapping for direct access from host
- ✅ Proper labels for worker nodes
- ✅ NodePort services for external access
