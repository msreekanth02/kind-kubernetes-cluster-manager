#!/bin/bash

# 🎬 Kind Kubernetes Cluster Manager - Live Demo Script
# This script demonstrates all the key features of our enhanced cluster management system

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_demo_header() {
    clear
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}🎬 LIVE DEMO: $1${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}[STEP $1]${NC} $2"
    echo -e "${YELLOW}Command: $3${NC}"
    echo ""
}

pause_demo() {
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read
}

# Demo 1: Cluster Status Detection
demo_status_detection() {
    print_demo_header "Accurate Cluster Status Detection"
    
    print_step "1" "Show all clusters with accurate status" "./cluster-utils.sh list"
    ./cluster-utils.sh list
    pause_demo
    
    print_step "2" "Start a cluster to see status change" "./cluster-utils.sh start web-app"
    ./cluster-utils.sh start web-app
    pause_demo
    
    print_step "3" "Verify status changed to Running" "./cluster-utils.sh list"
    ./cluster-utils.sh list
    pause_demo
    
    print_step "4" "Stop the cluster" "./cluster-utils.sh stop web-app"
    ./cluster-utils.sh stop web-app
    pause_demo
    
    print_step "5" "Confirm status shows as Stopped" "./cluster-utils.sh list"
    ./cluster-utils.sh list
    pause_demo
}

# Demo 2: Comprehensive Testing
demo_testing() {
    print_demo_header "Comprehensive Cluster Testing"
    
    print_step "1" "Start cluster for testing" "./cluster-utils.sh start web-app"
    ./cluster-utils.sh start web-app
    pause_demo
    
    print_step "2" "Run comprehensive tests with diagnostics" "./test-cluster.sh web-app"
    ./test-cluster.sh web-app
    pause_demo
}

# Demo 3: Quick Utilities
demo_utilities() {
    print_demo_header "Quick Cluster Utilities"
    
    print_step "1" "Show detailed cluster status" "./cluster-utils.sh status web-app"
    ./cluster-utils.sh status web-app
    pause_demo
    
    print_step "2" "View application logs" "./cluster-utils.sh logs web-app"
    ./cluster-utils.sh logs web-app
    pause_demo
    
    print_step "3" "Run quick connectivity tests" "./cluster-utils.sh quick-test web-app"
    ./cluster-utils.sh quick-test web-app
    pause_demo
}

# Demo 4: Interactive Management
demo_interactive() {
    print_demo_header "Interactive Cluster Management"
    
    echo -e "${CYAN}The setup.sh script provides a menu-driven interface:${NC}"
    echo ""
    echo "🚀 Kind Kubernetes Cluster Manager"
    echo "===================================="
    echo ""
    echo "[MENU] 1. Create New Cluster"
    echo "[MENU] 2. List Existing Clusters"
    echo "[MENU] 3. Delete Cluster"
    echo "[MENU] 4. Deploy Applications to Existing Cluster"
    echo "[MENU] 5. Test Cluster & Applications"
    echo "[MENU] 6. Show Cluster Information"
    echo "[MENU] 7. Stop/Start Cluster"
    echo "[MENU] 8. Cleanup All Resources"
    echo "[MENU] 9. Exit"
    echo ""
    echo -e "${YELLOW}To try: ./setup.sh${NC}"
    pause_demo
}

# Main demo menu
show_demo_menu() {
    clear
    echo -e "${PURPLE}🎬 Kind Kubernetes Cluster Manager - Live Demo${NC}"
    echo -e "${PURPLE}==============================================${NC}"
    echo ""
    echo -e "${CYAN}Choose a demo:${NC}"
    echo "1. 📊 Accurate Status Detection (Fixed Issue)"
    echo "2. 🧪 Comprehensive Testing Suite"
    echo "3. ⚡ Quick Utility Commands"
    echo "4. 🎛️ Interactive Management Interface"
    echo "5. 🎯 Run All Demos"
    echo "6. Exit"
    echo ""
    echo -n "Select demo (1-6): "
}

# Main demo execution
main_demo() {
    while true; do
        show_demo_menu
        read choice
        
        case $choice in
            1)
                demo_status_detection
                ;;
            2)
                demo_testing
                ;;
            3)
                demo_utilities
                ;;
            4)
                demo_interactive
                ;;
            5)
                demo_status_detection
                demo_testing
                demo_utilities
                demo_interactive
                ;;
            6)
                echo -e "${GREEN}Demo completed! 🎉${NC}"
                echo ""
                echo -e "${CYAN}Your Kind Kubernetes cluster management system is ready!${NC}"
                echo ""
                echo -e "${YELLOW}Quick reference:${NC}"
                echo "  ./setup.sh                    # Interactive management"
                echo "  ./cluster-utils.sh list      # Show all clusters"
                echo "  ./cluster-utils.sh stop web-app   # Stop cluster"
                echo "  ./cluster-utils.sh start web-app  # Start cluster"
                echo "  ./test-cluster.sh web-app    # Test cluster"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-6.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check if running in demo mode
if [ "$1" = "--demo" ]; then
    main_demo
else
    echo -e "${CYAN}Kind Kubernetes Cluster Manager Demo${NC}"
    echo "===================================="
    echo ""
    echo "This script demonstrates all the enhanced features."
    echo ""
    echo -e "${YELLOW}To run interactive demo:${NC} $0 --demo"
    echo ""
    echo -e "${YELLOW}Quick feature overview:${NC}"
    echo "✅ Fixed cluster status detection (Running vs Stopped)"
    echo "✅ Enhanced testing with diagnostics"
    echo "✅ Quick utility commands"
    echo "✅ Interactive management interface"
    echo "✅ Complete cluster lifecycle management"
    echo ""
fi
