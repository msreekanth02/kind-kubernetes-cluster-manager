#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Global variables
CLUSTER_NAME=""
CONFIG_FILE=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_menu() {
    echo -e "${CYAN}[MENU]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Function to get cluster name from user
get_cluster_name() {
    echo ""
    print_header "🏷️  Cluster Name Configuration"
    echo "==============================="
    
    while true; do
        echo -n "Enter cluster name (default: my-k8s-cluster): "
        read input_name
        
        if [ -z "$input_name" ]; then
            CLUSTER_NAME="my-k8s-cluster"
        else
            # Validate cluster name (alphanumeric, hyphens allowed)
            if [[ "$input_name" =~ ^[a-zA-Z0-9-]+$ ]]; then
                CLUSTER_NAME="$input_name"
            else
                print_error "Invalid cluster name. Use only alphanumeric characters and hyphens."
                continue
            fi
        fi
        
        print_success "Cluster name set to: $CLUSTER_NAME"
        break
    done
    
    # Create dynamic config file
    CONFIG_FILE="kind-config-${CLUSTER_NAME}.yaml"
    create_dynamic_config
}

# Function to create dynamic config file
create_dynamic_config() {
    print_status "Creating cluster configuration file: $CONFIG_FILE"
    
    cat > "$CONFIG_FILE" << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $CLUSTER_NAME
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 9080
    protocol: TCP
  - containerPort: 443
    hostPort: 9443
    protocol: TCP
- role: worker
  labels:
    worker-type: worker1
- role: worker
  labels:
    worker-type: worker2
EOF
    
    print_success "Configuration file created: $CONFIG_FILE"
}

# Function to show main menu
show_main_menu() {
    clear
    print_header "🚀 Kind Kubernetes Cluster Manager"
    print_header "===================================="
    echo ""
    print_menu "1. Create New Cluster"
    print_menu "2. List Existing Clusters"
    print_menu "3. Delete Cluster"
    print_menu "4. Deploy Applications to Existing Cluster"
    print_menu "5. Test Cluster & Applications"
    print_menu "6. Show Cluster Information"
    print_menu "7. Stop/Start Cluster"
    print_menu "8. Cleanup All Resources"
    print_menu "9. Exit"
    echo ""
    echo -n "Please select an option (1-9): "
}

# Function to list existing clusters
list_clusters() {
    print_header "📋 Existing Kind Clusters"
    echo "=========================="
    
    if command -v kind &> /dev/null; then
        clusters=$(kind get clusters 2>/dev/null)
        if [ -z "$clusters" ]; then
            print_warning "No Kind clusters found."
        else
            echo "$clusters"
        fi
    else
        print_error "Kind is not installed."
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to select existing cluster
select_existing_cluster() {
    clusters=$(kind get clusters 2>/dev/null)
    if [ -z "$clusters" ]; then
        print_error "No existing clusters found."
        return 1
    fi
    
    echo ""
    print_header "📋 Select Cluster"
    echo "=================="
    echo "Available clusters:"
    echo "$clusters"
    echo ""
    
    while true; do
        echo -n "Enter cluster name: "
        read selected_cluster
        
        if echo "$clusters" | grep -q "^$selected_cluster$"; then
            CLUSTER_NAME="$selected_cluster"
            print_success "Selected cluster: $CLUSTER_NAME"
            return 0
        else
            print_error "Cluster '$selected_cluster' not found. Please try again."
        fi
    done
}
# Function to delete cluster
delete_cluster() {
    if ! select_existing_cluster; then
        return
    fi
    
    echo ""
    print_warning "⚠️  This will permanently delete cluster: $CLUSTER_NAME"
    echo -n "Are you sure? (y/N): "
    read confirmation
    
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        print_status "Deleting cluster: $CLUSTER_NAME"
        kind delete cluster --name "$CLUSTER_NAME"
        
        if [ $? -eq 0 ]; then
            print_success "Cluster '$CLUSTER_NAME' deleted successfully"
            
            # Clean up config file if it exists
            config_file="kind-config-${CLUSTER_NAME}.yaml"
            if [ -f "$config_file" ]; then
                rm "$config_file"
                print_success "Removed configuration file: $config_file"
            fi
        else
            print_error "Failed to delete cluster: $CLUSTER_NAME"
        fi
    else
        print_status "Cluster deletion cancelled."
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to cleanup all resources
cleanup_all() {
    echo ""
    print_warning "⚠️  This will delete ALL Kind clusters and resources!"
    echo -n "Are you sure? (y/N): "
    read confirmation
    
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        print_status "Cleaning up all Kind clusters..."
        
        clusters=$(kind get clusters 2>/dev/null)
        if [ ! -z "$clusters" ]; then
            echo "$clusters" | while read cluster; do
                if [ ! -z "$cluster" ]; then
                    print_status "Deleting cluster: $cluster"
                    kind delete cluster --name "$cluster"
                fi
            done
        fi
        
        # Clean up all config files
        print_status "Cleaning up configuration files..."
        rm -f kind-config-*.yaml
        
        # Stop any port forwarding processes
        print_status "Stopping port forwarding processes..."
        pkill -f "kubectl port-forward" 2>/dev/null || true
        
        print_success "All cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to stop/start cluster
manage_cluster_state() {
    if ! select_existing_cluster; then
        return
    fi
    
    # Set context
    kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1
    
    echo ""
    print_header "🛑 Cluster State Management: $CLUSTER_NAME"
    echo "==========================================="
    echo ""
    print_menu "1. Stop Cluster (pause all containers)"
    print_menu "2. Start Cluster (resume all containers)"
    print_menu "3. Stop Applications Only (keep cluster running)"
    print_menu "4. Start Applications Only"
    print_menu "5. Show Current Status"
    print_menu "6. Back to Main Menu"
    echo ""
    echo -n "Please select an option (1-6): "
    read choice
    
    case $choice in
        1)
            stop_cluster
            ;;
        2)
            start_cluster
            ;;
        3)
            stop_applications
            ;;
        4)
            start_applications
            ;;
        5)
            show_cluster_status_detailed
            ;;
        6)
            return
            ;;
        *)
            print_error "Invalid option. Please select 1-6."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to stop cluster (pause Docker containers)
stop_cluster() {
    print_warning "⚠️  This will stop all Docker containers for cluster: $CLUSTER_NAME"
    echo -n "Are you sure? (y/N): "
    read confirmation
    
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        print_status "Stopping cluster containers: $CLUSTER_NAME"
        
        # Get all container IDs for this cluster
        containers=$(docker ps --filter "label=io.x-k8s.kind.cluster=$CLUSTER_NAME" --format "{{.ID}}")
        
        if [ ! -z "$containers" ]; then
            echo "$containers" | while read container; do
                print_status "Stopping container: $container"
                docker stop "$container"
            done
            print_success "Cluster '$CLUSTER_NAME' containers stopped"
        else
            print_warning "No running containers found for cluster: $CLUSTER_NAME"
        fi
    else
        print_status "Cluster stop cancelled."
    fi
}

# Function to start cluster (resume Docker containers)
start_cluster() {
    print_status "Starting cluster containers: $CLUSTER_NAME"
    
    # Get all container IDs for this cluster (including stopped ones)
    containers=$(docker ps -a --filter "label=io.x-k8s.kind.cluster=$CLUSTER_NAME" --format "{{.ID}}")
    
    if [ ! -z "$containers" ]; then
        echo "$containers" | while read container; do
            status=$(docker inspect --format='{{.State.Status}}' "$container")
            if [ "$status" = "exited" ]; then
                print_status "Starting container: $container"
                docker start "$container"
            else
                print_status "Container $container is already running"
            fi
        done
        
        # Wait for cluster to be ready
        print_status "Waiting for cluster to be ready..."
        sleep 10
        
        # Test cluster connectivity
        max_attempts=30
        attempt=0
        while [ $attempt -lt $max_attempts ]; do
            if kubectl get nodes >/dev/null 2>&1; then
                print_success "Cluster '$CLUSTER_NAME' is ready"
                return
            fi
            attempt=$((attempt + 1))
            echo -n "."
            sleep 2
        done
        
        print_warning "Cluster may still be starting up. Check with: kubectl get nodes"
    else
        print_error "No containers found for cluster: $CLUSTER_NAME"
    fi
}

# Function to stop applications only
stop_applications() {
    print_warning "⚠️  This will stop Nginx and MySQL applications in cluster: $CLUSTER_NAME"
    echo -n "Are you sure? (y/N): "
    read confirmation
    
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        print_status "Stopping applications in cluster: $CLUSTER_NAME"
        
        # Scale down deployments
        kubectl scale deployment nginx-deployment --replicas=0
        kubectl scale deployment mysql-deployment --replicas=0
        
        print_success "Applications stopped. Cluster infrastructure remains running."
        print_status "To restart: kubectl scale deployment nginx-deployment --replicas=2"
        print_status "To restart: kubectl scale deployment mysql-deployment --replicas=1"
    else
        print_status "Application stop cancelled."
    fi
}

# Function to start applications only
start_applications() {
    print_status "Starting applications in cluster: $CLUSTER_NAME"
    
    # Scale up deployments
    kubectl scale deployment nginx-deployment --replicas=2
    kubectl scale deployment mysql-deployment --replicas=1
    
    print_status "Waiting for applications to start..."
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=nginx --timeout=120s 2>/dev/null || print_warning "Nginx pods may still be starting"
    kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s 2>/dev/null || print_warning "MySQL pod may still be starting"
    
    print_success "Applications started successfully"
}

# Function to show detailed cluster status
show_cluster_status_detailed() {
    print_status "Cluster Status for: $CLUSTER_NAME"
    echo ""
    
    # Docker container status
    echo -e "${CYAN}=== Docker Containers ===${NC}"
    docker ps -a --filter "label=io.x-k8s.kind.cluster=$CLUSTER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo -e "${CYAN}=== Kubernetes Status ===${NC}"
    kubectl get nodes
    
    echo ""
    kubectl get pods -o wide
    
    echo ""
    kubectl get services
}
show_cluster_info() {
    if ! select_existing_cluster; then
        return
    fi
    
    print_header "📊 Cluster Information: $CLUSTER_NAME"
    echo "======================================="
    
    # Set context
    kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1
    
    echo ""
    print_status "Cluster Nodes:"
    kubectl get nodes -o wide 2>/dev/null || print_error "Failed to get nodes"
    
    echo ""
    print_status "Running Pods:"
    kubectl get pods -o wide 2>/dev/null || print_error "Failed to get pods"
    
    echo ""
    print_status "Services:"
    kubectl get services 2>/dev/null || print_error "Failed to get services"
    
    echo ""
    print_status "Persistent Volumes:"
    kubectl get pv 2>/dev/null || print_error "No persistent volumes found"
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to check if kind is installed
check_kind() {
    if ! command -v kind &> /dev/null; then
        print_error "Kind is not installed. Installing Kind..."
        # Install kind on macOS
        [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
        [ $(uname -m) = arm64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-arm64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
        print_success "Kind installed successfully"
    else
        print_success "Kind is already installed"
    fi
}

# Function to check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/kubectl
        print_success "kubectl installed successfully"
    else
        print_success "kubectl is already installed"
    fi
}

# Function to create kind cluster
create_cluster() {
    print_status "Creating Kind cluster: $CLUSTER_NAME with 1 control plane + 2 worker nodes..."
    
    # Delete existing cluster if it exists
    if kind get clusters 2>/dev/null | grep -q "^$CLUSTER_NAME$"; then
        print_warning "Cluster '$CLUSTER_NAME' already exists. Deleting it..."
        kind delete cluster --name "$CLUSTER_NAME"
    fi
    
    # Create new cluster
    kind create cluster --config="$CONFIG_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Kind cluster '$CLUSTER_NAME' created successfully"
        
        # Set kubectl context
        kubectl config use-context "kind-$CLUSTER_NAME"
        print_success "kubectl context set to kind-$CLUSTER_NAME"
    else
        print_error "Failed to create Kind cluster: $CLUSTER_NAME"
        return 1
    fi
}

# Function to generate SSL certificates for nginx
generate_ssl_certs() {
    print_status "Generating SSL certificates for Nginx..."
    
    # Create temporary directory for certificates
    mkdir -p /tmp/nginx-ssl
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /tmp/nginx-ssl/nginx.key \
        -out /tmp/nginx-ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    
    # Create Kubernetes secret from certificates
    kubectl create secret tls nginx-ssl-secret \
        --key=/tmp/nginx-ssl/nginx.key \
        --cert=/tmp/nginx-ssl/nginx.crt
    
    # Clean up temporary files
    rm -rf /tmp/nginx-ssl
    
    print_success "SSL certificates created and secret deployed"
}

# Function to deploy applications
deploy_applications() {
    print_status "Deploying applications to cluster: $CLUSTER_NAME"
    
    # Ensure we're using the right context
    kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1
    
    # Apply configurations in order
    print_status "Deploying MySQL components..."
    kubectl apply -f mysql-secret.yaml
    kubectl apply -f mysql-configmap.yaml
    kubectl apply -f mysql-storage.yaml
    kubectl apply -f mysql-deployment.yaml
    
    print_status "Deploying Nginx components..."
    kubectl apply -f nginx-configmap.yaml
    kubectl apply -f nginx-deployment.yaml
    
    print_success "Applications deployed successfully to cluster: $CLUSTER_NAME"
}

# Function to wait for pods to be ready
wait_for_pods() {
    print_status "Waiting for pods to be ready..."
    
    # Wait for MySQL pod
    print_status "Waiting for MySQL pod..."
    kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s
    
    # Wait for Nginx pods
    print_status "Waiting for Nginx pods..."
    kubectl wait --for=condition=ready pod -l app=nginx --timeout=300s
    
    print_success "All pods are ready"
}

# Function to display connection information
display_info() {
    echo ""
    echo "=========================================="
    echo "🎉 Cluster Setup Complete!"
    echo "=========================================="
    echo ""
    
    print_success "Cluster Name: $CLUSTER_NAME"
    echo ""
    
    print_success "Nginx Web Server:"
    echo "  - HTTP:  http://localhost:9080"
    echo "  - HTTPS: https://localhost:9443"
    echo ""
    
    print_success "MySQL Database:"
    echo "  - Host: localhost"
    echo "  - Port: 30306"
    echo "  - Root User: root"
    echo "  - Root Password: rootpassword123"
    echo "  - App User: appuser"
    echo "  - App Password: apppassword123"
    echo "  - Database: myapp"
    echo ""
    
    print_success "Connection Examples:"
    echo "  MySQL Root: mysql -h 127.0.0.1 -P 30306 -u root -prootpassword123"
    echo "  MySQL App:  mysql -h 127.0.0.1 -P 30306 -u appuser -papppassword123 myapp"
    echo ""
    
    print_success "Useful Commands:"
    echo "  kubectl get pods                    # View pod status"
    echo "  kubectl get services               # View services"
    echo "  kubectl logs -f <pod-name>         # View pod logs"
    echo "  kind delete cluster --name $CLUSTER_NAME  # Delete this cluster"
    echo ""
}

# Function to create complete cluster with applications
create_complete_cluster() {
    get_cluster_name
    
    print_header "🚀 Creating Complete Cluster Setup"
    echo "===================================="
    
    check_kind
    check_kubectl
    create_cluster
    
    if [ $? -eq 0 ]; then
        generate_ssl_certs
        deploy_applications
        wait_for_pods
        display_info
        
        print_success "Setup completed successfully! 🎉"
    else
        print_error "Cluster creation failed!"
        return 1
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to deploy to existing cluster
deploy_to_existing() {
    if ! select_existing_cluster; then
        return
    fi
    
    print_header "📦 Deploying Applications to: $CLUSTER_NAME"
    echo "============================================="
    
    # Set context
    kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1
    
    generate_ssl_certs
    deploy_applications
    wait_for_pods
    display_info
    
    print_success "Applications deployed successfully! 🎉"
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to run tests
run_tests() {
    if ! select_existing_cluster; then
        return
    fi
    
    # Set context
    kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1
    
    print_header "🧪 Testing Cluster: $CLUSTER_NAME"
    echo "=================================="
    
    if [ -f "test-cluster.sh" ]; then
        # Update test script to use current cluster
        sed -i.bak "s/kind delete cluster --name [a-zA-Z0-9-]*/kind delete cluster --name $CLUSTER_NAME/" test-cluster.sh
        ./test-cluster.sh
    else
        print_error "test-cluster.sh not found!"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main execution function
main() {
    while true; do
        show_main_menu
        read choice
        
        case $choice in
            1)
                create_complete_cluster
                ;;
            2)
                list_clusters
                ;;
            3)
                delete_cluster
                ;;
            4)
                deploy_to_existing
                ;;
            5)
                run_tests
                ;;
            6)
                show_cluster_info
                ;;
            7)
                manage_cluster_state
                ;;
            8)
                cleanup_all
                ;;
            9)
                print_success "Goodbye! 👋"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-9."
                sleep 1
                ;;
        esac
    done
}

# Run main function
main
