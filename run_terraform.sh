#!/bin/bash

# Terraform Apply 실행 및 로그 캡처 스크립트
# 사용법: ./run_terraform.sh [plan|apply|destroy] [tfvars_file]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 인스턴스 이름 추출 함수
extract_instance_name() {
    local tfvars_file="$1"
    local instance_name=""
    
    if [ -f "$tfvars_file" ]; then
        # .tfvars 파일에서 instance_name 추출
        if grep -q '^instance_name' "$tfvars_file"; then
            instance_name=$(grep '^instance_name' "$tfvars_file" | head -1 | cut -d'=' -f2 | sed 's/[[:space:]]*//g' | sed 's/^"//g' | sed 's/"$//g')
        fi
    fi
    
    echo "$instance_name"
}

# 기본값 설정
ACTION=${1:-apply}
TFVARS_FILE=${2:-terraform.tfvars}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TERRAFORM_LOG_DIR="terraform_logs"
PLAN_FILE="terraform_${TIMESTAMP}.tfplan"

# tfvars 파일 존재 확인
if [ ! -f "$TFVARS_FILE" ]; then
    log_error "Terraform variables file not found: $TFVARS_FILE"
    echo "Available .tfvars files:"
    ls -la *.tfvars 2>/dev/null || echo "No .tfvars files found"
    exit 1
fi

# 로그 디렉토리 생성
mkdir -p "$TERRAFORM_LOG_DIR"

# 인스턴스 이름 추출
INSTANCE_NAME=$(extract_instance_name "$TFVARS_FILE")

if [ -z "$INSTANCE_NAME" ]; then
    log_error "Could not extract instance_name from $TFVARS_FILE"
    log_info "Make sure your tfvars file contains: instance_name = \"your-instance-name\""
    exit 1
fi

log_info "Starting Terraform $ACTION for instance: $INSTANCE_NAME"
log_info "Using tfvars file: $TFVARS_FILE"
log_info "Timestamp: $TIMESTAMP"

# Plan 단계에서 VM 디렉토리 미리 생성
if [ "$ACTION" = "plan" ] || [ "$ACTION" = "apply" ]; then
    log_info "Creating directory for instance: $INSTANCE_NAME"
    mkdir -p "$INSTANCE_NAME"
    
    # 초기 로그 파일 생성
    cat > "$INSTANCE_NAME/creation.log" << EOF
==================================================
Terraform $ACTION Started
==================================================
Instance Name: $INSTANCE_NAME
Tfvars File: $TFVARS_FILE
Timestamp: $TIMESTAMP
Action: $ACTION
==================================================

EOF
fi

case $ACTION in
    "plan")
        log_info "Running terraform plan..."
        
        # Plan 실행 및 로그 저장 (tfvars 파일 지정)
        terraform plan -var-file="$TFVARS_FILE" -out="$PLAN_FILE" 2>&1 | tee "$TERRAFORM_LOG_DIR/terraform_plan_${TIMESTAMP}.log"
        PLAN_EXIT_CODE=${PIPESTATUS[0]}
        
        if [ $PLAN_EXIT_CODE -eq 0 ]; then
            log_success "Terraform plan completed successfully"
            log_info "Plan file: $PLAN_FILE"
            log_info "Plan log: $TERRAFORM_LOG_DIR/terraform_plan_${TIMESTAMP}.log"
            
            # Plan 결과를 인스턴스 디렉토리에 복사
            log_info "Copying terraform plan log to instance directory..."
            cp "$TERRAFORM_LOG_DIR/terraform_plan_${TIMESTAMP}.log" "$INSTANCE_NAME/terraform_plan_output.log"
            
            # Plan 결과를 creation.log에 추가
            cat >> "$INSTANCE_NAME/creation.log" << EOF
Terraform Plan Output:
======================
EOF
            cat "$TERRAFORM_LOG_DIR/terraform_plan_${TIMESTAMP}.log" >> "$INSTANCE_NAME/creation.log"
            echo "" >> "$INSTANCE_NAME/creation.log"
            echo "Plan completed at: $(date)" >> "$INSTANCE_NAME/creation.log"
            echo "==================================================" >> "$INSTANCE_NAME/creation.log"
            
            log_success "Plan results saved to $INSTANCE_NAME/ directory"
        else
            log_error "Terraform plan failed with exit code: $PLAN_EXIT_CODE"
            echo "Plan failed at: $(date)" >> "$INSTANCE_NAME/creation.log"
            exit $PLAN_EXIT_CODE
        fi
        ;;
        
    "apply")
        log_info "Running terraform apply..."
        
        # Apply 실행 및 로그 저장 (tfvars 파일 지정)
        terraform apply -var-file="$TFVARS_FILE" -auto-approve 2>&1 | tee "$TERRAFORM_LOG_DIR/terraform_apply_${TIMESTAMP}.log"
        APPLY_EXIT_CODE=${PIPESTATUS[0]}
        
        if [ $APPLY_EXIT_CODE -eq 0 ]; then
            log_success "Terraform apply completed successfully"
            
            # Apply 로그를 인스턴스 디렉토리에 복사
            log_info "Copying terraform apply log to instance directory..."
            cp "$TERRAFORM_LOG_DIR/terraform_apply_${TIMESTAMP}.log" "$INSTANCE_NAME/terraform_apply_output.log"
            
            # 추가 정보를 creation.log에 추가
            cat >> "$INSTANCE_NAME/creation.log" << EOF

==================================================
Terraform Apply Output (Full Log):
==================================================
EOF
            cat "$TERRAFORM_LOG_DIR/terraform_apply_${TIMESTAMP}.log" >> "$INSTANCE_NAME/creation.log"
            
            # Terraform output도 저장
            log_info "Saving terraform outputs..."
            cat >> "$INSTANCE_NAME/creation.log" << EOF

==================================================
Terraform Outputs:
==================================================
EOF
            terraform output >> "$INSTANCE_NAME/creation.log" 2>&1
            
            echo "" >> "$INSTANCE_NAME/creation.log"
            echo "==================================================" >> "$INSTANCE_NAME/creation.log"
            echo "Apply completed at: $(date)" >> "$INSTANCE_NAME/creation.log"
            echo "==================================================" >> "$INSTANCE_NAME/creation.log"
            
            log_success "All logs saved to $INSTANCE_NAME/ directory"
            
            # 최종 요약 정보 표시
            log_success "=== DEPLOYMENT SUMMARY ==="
            echo "Instance Name: $INSTANCE_NAME"
            echo "Tfvars File: $TFVARS_FILE"
            echo "Timestamp: $TIMESTAMP"
            echo "Apply Log: $TERRAFORM_LOG_DIR/terraform_apply_${TIMESTAMP}.log"
            echo "Instance Directory: $INSTANCE_NAME/"
            echo "Creation Log: $INSTANCE_NAME/creation.log"
            echo "Instance Info: $INSTANCE_NAME/instance_info.json"
            echo ""
            echo "Files in $INSTANCE_NAME/ directory:"
            ls -la "$INSTANCE_NAME/"
            log_success "=========================="
        else
            log_error "Terraform apply failed with exit code: $APPLY_EXIT_CODE"
            echo "Apply failed at: $(date)" >> "$INSTANCE_NAME/creation.log"
            exit $APPLY_EXIT_CODE
        fi
        ;;
        
    "destroy")
        log_warning "Running terraform destroy..."
        
        # Destroy 실행 및 로그 저장 (tfvars 파일 지정)
        terraform destroy -var-file="$TFVARS_FILE" -auto-approve 2>&1 | tee "$TERRAFORM_LOG_DIR/terraform_destroy_${TIMESTAMP}.log"
        DESTROY_EXIT_CODE=${PIPESTATUS[0]}
        
        if [ $DESTROY_EXIT_CODE -eq 0 ]; then
            log_success "Terraform destroy completed successfully"
            log_info "Destroy log: $TERRAFORM_LOG_DIR/terraform_destroy_${TIMESTAMP}.log"
            
            # 인스턴스 디렉토리가 있다면 destroy 로그도 복사
            if [ -d "$INSTANCE_NAME" ]; then
                log_info "Copying destroy log to instance directory..."
                cp "$TERRAFORM_LOG_DIR/terraform_destroy_${TIMESTAMP}.log" "$INSTANCE_NAME/terraform_destroy_output.log"
                
                cat >> "$INSTANCE_NAME/deletion.log" << EOF
==================================================
Terraform Destroy Output (Full Log):
==================================================
EOF
                cat "$TERRAFORM_LOG_DIR/terraform_destroy_${TIMESTAMP}.log" >> "$INSTANCE_NAME/deletion.log"
                echo "Destroy completed at: $(date)" >> "$INSTANCE_NAME/deletion.log"
                
                log_warning "Instance directory $INSTANCE_NAME/ preserved with destroy logs"
                log_warning "You can manually delete it if no longer needed"
            fi
        else
            log_error "Terraform destroy failed with exit code: $DESTROY_EXIT_CODE"
            exit $DESTROY_EXIT_CODE
        fi
        ;;
        
    *)
        log_error "Invalid action: $ACTION"
        echo "Usage: $0 [plan|apply|destroy] [tfvars_file]"
        echo ""
        echo "Examples:"
        echo "  $0 plan                    # Use default terraform.tfvars"
        echo "  $0 plan prod.tfvars        # Use specific tfvars file"
        echo "  $0 apply                   # Apply with default terraform.tfvars"
        echo "  $0 apply prod.tfvars       # Apply with specific tfvars file"
        echo "  $0 destroy staging.tfvars  # Destroy with specific tfvars file"
        exit 1
        ;;
esac

log_success "Terraform $ACTION operation completed!"