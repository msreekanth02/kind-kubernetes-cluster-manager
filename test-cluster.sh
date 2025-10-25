#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get cluster name from command line or prompt user
CLUSTER_NAME=""
if [ ! -z "$1" ]; then
    CLUSTER_NAME="$1"
else
    clusters=$(kind get clusters 2>/dev/null)
    if [ -z "$clusters" ]; then
        echo -e "${RED}❌ No Kind clusters found.${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Available clusters:${NC}"
    echo "$clusters"
    echo ""
    echo -n "Enter cluster name to test (or press Enter for first available): "
    read input_cluster
    
    if [ -z "$input_cluster" ]; then
        CLUSTER_NAME=$(echo "$clusters" | head -n1)
    else
        CLUSTER_NAME="$input_cluster"
    fi
fi

# Set kubectl context
echo -e "${BLUE}Setting kubectl context to: kind-$CLUSTER_NAME${NC}"
kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set context for cluster: $CLUSTER_NAME${NC}"
    exit 1
fi

echo "🧪 Testing Kind Kubernetes Cluster: $CLUSTER_NAME"
echo "=================================================="

# Check if we need to set up port forwarding
echo -e "\n${BLUE}[SETUP]${NC} Setting up port forwarding for testing..."
# Kill any existing port forwarding
pkill -f "kubectl port-forward.*nginx-service" 2>/dev/null || true
pkill -f "kubectl port-forward.*mysql-service" 2>/dev/null || true

# Start port forwarding in background
kubectl port-forward service/nginx-service 9080:80 9443:443 >/dev/null 2>&1 &
NGINX_PF_PID=$!

# Wait a moment for port forwarding to establish
sleep 3

# Test Nginx HTTP
echo -e "\n${BLUE}[TEST 1]${NC} Testing Nginx HTTP (port 9080)..."
HTTP_RESPONSE=$(curl -s --max-time 10 http://localhost:9080 2>/dev/null)
if echo "$HTTP_RESPONSE" | grep -q "Hello World from Kubernetes"; then
    echo -e "${GREEN}✅ HTTP Test Passed${NC}"
else
    echo -e "${RED}❌ HTTP Test Failed${NC}"
    echo -e "${YELLOW}   Checking nginx pods...${NC}"
    kubectl get pods -l app=nginx
fi

# Test Nginx HTTPS
echo -e "\n${BLUE}[TEST 2]${NC} Testing Nginx HTTPS (port 9443)..."
HTTPS_RESPONSE=$(curl -sk --max-time 10 https://localhost:9443 2>/dev/null)
if echo "$HTTPS_RESPONSE" | grep -q "Hello World from Kubernetes"; then
    echo -e "${GREEN}✅ HTTPS Test Passed${NC}"
else
    echo -e "${RED}❌ HTTPS Test Failed${NC}"
    echo -e "${YELLOW}   Checking SSL secret...${NC}"
    kubectl get secret nginx-ssl-secret
fi

# Test MySQL Root Connection
echo -e "\n${BLUE}[TEST 3]${NC} Testing MySQL Root Connection..."
if timeout 10 mysql -h 127.0.0.1 -P 30306 -u root -prootpassword123 -e "SHOW DATABASES;" 2>/dev/null | grep -q "myapp"; then
    echo -e "${GREEN}✅ MySQL Root Connection Test Passed${NC}"
else
    echo -e "${RED}❌ MySQL Root Connection Test Failed${NC}"
    echo -e "${YELLOW}   Checking MySQL pod status...${NC}"
    kubectl get pods -l app=mysql
    echo -e "${YELLOW}   Checking MySQL logs (last 10 lines)...${NC}"
    kubectl logs -l app=mysql --tail=10
fi

# Test MySQL App User Connection
echo -e "\n${BLUE}[TEST 4]${NC} Testing MySQL App User Connection..."
USER_COUNT=$(timeout 10 mysql -h 127.0.0.1 -P 30306 -u appuser -papppassword123 myapp -e "SELECT COUNT(*) FROM users;" 2>/dev/null | tail -n1)
if [ "$USER_COUNT" = "3" ] || [ "$USER_COUNT" = "4" ]; then
    echo -e "${GREEN}✅ MySQL App User Connection Test Passed (Found $USER_COUNT users)${NC}"
else
    echo -e "${RED}❌ MySQL App User Connection Test Failed${NC}"
    echo -e "${YELLOW}   Checking app user permissions...${NC}"
    timeout 10 mysql -h 127.0.0.1 -P 30306 -u root -prootpassword123 -e "SHOW GRANTS FOR 'appuser'@'%';" 2>/dev/null || echo "   Failed to check user permissions"
fi

# Test Cluster Nodes
echo -e "\n${BLUE}[TEST 5]${NC} Testing Cluster Nodes (1 control plane + 2 workers)..."
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
WORKER_COUNT=$(kubectl get nodes --no-headers | grep -v control-plane | wc -l | tr -d ' ')
if [ "$NODE_COUNT" -eq "3" ] && [ "$WORKER_COUNT" -eq "2" ]; then
    echo -e "${GREEN}✅ Cluster Nodes Test Passed (3 nodes: 1 control-plane + 2 workers)${NC}"
else
    echo -e "${RED}❌ Cluster Nodes Test Failed (Expected: 3 nodes, Found: $NODE_COUNT)${NC}"
fi

# Test Pod Status
echo -e "\n${BLUE}[TEST 6]${NC} Testing Pod Status..."
RUNNING_PODS=$(kubectl get pods --no-headers | grep -c "Running")
if [ "$RUNNING_PODS" -ge "2" ]; then
    echo -e "${GREEN}✅ Pod Status Test Passed ($RUNNING_PODS pods running)${NC}"
else
    echo -e "${RED}❌ Pod Status Test Failed (Expected: at least 2 pods running, Found: $RUNNING_PODS)${NC}"
fi

echo -e "\n📊 ${BLUE}Cluster Summary:${NC}"
echo "================================"
kubectl get nodes
echo ""
kubectl get pods
echo ""
kubectl get services

echo -e "\n🔗 ${BLUE}Access Information:${NC}"
echo "================================"
echo "🌐 Nginx Web Server:"
echo "   - HTTP:  http://localhost:9080"
echo "   - HTTPS: https://localhost:9443"
echo ""
echo "🗄️  MySQL Database:"
echo "   - Host: 127.0.0.1"
echo "   - Port: 30306"
echo "   - Root: mysql -h 127.0.0.1 -P 30306 -u root -prootpassword123"
echo "   - App:  mysql -h 127.0.0.1 -P 30306 -u appuser -papppassword123 myapp"
echo ""
echo "🧹 Cleanup:"
echo "   kind delete cluster --name $CLUSTER_NAME"

# Cleanup port forwarding
echo -e "\n${BLUE}[CLEANUP]${NC} Stopping port forwarding..."
kill $NGINX_PF_PID 2>/dev/null || true
wait $NGINX_PF_PID 2>/dev/null || true
