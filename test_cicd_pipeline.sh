#!/bin/bash

# Remove the strict exit-on-error to allow tests to continue
# set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
STAGE_RESULTS=()

echo ""
echo "=========================================="
echo "  CI/CD Pipeline Testing Suite"
echo "=========================================="
echo ""

# ==========================================
# STAGE 1: Prerequisites Check
# ==========================================
log_info "STAGE 1: Checking prerequisites..."

check_tool() {
    if command -v $1 &> /dev/null; then
        log_success "$1 is installed"
        ((TESTS_PASSED++))
        return 0
    else
        log_warning "$1 is not installed"
        ((TESTS_FAILED++))
        return 1
    fi
}

check_tool "docker"
check_tool "docker-compose"
check_tool "python3"
check_tool "npm"
check_tool "git"

STAGE_RESULTS+=("Prerequisites: $TESTS_PASSED passed, $TESTS_FAILED failed")

# ==========================================
# STAGE 2: Docker Build Validation
# ==========================================
log_info "STAGE 2: Building Docker images..."

DOCKER_TESTS_PASSED=0
DOCKER_TESTS_FAILED=0

build_docker_image() {
    local dockerfile=$1
    local service_name=$2
    
    echo -n "  Building $service_name... "
    if docker build -f "$dockerfile" -t "fantasy-$service_name:test" . > /tmp/docker_build_$service_name.log 2>&1; then
        log_success "$service_name build successful"
        ((DOCKER_TESTS_PASSED++))
        return 0
    else
        log_error "$service_name build failed"
        echo "    Error log:"
        tail -10 /tmp/docker_build_$service_name.log | sed 's/^/    /'
        ((DOCKER_TESTS_FAILED++))
        return 1
    fi
}

build_docker_image "backend/Dockerfile" "backend"
build_docker_image "frontend/Dockerfile" "frontend"
build_docker_image "consumers/Dockerfile" "consumers"

STAGE_RESULTS+=("Docker Build: $DOCKER_TESTS_PASSED passed, $DOCKER_TESTS_FAILED failed")

# ==========================================
# STAGE 3: Code Quality (SonarQube)
# ==========================================
log_info "STAGE 3: Code Quality Analysis (SonarQube)..."

if [ -f "sonar-project.properties" ]; then
    log_warning "SonarQube configuration found but requires SonarQube server running"
    log_info "To run SonarQube locally:"
    echo "  docker run -d --name sonarqube -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLED=true -p 9000:9000 sonarqube:latest"
    echo "  sonar-scanner"
    STAGE_RESULTS+=("SonarQube: Skipped (requires server)")
else
    log_warning "sonar-project.properties not found"
    STAGE_RESULTS+=("SonarQube: Not configured")
fi

# ==========================================
# STAGE 4: Infrastructure Start
# ==========================================
log_info "STAGE 4: Starting Docker Compose infrastructure..."

if docker-compose up -d 2>&1 | tail -5; then
    log_success "Docker Compose started"
    sleep 15
    
    # Check if all services are running
    echo ""
    log_info "Checking service health..."
    
    INFRA_HEALTHY=0
    
    # Check MongoDB
    if docker exec mongo mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
        log_success "MongoDB is responding"
        ((INFRA_HEALTHY++))
    else
        log_error "MongoDB is not responding"
    fi
    
    # Check Redis
    if docker exec redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis is responding"
        ((INFRA_HEALTHY++))
    else
        log_error "Redis is not responding"
    fi
    
    # Check Kafka
    if docker exec kafka kafka-broker-api-versions.sh --bootstrap-server kafka:9092 > /dev/null 2>&1; then
        log_success "Kafka is responding"
        ((INFRA_HEALTHY++))
    else
        log_error "Kafka is not responding"
    fi
    
    # Check Backend
    if curl -s http://localhost:5001/players > /dev/null 2>&1; then
        log_success "Backend API is responding"
        ((INFRA_HEALTHY++))
    else
        log_error "Backend API is not responding"
    fi
    
    STAGE_RESULTS+=("Infrastructure: $INFRA_HEALTHY/4 services healthy")
else
    log_error "Failed to start Docker Compose"
    STAGE_RESULTS+=("Infrastructure: Failed to start")
    log_warning "Continuing with other tests..."
fi

# ==========================================
# STAGE 5: API Testing (Postman/Newman)
# ==========================================
log_info "STAGE 5: API Testing..."

if [ -f "postman_collection.json" ]; then
    # Check if backend is running first
    if ! curl -s http://localhost:5001/players > /dev/null 2>&1; then
        log_warning "Backend API not running - skipping API tests"
        STAGE_RESULTS+=("API Testing: Skipped (backend not running)")
    elif command -v newman &> /dev/null; then
        echo "  Running Newman API tests..."
        if newman run postman_collection.json -r json,html --reporter-json-export /tmp/newman_results.json --reporter-html-export /tmp/newman_report.html > /dev/null 2>&1; then
            log_success "API tests passed"
            STAGE_RESULTS+=("API Testing: Passed")
        else
            log_error "API tests failed (check /tmp/newman_report.html)"
            STAGE_RESULTS+=("API Testing: Failed")
        fi
    else
        log_warning "Newman not installed. Installing..."
        npm install -g newman > /dev/null 2>&1
        if newman run postman_collection.json -r json,html --reporter-json-export /tmp/newman_results.json --reporter-html-export /tmp/newman_report.html > /dev/null 2>&1; then
            log_success "API tests passed"
            STAGE_RESULTS+=("API Testing: Passed")
        else
            log_error "API tests failed"
            STAGE_RESULTS+=("API Testing: Failed")
        fi
    fi
else
    log_warning "postman_collection.json not found"
    STAGE_RESULTS+=("API Testing: Skipped (no collection)")
fi

# ==========================================
# STAGE 6: Basic Security Scanning
# ==========================================
log_info "STAGE 6: Security Scanning..."

# Check for hardcoded secrets
log_info "Checking for hardcoded secrets..."
SECRET_MATCHES=$(grep -r "password\|secret\|key" --include="*.py" --include="*.js" backend/ frontend/ consumers/ 2>/dev/null | grep -v "SECRET_KEY" | grep -v "config" | wc -l)

if [ "$SECRET_MATCHES" -lt 5 ]; then
    log_success "No obvious hardcoded secrets found"
    STAGE_RESULTS+=("Security Scan: Passed")
else
    log_warning "Found $SECRET_MATCHES potential hardcoded secrets - review recommended"
    STAGE_RESULTS+=("Security Scan: Warning")
fi

# ==========================================
# STAGE 7: Consumer Testing
# ==========================================
log_info "STAGE 7: Testing Kafka Consumers..."

# Check if consumers are running
CONSUMER_HEALTH=0

if docker exec player-consumer ps aux 2>/dev/null | grep -q "player_consumer.py"; then
    log_success "Player consumer is running"
    ((CONSUMER_HEALTH++))
else
    log_error "Player consumer is not running"
fi

if docker exec eval-engine ps aux 2>/dev/null | grep -q "evalengine.py"; then
    log_success "Eval engine consumer is running"
    ((CONSUMER_HEALTH++))
else
    log_error "Eval engine consumer is not running"
fi

if docker exec leaderboard-consumer ps aux 2>/dev/null | grep -q "leaderboard_consumer.py"; then
    log_success "Leaderboard consumer is running"
    ((CONSUMER_HEALTH++))
else
    log_error "Leaderboard consumer is not running"
fi

STAGE_RESULTS+=("Consumer Health: $CONSUMER_HEALTH/3 running")

# ==========================================
# STAGE 8: Data Flow Testing
# ==========================================
log_info "STAGE 8: Testing Data Flow (Producer → Kafka → Consumers → DB)..."

# Send test player data
if [ $CONSUMER_HEALTH -eq 0 ]; then
    log_warning "Consumers not running - skipping data flow test"
    STAGE_RESULTS+=("Data Flow: Skipped (consumers not running)")
else
    log_info "Publishing test player data..."
    if python3 producer/player_dump.py > /dev/null 2>&1; then
        log_success "Producer published test data"
        
        # Wait for consumer to process
        sleep 3
        
        # Check if data reached MongoDB
        PLAYER_COUNT=$(docker exec mongo mongosh --eval "db.cricket_db.players.count()" 2>/dev/null | grep -oE '[0-9]+$' | tail -1)
        
        if [ ! -z "$PLAYER_COUNT" ] && [ "$PLAYER_COUNT" -gt 0 ]; then
            log_success "Data flow verified: $PLAYER_COUNT players in database"
            STAGE_RESULTS+=("Data Flow: Successful ($PLAYER_COUNT records)")
        else
            log_error "Data flow failed: No players found in database"
            STAGE_RESULTS+=("Data Flow: Failed")
        fi
    else
        log_error "Producer failed to publish"
        STAGE_RESULTS+=("Data Flow: Producer error")
    fi
fi

# ==========================================
# STAGE 9: Load Testing (Optional)
# ==========================================
log_info "STAGE 9: Basic Load Testing..."

# Check if backend is running
if ! curl -s http://localhost:5001/players > /dev/null 2>&1; then
    log_warning "Backend API not running - skipping load testing"
    STAGE_RESULTS+=("Load Test: Skipped (backend not running)")
elif command -v ab &> /dev/null; then
    log_info "Running Apache Bench on backend API..."
    if ab -n 100 -c 10 http://localhost:5001/players > /tmp/load_test.log 2>&1; then
        if grep -q "Requests per second" /tmp/load_test.log; then
            THROUGHPUT=$(grep "Requests per second" /tmp/load_test.log | awk '{print $4}')
            log_success "Load test completed: $THROUGHPUT req/sec"
            STAGE_RESULTS+=("Load Test: $THROUGHPUT req/sec")
        fi
    else
        log_error "Load test failed"
        STAGE_RESULTS+=("Load Test: Failed")
    fi
else
    log_warning "Apache Bench (ab) not installed - skipping load testing"
    STAGE_RESULTS+=("Load Test: Skipped (ab not installed)")
fi

# ==========================================
# STAGE 10: Cleanup & Report
# ==========================================
log_info "STAGE 10: Generating Report..."

echo ""
echo "=========================================="
echo "  Test Results Summary"
echo "=========================================="
echo ""

for result in "${STAGE_RESULTS[@]}"; do
    echo "  • $result"
done

# Shutdown services (if they're running)
log_info "Cleaning up services..."
docker-compose down > /dev/null 2>&1 || log_warning "Some services may not have been started"
log_success "Infrastructure stopped"

echo ""
echo "=========================================="
echo "  Reports Generated"
echo "=========================================="
echo ""
[ -f /tmp/newman_report.html ] && log_info "API Test Report: /tmp/newman_report.html"
[ -f /tmp/load_test.log ] && log_info "Load Test Log: /tmp/load_test.log"
log_info "Docker Build Logs: /tmp/docker_build.log"

echo ""
echo "=========================================="
echo "  Pipeline Testing Complete"
echo "=========================================="
echo