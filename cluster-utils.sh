#!/bin/bash

# Quick cluster utility script
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to show usage
show_usage() {
    echo -e "${CYAN}Kind Cluster Quick Utilities${NC}"
    echo "============================="
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list                     - List all Kind clusters"
    echo "  status <cluster-name>    - Show detailed cluster status"
    echo "  logs <cluster-name>      - Show logs for all pods in cluster"
    echo "  shell <cluster-name>     - Get shell access to a pod"
    echo "  port-forward <cluster>   - Setup port forwarding for web access"
    echo "  quick-test <cluster>     - Run quick connectivity tests"
    echo "  stop <cluster-name>      - Stop cluster containers"
    echo "  start <cluster-name>     - Start cluster containers"
    echo "  backup <cluster-name>    - Backup cluster configurations"
    echo "  restore <backup-file>    - Restore cluster from backup"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 status web-app"
    echo "  $0 logs web-app"
    echo "  $0 port-forward web-app"
    echo "  $0 quick-test web-app"
    echo "  $0 stop web-app"
    echo "  $0 start web-app"
}

# Function to list clusters with details
list_clusters() {
    print_info "Listing all Kind clusters..."
    
    clusters=$(kind get clusters 2>/dev/null)
    if [ -z "$clusters" ]; then
        print_warning "No Kind clusters found."
        return
    fi
    
    echo ""
    echo -e "${CYAN}Cluster Name${NC}           ${CYAN}Status${NC}    ${CYAN}Nodes${NC}  ${CYAN}Context${NC}"
    echo "============================================================"
    
    echo "$clusters" | while read cluster; do
        if [ ! -z "$cluster" ]; then
            # Check if cluster containers are actually running
            running_containers=$(docker ps --filter "label=io.x-k8s.kind.cluster=$cluster" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
            total_containers=$(docker ps -a --filter "label=io.x-k8s.kind.cluster=$cluster" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
            
            # Determine status based on running containers
            if [ "$running_containers" -eq "$total_containers" ] && [ "$total_containers" -gt "0" ]; then
                status="Running"
                # Try to get node count from kubectl
                kubectl config use-context "kind-$cluster" >/dev/null 2>&1
                node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
                if [ "$node_count" -eq "0" ]; then
                    node_count="$total_containers"
                fi
            elif [ "$running_containers" -gt "0" ] && [ "$total_containers" -gt "0" ]; then
                status="Partial"
                node_count="$running_containers/$total_containers"
            elif [ "$total_containers" -gt "0" ]; then
                status="Stopped"
                node_count="$total_containers"
            else
                status="Missing"
                node_count="0"
            fi
            
            context="kind-$cluster"
            printf "%-20s %-9s %-6s %s\n" "$cluster" "$status" "$node_count" "$context"
        fi
    done
}

# Function to show cluster status
show_cluster_status() {
    local cluster_name="$1"
    
    if [ -z "$cluster_name" ]; then
        print_error "Please specify a cluster name"
        return 1
    fi
    
    print_info "Checking status of cluster: $cluster_name"
    
    # Set context
    kubectl config use-context "kind-$cluster_name" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_error "Failed to set context for cluster: $cluster_name"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}=== Cluster Nodes ===${NC}"
    kubectl get nodes -o wide
    
    echo ""
    echo -e "${CYAN}=== Pods Status ===${NC}"
    kubectl get pods -o wide
    
    echo ""
    echo -e "${CYAN}=== Services ===${NC}"
    kubectl get services
    
    echo ""
    echo -e "${CYAN}=== Resource Usage ===${NC}"
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
}

# Function to show logs
show_logs() {
    local cluster_name="$1"
    
    if [ -z "$cluster_name" ]; then
        print_error "Please specify a cluster name"
        return 1
    fi
    
    kubectl config use-context "kind-$cluster_name" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_error "Failed to set context for cluster: $cluster_name"
        return 1
    fi
    
    echo -e "${CYAN}=== MySQL Logs ===${NC}"
    kubectl logs -l app=mysql --tail=20
    
    echo ""
    echo -e "${CYAN}=== Nginx Logs ===${NC}"
    kubectl logs -l app=nginx --tail=20
}

# Function to setup port forwarding
setup_port_forward() {
    local cluster_name="$1"
    
    if [ -z "$cluster_name" ]; then
        print_error "Please specify a cluster name"
        return 1
    fi
    
    kubectl config use-context "kind-$cluster_name" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_error "Failed to set context for cluster: $cluster_name"
        return 1
    fi
    
    print_info "Setting up port forwarding for cluster: $cluster_name"
    
    # Kill existing port forwarding
    pkill -f "kubectl port-forward.*nginx-service" 2>/dev/null || true
    pkill -f "kubectl port-forward.*mysql-service" 2>/dev/null || true
    
    # Start new port forwarding
    print_info "Starting Nginx port forwarding (9080:80, 9443:443)..."
    kubectl port-forward service/nginx-service 9080:80 9443:443 >/dev/null 2>&1 &
    
    print_info "Starting MySQL port forwarding (3306:3306)..."
    kubectl port-forward service/mysql-service 3306:3306 >/dev/null 2>&1 &
    
    sleep 2
    print_success "Port forwarding active:"
    print_success "  HTTP:  http://localhost:9080"
    print_success "  HTTPS: https://localhost:9443"
    print_success "  MySQL: mysql -h 127.0.0.1 -P 3306 -u root -prootpassword123"
    print_info "Press Ctrl+C to stop port forwarding"
    
    # Wait for interrupt
    wait
}

# Function to run quick tests
quick_test() {
    local cluster_name="$1"
    
    if [ -z "$cluster_name" ]; then
        print_error "Please specify a cluster name"
        return 1
    fi
    
    kubectl config use-context "kind-$cluster_name" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_error "Failed to set context for cluster: $cluster_name"
        return 1
    fi
    
    print_info "Running quick tests for cluster: $cluster_name"
    
    # Test pods
    echo ""
    echo -e "${BLUE}[TEST]${NC} Checking pod status..."
    running_pods=$(kubectl get pods --no-headers | grep -c "Running")
    total_pods=$(kubectl get pods --no-headers | wc -l | tr -d ' ')
    
    if [ "$running_pods" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
        print_success "All $total_pods pods are running"
    else
        print_warning "$running_pods/$total_pods pods are running"
        kubectl get pods
    fi
    
    # Test services
    echo ""
    echo -e "${BLUE}[TEST]${NC} Checking services..."
    services=$(kubectl get services --no-headers | grep -v kubernetes | wc -l | tr -d ' ')
    if [ "$services" -ge 2 ]; then
        print_success "Found $services services"
    else
        print_warning "Expected at least 2 services, found $services"
    fi
}

# Function to stop cluster
stop_cluster() {
    local cluster_name="$1"
    
    if [ -z "$cluster_name" ]; then
        print_error "Please specify a cluster name"
        return 1
    fi
    
    print_info "Stopping cluster: $cluster_name"
    
    # Get all container IDs for this cluster
    containers=$(docker ps --filter "label=io.x-k8s.kind.cluster=$cluster_name" --format "{{.ID}}")
    
    if [ ! -z "$containers" ]; then
        echo "$containers" | while read container; do
            print_info "Stopping container: $container"
            docker stop "$container"
        done
        print_success "Cluster '$cluster_name' stopped"
    else
        print_warning "No running containers found for cluster: $cluster_name"
    fi
}

# Function to start cluster
start_cluster() {
    local cluster_name="$1"
    
    if [ -z "$cluster_name" ]; then
        print_error "Please specify a cluster name"
        return 1
    fi
    
    print_info "Starting cluster: $cluster_name"
    
    # Get all container IDs for this cluster (including stopped ones)
    containers=$(docker ps -a --filter "label=io.x-k8s.kind.cluster=$cluster_name" --format "{{.ID}}")
    
    if [ ! -z "$containers" ]; then
        echo "$containers" | while read container; do
            status=$(docker inspect --format='{{.State.Status}}' "$container")
            if [ "$status" = "exited" ]; then
                print_info "Starting container: $container"
                docker start "$container"
            fi
        done
        
        print_success "Cluster '$cluster_name' started"
        print_info "Waiting for cluster to be ready..."
        sleep 10
        
        # Test if cluster is responsive
        kubectl config use-context "kind-$cluster_name" >/dev/null 2>&1
        if kubectl get nodes >/dev/null 2>&1; then
            print_success "Cluster is ready"
        else
            print_warning "Cluster may still be starting up"
        fi
    else
        print_error "No containers found for cluster: $cluster_name"
    fi
}

# Function to backup cluster
backup_cluster() {
    local cluster_name="$1"
    
    if [ -z "$cluster_name" ]; then
        print_error "Please specify a cluster name"
        return 1
    fi
    
    kubectl config use-context "kind-$cluster_name" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_error "Failed to set context for cluster: $cluster_name"
        return 1
    fi
    
    local backup_dir="backup-${cluster_name}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    print_info "Creating backup for cluster: $cluster_name"
    print_info "Backup directory: $backup_dir"
    
    # Backup all resources
    kubectl get all -o yaml > "$backup_dir/all-resources.yaml"
    kubectl get configmaps -o yaml > "$backup_dir/configmaps.yaml"
    kubectl get secrets -o yaml > "$backup_dir/secrets.yaml"
    kubectl get pv,pvc -o yaml > "$backup_dir/storage.yaml"
    
    # Copy configuration files
    cp kind-config-${cluster_name}.yaml "$backup_dir/" 2>/dev/null || true
    cp *.yaml "$backup_dir/" 2>/dev/null || true
    
    # Create restore script
    cat > "$backup_dir/restore.sh" << EOF
#!/bin/bash
echo "Restoring cluster: $cluster_name"
kubectl apply -f configmaps.yaml
kubectl apply -f secrets.yaml
kubectl apply -f storage.yaml
kubectl apply -f all-resources.yaml
echo "Restore completed"
EOF
    chmod +x "$backup_dir/restore.sh"
    
    print_success "Backup created: $backup_dir"
}

# Main script logic
case "$1" in
    "list")
        list_clusters
        ;;
    "status")
        show_cluster_status "$2"
        ;;
    "logs")
        show_logs "$2"
        ;;
    "port-forward")
        setup_port_forward "$2"
        ;;
    "quick-test")
        quick_test "$2"
        ;;
    "stop")
        stop_cluster "$2"
        ;;
    "start")
        start_cluster "$2"
        ;;
    "backup")
        backup_cluster "$2"
        ;;
    "shell")
        cluster_name="$2"
        if [ -z "$cluster_name" ]; then
            print_error "Please specify a cluster name"
            exit 1
        fi
        kubectl config use-context "kind-$cluster_name" >/dev/null 2>&1
        pod=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ ! -z "$pod" ]; then
            print_info "Connecting to pod: $pod"
            kubectl exec -it "$pod" -- /bin/sh
        else
            print_error "No nginx pods found"
        fi
        ;;
    *)
        show_usage
        ;;
esac
