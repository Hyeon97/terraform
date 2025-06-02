#!/bin/bash

# Terraform 실행 스크립트
# Usage: ./run_terraform.sh [plan|apply|destroy] [options]

set -e  # 에러 발생 시 스크립트 종료

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로깅 함수
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

# 도움말 함수
show_help() {
    cat << EOF
Terraform 실행 스크립트

사용법:
    ./run_terraform.sh <command> [options]

Commands:
    plan      - Terraform plan 실행 및 로그 저장
    apply     - Terraform apply 실행 (자동 승인)
    destroy   - Terraform destroy 실행 (사용자 확인 후 자동 승인)
    clean     - 생성된 인스턴스 디렉토리 정리
    status    - 현재 상태 및 디렉토리 정보 확인
    help      - 이 도움말 표시

Options:
    -v, --var-file <file>    - 변수 파일 지정 (기본값: terraform.tfvars)
    -o, --output <file>      - Plan 출력 파일 지정 (plan 명령어에만 적용)
    -f, --force              - 확인 없이 강제 실행 (destroy에만 적용)
    -h, --help               - 도움말 표시

Examples:
    ./run_terraform.sh plan
    ./run_terraform.sh plan -v dev.tfvars
    ./run_terraform.sh apply
    ./run_terraform.sh destroy          # 사용자 확인 후 실행
    ./run_terraform.sh destroy -f       # 즉시 실행
    ./run_terraform.sh status
    ./run_terraform.sh clean

EOF
}

# 기본 설정
COMMAND=""
VAR_FILE="terraform.tfvars"
PLAN_OUTPUT=""
FORCE_MODE=false
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        plan|apply|destroy|clean|status|help)
            COMMAND="$1"
            shift
            ;;
        -v|--var-file)
            VAR_FILE="$2"
            shift 2
            ;;
        -o|--output)
            PLAN_OUTPUT="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_MODE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "알 수 없는 옵션: $1"
            show_help
            exit 1
            ;;
    esac
done

# 명령어가 지정되지 않은 경우
if [[ -z "$COMMAND" ]]; then
    log_error "명령어를 지정해주세요."
    show_help
    exit 1
fi

# 필수 파일 검증
validate_files() {
    local required_files=("provider.tf" "variables.tf" "main.tf")
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "필수 파일이 누락되었습니다: $file"
            exit 1
        fi
    done
    
    if [[ ! -f "$VAR_FILE" ]]; then
        log_warning "변수 파일이 존재하지 않습니다: $VAR_FILE"
        log_info "기본 변수값으로 진행합니다."
        VAR_FILE=""
    fi
}

# 인스턴스 이름 추출 (tfvars 파일에서)
get_instance_name() {
    local instance_name=""
    
    if [[ -n "$VAR_FILE" && -f "$VAR_FILE" ]]; then
        # 다양한 형태의 instance_name 추출 시도
        instance_name=$(grep -E '^[[:space:]]*instance_name[[:space:]]*=' "$VAR_FILE" | \
                       sed -E 's/^[[:space:]]*instance_name[[:space:]]*=[[:space:]]*"([^"]*)".*$/\1/' | \
                       head -n1)
        
        # 따옴표 없는 형태도 시도
        if [[ -z "$instance_name" ]]; then
            instance_name=$(grep -E '^[[:space:]]*instance_name[[:space:]]*=' "$VAR_FILE" | \
                           sed -E 's/^[[:space:]]*instance_name[[:space:]]*=[[:space:]]*([^[:space:]]+).*$/\1/' | \
                           head -n1)
        fi
    fi
    
    # 기본값 설정
    if [[ -z "$instance_name" ]]; then
        instance_name="terraform-instance"
    fi
    
    echo "$instance_name"
}

# 디스크 공간 확인
check_disk_space() {
    local required_space_mb=1000  # 1GB
    local available_space_mb
    
    available_space_mb=$(df . | tail -1 | awk '{print int($4/1024)}')
    
    if [[ $available_space_mb -lt $required_space_mb ]]; then
        log_warning "디스크 공간이 부족할 수 있습니다. (사용 가능: ${available_space_mb}MB, 권장: ${required_space_mb}MB)"
    fi
}

# 인스턴스 디렉토리 생성
create_instance_directory() {
    local instance_name="$1"
    local instance_dir="$instance_name"
    
    # 인스턴스 디렉토리 생성
    mkdir -p "$instance_dir"
    log_info "인스턴스 디렉토리 생성: $instance_dir" >&2
    
    echo "$instance_dir"
}

# 설정 파일들 복사
copy_config_files() {
    local instance_dir="$1"
    
    # credentials.json 복사
    if [[ -f "credentials.json" ]]; then
        cp "credentials.json" "$instance_dir/credentials.json"
        log_info "credentials.json 복사됨: $instance_dir/credentials.json" >&2
    else
        log_warning "credentials.json 파일을 찾을 수 없습니다." >&2
    fi
    
    # terraform.tfvars 복사 (또는 지정된 변수 파일)
    if [[ -n "$VAR_FILE" && -f "$VAR_FILE" ]]; then
        if [[ "$VAR_FILE" == "terraform.tfvars" ]]; then
            cp "$VAR_FILE" "$instance_dir/terraform.tfvars"
            log_info "terraform.tfvars 복사됨: $instance_dir/terraform.tfvars" >&2
        else
            cp "$VAR_FILE" "$instance_dir/$(basename "$VAR_FILE")"
            log_info "변수 파일 복사됨: $instance_dir/$(basename "$VAR_FILE")" >&2
        fi
    fi
}

# 인스턴스 디렉토리 확인 및 준비
prepare_instance_directory() {
    local instance_name="$1"
    local instance_dir
    
    # 인스턴스 디렉토리 확인 및 생성 (없으면 생성)
    if [[ -d "$instance_name" ]]; then
        instance_dir="$instance_name"
        log_info "기존 인스턴스 디렉토리 사용: $instance_dir" >&2
    else
        instance_dir=$(create_instance_directory "$instance_name")
        # 설정 파일들 복사 (새로 생성된 경우에만)
        copy_config_files "$instance_dir"
    fi
    
    echo "$instance_dir"
}

# total.log에 실행 히스토리 기록
log_to_total() {
    local operation="$1"
    local instance_dir="$2"
    local total_log="${instance_dir}/total.log"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    echo "[$timestamp] $operation" >> "$total_log"
}

# 로그 파일 헤더 생성
create_log_header() {
    local log_file="$1"
    local operation="$2"
    local instance_name="$3"
    local instance_dir="$4"
    
    cat > "$log_file" << 'HEADER_EOF'
=================================================
Terraform $operation Log
=================================================
Instance Name: $instance_name
Instance Directory: $instance_dir
Timestamp: $(date)
User: $(whoami)
Host: $(hostname)
Working Directory: $(pwd)
Terraform Version: $(terraform version | head -n1)
Var File: $VAR_FILE
=================================================

HEADER_EOF
    
    # 변수 치환을 위해 다시 작성
    cat > "$log_file" << EOF
=================================================
Terraform $operation Log
=================================================
Instance Name: $instance_name
Instance Directory: $instance_dir
Timestamp: $(date)
User: $(whoami)
Host: $(hostname)
Working Directory: $(pwd)
Terraform Version: $(terraform version | head -n1)
Var File: $VAR_FILE
=================================================

EOF
    
    # 환경 정보 추가
    echo "Environment Information:" >> "$log_file"
    echo "- OS: $(uname -s)" >> "$log_file"
    echo "- Architecture: $(uname -m)" >> "$log_file"
    echo "- Shell: $SHELL" >> "$log_file"
    echo "- PATH: $PATH" >> "$log_file"
    echo "" >> "$log_file"
    
    # Terraform 변수 파일 내용 (민감한 정보 제외)
    if [[ -n "$VAR_FILE" && -f "$VAR_FILE" ]]; then
        echo "Terraform Variables (from $VAR_FILE):" >> "$log_file"
        # 패스워드나 키 관련 정보는 제외하고 로깅
        grep -E '^[^#]*=' "$VAR_FILE" | grep -v -E '(password|key|secret|token)' >> "$log_file" || true
        echo "" >> "$log_file"
    fi
}

# Terraform backend 설정 파일 생성
create_backend_config() {
    local instance_dir="$1"
    local backend_config_file="${instance_dir}/backend.tf"
    
    # backend 설정 파일이 없는 경우에만 생성
    if [[ ! -f "$backend_config_file" ]]; then
        cat > "$backend_config_file" << EOF
# Terraform backend configuration for ${instance_dir}
# Auto-generated by run_terraform.sh

terraform {
  backend "local" {
    path = "${instance_dir}/terraform.tfstate"
  }
}
EOF
        log_info "Backend 설정 파일 생성: $backend_config_file" >&2
    fi
}

# Terraform 작업 디렉토리 설정
setup_terraform_workspace() {
    local instance_dir="$1"
    
    # Terraform 작업 디렉토리 설정
    export TF_DATA_DIR="${instance_dir}/.terraform"
    
    # Backend 설정 파일 생성
    create_backend_config "$instance_dir"
    
    # 기존 terraform 파일들을 인스턴스 디렉토리로 이동
    if [[ -f "terraform.tfstate" ]]; then
        mv "terraform.tfstate" "${instance_dir}/"
        log_info "terraform.tfstate를 $instance_dir 로 이동" >&2
    fi
    
    if [[ -f "terraform.tfstate.backup" ]]; then
        mv "terraform.tfstate.backup" "${instance_dir}/"
        log_info "terraform.tfstate.backup을 $instance_dir 로 이동" >&2
    fi
    
    if [[ -d ".terraform" ]]; then
        mv ".terraform" "${instance_dir}/"
        log_info ".terraform 디렉토리를 $instance_dir 로 이동" >&2
    fi
}

# Terraform 초기화 (작업 디렉토리 설정 포함)
terraform_init() {
    local instance_name="$1"
    local instance_dir
    
    instance_dir=$(prepare_instance_directory "$instance_name")
    
    log_info "Terraform 초기화 중..."
    log_info "작업 디렉토리: $instance_dir"
    
    # Terraform 작업 디렉토리 설정
    setup_terraform_workspace "$instance_dir"
    
    # 초기화 실행
    if terraform init; then
        log_success "Terraform 초기화 완료"
        log_info "Terraform 파일들이 $instance_dir 에 저장됩니다."
    else
        log_error "Terraform 초기화 실패"
        exit 1
    fi
}

# Terraform Plan 실행
terraform_plan() {
    local instance_name
    local instance_dir
    local plan_log_file
    local plan_output_file
    
    instance_name=$(get_instance_name)
    instance_dir=$(create_instance_directory "$instance_name")
    
    plan_log_file="${instance_dir}/plan.log"
    
    # Plan 출력 파일 설정
    if [[ -n "$PLAN_OUTPUT" ]]; then
        plan_output_file="$PLAN_OUTPUT"
    else
        plan_output_file="${instance_dir}/plan.tfplan"
    fi
    
    log_info "Terraform Plan 실행 중..."
    log_info "인스턴스 이름: $instance_name"
    log_info "인스턴스 디렉토리: $instance_dir"
    log_info "Plan 로그 파일: $plan_log_file"
    log_info "Plan 출력 파일: $plan_output_file"
    
    # 디스크 공간 확인
    check_disk_space
    
    # 설정 파일들 복사
    copy_config_files "$instance_dir"
    
    # total.log에 실행 기록
    log_to_total "plan" "$instance_dir"
    
    # 로그 파일 헤더 작성
    create_log_header "$plan_log_file" "Plan" "$instance_name" "$instance_dir"
    echo "Plan Output: $plan_output_file" >> "$plan_log_file"
    echo "" >> "$plan_log_file"
    
    # Terraform plan 실행 및 로깅
    local terraform_cmd="terraform plan"
    
    if [[ -n "$VAR_FILE" ]]; then
        terraform_cmd+=" -var-file=\"$VAR_FILE\""
    fi
    
    terraform_cmd+=" -out=\"$plan_output_file\""
    
    log_info "실행 명령어: $terraform_cmd"
    echo "Command: $terraform_cmd" >> "$plan_log_file"
    echo "" >> "$plan_log_file"
    echo "Plan execution started at: $(date)" >> "$plan_log_file"
    echo "----------------------------------------" >> "$plan_log_file"
    echo "" >> "$plan_log_file"
    
    # Plan 실행 및 결과 저장
    if eval "$terraform_cmd" 2>&1 | tee -a "$plan_log_file"; then
        log_success "Terraform Plan 완료"
        
        # Plan 완료 후 정보 추가
        echo "" >> "$plan_log_file"
        echo "----------------------------------------" >> "$plan_log_file"
        echo "Plan execution completed at: $(date)" >> "$plan_log_file"
        echo "" >> "$plan_log_file"
        
        # Plan 파일 정보 추가
        if [[ -f "$plan_output_file" ]]; then
            echo "Plan file details:" >> "$plan_log_file"
            ls -la "$plan_output_file" >> "$plan_log_file"
            echo "Plan file size: $(du -h "$plan_output_file" | cut -f1)" >> "$plan_log_file"
            echo "" >> "$plan_log_file"
        fi
        
        # Terraform 파일들 이동 및 정보 기록
        echo "Terraform files location:" >> "$plan_log_file"
        echo "- State file: ${instance_dir}/terraform.tfstate" >> "$plan_log_file"
        echo "- Terraform dir: ${instance_dir}/.terraform/" >> "$plan_log_file"
        echo "" >> "$plan_log_file"
        
        echo "==================================================" >> "$plan_log_file"
        echo "Plan completed successfully at: $(date)" >> "$plan_log_file"
        echo "==================================================" >> "$plan_log_file"
        
        # Plan 요약 정보 출력
        echo ""
        log_info "=== Plan 요약 정보 ==="
        log_info "인스턴스 디렉토리: $instance_dir"
        log_info "로그 파일: $plan_log_file"
        log_info "Plan 파일: $plan_output_file"
        log_info "상태 파일: ${instance_dir}/terraform.tfstate"
        
        # Plan 결과에서 리소스 변경 정보 추출
        if grep -q "Plan:" "$plan_log_file"; then
            local plan_summary
            plan_summary=$(grep "Plan:" "$plan_log_file" | tail -1)
            log_info "변경 사항: $plan_summary"
        fi
        
        # 파일 크기 정보
        log_info "로그 파일 크기: $(du -h "$plan_log_file" | cut -f1)"
        log_info "Plan 파일 크기: $(du -h "$plan_output_file" | cut -f1)"
        
        echo ""
        log_success "Plan이 성공적으로 완료되었습니다."
        log_info "Apply를 실행하려면: ./run_terraform.sh apply"
        log_info "Plan 내용 확인: terraform show $plan_output_file"
        
    else
        log_error "Terraform Plan 실패"
        echo "" >> "$plan_log_file"
        echo "----------------------------------------" >> "$plan_log_file"
        echo "Plan execution failed at: $(date)" >> "$plan_log_file"
        echo "==================================================" >> "$plan_log_file"
        echo "Plan failed at: $(date)" >> "$plan_log_file"
        echo "==================================================" >> "$plan_log_file"
        
        # 실패한 로그 파일 위치 안내
        log_error "오류 로그 확인: $plan_log_file"
        exit 1
    fi
}

# Terraform Apply 실행
terraform_apply() {
    local instance_name
    local instance_dir
    local apply_log_file
    
    instance_name=$(get_instance_name)
    instance_dir=$(prepare_instance_directory "$instance_name")
    apply_log_file="${instance_dir}/apply.log"
    
    log_info "Terraform Apply 실행 중..."
    log_info "인스턴스 이름: $instance_name"
    log_info "인스턴스 디렉토리: $instance_dir"
    log_info "Apply 로그 파일: $apply_log_file"
    log_info "자동 승인 모드로 실행됩니다."
    
    # total.log에 실행 기록
    log_to_total "apply" "$instance_dir"
    
    # Terraform 작업 디렉토리 설정
    setup_terraform_workspace "$instance_dir"
    
    # 로그 파일 헤더 작성
    create_log_header "$apply_log_file" "Apply" "$instance_name" "$instance_dir"
    
    # Terraform apply 실행
    local terraform_cmd="terraform apply -auto-approve"
    
    if [[ -n "$VAR_FILE" ]]; then
        terraform_cmd+=" -var-file=\"$VAR_FILE\""
    fi
    
    log_info "실행 명령어: $terraform_cmd"
    echo "Command: $terraform_cmd" >> "$apply_log_file"
    echo "" >> "$apply_log_file"
    echo "Apply execution started at: $(date)" >> "$apply_log_file"
    echo "----------------------------------------" >> "$apply_log_file"
    echo "" >> "$apply_log_file"
    
    if eval "$terraform_cmd" 2>&1 | tee -a "$apply_log_file"; then
        log_success "Terraform Apply 완료"
        
        # Apply 완료 후 정보 추가
        echo "" >> "$apply_log_file"
        echo "----------------------------------------" >> "$apply_log_file"
        echo "Apply execution completed at: $(date)" >> "$apply_log_file"
        echo "" >> "$apply_log_file"
        
        # Terraform 상태 정보 저장
        echo "Terraform State Summary:" >> "$apply_log_file"
        terraform show -no-color >> "$apply_log_file" 2>&1 || echo "Failed to get terraform state" >> "$apply_log_file"
        echo "" >> "$apply_log_file"
        
        # Output 정보 저장
        echo "Terraform Outputs:" >> "$apply_log_file"
        terraform output -no-color >> "$apply_log_file" 2>&1 || echo "No outputs available" >> "$apply_log_file"
        echo "" >> "$apply_log_file"
        
        # Terraform 파일들 위치 정보
        echo "Terraform files location:" >> "$apply_log_file"
        echo "- State file: ${instance_dir}/terraform.tfstate" >> "$apply_log_file"
        echo "- Backup file: ${instance_dir}/terraform.tfstate.backup" >> "$apply_log_file"
        echo "- Terraform dir: ${instance_dir}/.terraform/" >> "$apply_log_file"
        echo "" >> "$apply_log_file"
        
        echo "==================================================" >> "$apply_log_file"
        echo "Apply completed successfully at: $(date)" >> "$apply_log_file"
        echo "==================================================" >> "$apply_log_file"
        
        # Apply 후 출력 정보 표시
        echo ""
        log_info "=== 생성된 리소스 정보 ==="
        terraform output
        
        # Apply 요약 정보 출력
        echo ""
        log_info "=== Apply 요약 정보 ==="
        log_info "인스턴스 디렉토리: $instance_dir"
        log_info "Apply 로그 파일: $apply_log_file"
        log_info "상태 파일: ${instance_dir}/terraform.tfstate"
        log_info "로그 파일 크기: $(du -h "$apply_log_file" | cut -f1)"
        
        echo ""
        log_success "Apply가 성공적으로 완료되었습니다."
        log_info "생성된 리소스 확인: terraform output"
        log_info "상세 로그 확인: cat $apply_log_file"
        
    else
        log_error "Terraform Apply 실패"
        echo "" >> "$apply_log_file"
        echo "----------------------------------------" >> "$apply_log_file"
        echo "Apply execution failed at: $(date)" >> "$apply_log_file"
        echo "==================================================" >> "$apply_log_file"
        echo "Apply failed at: $(date)" >> "$apply_log_file"
        echo "==================================================" >> "$apply_log_file"
        
        # 실패한 로그 파일 위치 안내
        log_error "오류 로그 확인: $apply_log_file"
        exit 1
    fi
}

# Terraform Destroy 실행
terraform_destroy() {
    local instance_name
    local instance_dir
    local destroy_log_file
    
    instance_name=$(get_instance_name)
    instance_dir=$(prepare_instance_directory "$instance_name")
    destroy_log_file="${instance_dir}/destroy.log"
    
    log_warning "Terraform Destroy 실행 중..."
    log_info "인스턴스 이름: $instance_name"
    log_info "인스턴스 디렉토리: $instance_dir"
    log_info "Destroy 로그 파일: $destroy_log_file"
    
    # 강제 모드가 아닌 경우 사용자 확인
    if [[ "$FORCE_MODE" != true ]]; then
        echo ""
        log_warning "다음 리소스가 삭제됩니다:"
        echo "  - 인스턴스: $instance_name"
        echo "  - 관련된 모든 리소스 (볼륨, 네트워크, 보안그룹 등)"
        echo ""
        read -p "정말로 삭제하시겠습니까? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Destroy가 취소되었습니다."
            exit 0
        fi
        log_info "사용자 확인 완료. 자동 승인 모드로 실행됩니다."
    else
        log_info "강제 모드. 자동 승인으로 실행됩니다."
    fi
    
    # total.log에 실행 기록
    log_to_total "destroy" "$instance_dir"
    
    # Terraform 작업 디렉토리 설정
    setup_terraform_workspace "$instance_dir"
    
    # 로그 파일 헤더 작성
    create_log_header "$destroy_log_file" "Destroy" "$instance_name" "$instance_dir"
    
    # 삭제 전 현재 상태 백업
    echo "Current Terraform State (before destroy):" >> "$destroy_log_file"
    terraform show -no-color >> "$destroy_log_file" 2>&1 || echo "Failed to get current state" >> "$destroy_log_file"
    echo "" >> "$destroy_log_file"
    
    echo "Current Terraform Outputs (before destroy):" >> "$destroy_log_file"
    terraform output -no-color >> "$destroy_log_file" 2>&1 || echo "No outputs available" >> "$destroy_log_file"
    echo "" >> "$destroy_log_file"
    
    # Terraform destroy 실행
    local terraform_cmd="terraform destroy -auto-approve"
    
    if [[ -n "$VAR_FILE" ]]; then
        terraform_cmd+=" -var-file=\"$VAR_FILE\""
    fi
    
    log_info "실행 명령어: $terraform_cmd"
    echo "Command: $terraform_cmd" >> "$destroy_log_file"
    echo "" >> "$destroy_log_file"
    echo "Destroy execution started at: $(date)" >> "$destroy_log_file"
    echo "----------------------------------------" >> "$destroy_log_file"
    echo "" >> "$destroy_log_file"
    
    if eval "$terraform_cmd" 2>&1 | tee -a "$destroy_log_file"; then
        log_success "Terraform Destroy 완료"
        
        # Destroy 완료 후 정보 추가
        echo "" >> "$destroy_log_file"
        echo "----------------------------------------" >> "$destroy_log_file"
        echo "Destroy execution completed at: $(date)" >> "$destroy_log_file"
        echo "" >> "$destroy_log_file"
        
        # Terraform 파일들 정보
        echo "Terraform files preserved:" >> "$destroy_log_file"
        echo "- State file: ${instance_dir}/terraform.tfstate" >> "$destroy_log_file"
        echo "- Backup file: ${instance_dir}/terraform.tfstate.backup" >> "$destroy_log_file"
        echo "- Terraform dir: ${instance_dir}/.terraform/" >> "$destroy_log_file"
        echo "" >> "$destroy_log_file"
        
        echo "==================================================" >> "$destroy_log_file"
        echo "Destroy completed successfully at: $(date)" >> "$destroy_log_file"
        echo "==================================================" >> "$destroy_log_file"
        
        # Destroy 요약 정보 출력
        echo ""
        log_info "=== Destroy 요약 정보 ==="
        log_info "인스턴스 디렉토리: $instance_dir"
        log_info "Destroy 로그 파일: $destroy_log_file"
        log_info "상태 파일: ${instance_dir}/terraform.tfstate"
        log_info "로그 파일 크기: $(du -h "$destroy_log_file" | cut -f1)"
        
        echo ""
        log_success "Destroy가 성공적으로 완료되었습니다."
        log_info "상세 로그 확인: cat $destroy_log_file"
        log_info "모든 Terraform 파일이 $instance_dir 에 보존되었습니다."
        
    else
        log_error "Terraform Destroy 실패"
        echo "" >> "$destroy_log_file"
        echo "----------------------------------------" >> "$destroy_log_file"
        echo "Destroy execution failed at: $(date)" >> "$destroy_log_file"
        echo "==================================================" >> "$destroy_log_file"
        echo "Destroy failed at: $(date)" >> "$destroy_log_file"
        echo "==================================================" >> "$destroy_log_file"
        
        # 실패한 로그 파일 위치 안내
        log_error "오류 로그 확인: $destroy_log_file"
        exit 1
    fi
}

# 인스턴스 디렉토리 정리
clean_directories() {
    local found_dirs=()
    
    # 현재 디렉토리에서 인스턴스 디렉토리 찾기
    for dir in */; do
        if [[ -d "$dir" && "$dir" != "modules/" && "$dir" != ".terraform/" ]]; then
            # 디렉토리 내에 plan.log, apply.log, destroy.log 파일이 있는지 확인
            if ls "${dir}"plan.log >/dev/null 2>&1 || ls "${dir}"apply.log >/dev/null 2>&1 || ls "${dir}"destroy.log >/dev/null 2>&1; then
                found_dirs+=("$dir")
            fi
        fi
    done
    
    if [[ ${#found_dirs[@]} -eq 0 ]]; then
        log_info "정리할 인스턴스 디렉토리가 없습니다."
        return
    fi
    
    log_warning "정리될 인스턴스 디렉토리 목록:"
    for dir in "${found_dirs[@]}"; do
        local dir_size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        local file_count=$(find "$dir" -type f | wc -l)
        log_info "- $dir (크기: $dir_size, 파일: $file_count개)"
    done
    
    echo ""
    read -p "계속 진행하시겠습니까? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for dir in "${found_dirs[@]}"; do
            rm -rf "$dir"
            log_success "디렉토리 삭제됨: $dir"
        done
        log_success "인스턴스 디렉토리들이 정리되었습니다."
    else
        log_info "정리가 취소되었습니다."
    fi
}

# 상태 및 디렉토리 정보 표시
show_status() {
    local instance_name
    instance_name=$(get_instance_name)
    
    echo ""
    log_info "=== 현재 상태 정보 ==="
    log_info "설정된 인스턴스 이름: $instance_name"
    log_info "변수 파일: $VAR_FILE"
    log_info "작업 디렉토리: $(pwd)"
    
    # 인스턴스 디렉토리 확인
    if [[ -d "$instance_name" ]]; then
        log_info "인스턴스 디렉토리: $instance_name/ (존재함)"
        
        # 디렉토리 내 파일 목록
        echo ""
        log_info "=== 인스턴스 디렉토리 내용 ==="
        ls -la "$instance_name/"
        
        # Terraform 파일들 통계
        local terraform_files=$(find "$instance_name" -name "plan.log" -o -name "apply.log" -o -name "destroy.log" -o -name "plan.tfplan" -o -name "total.log" | wc -l)
        log_info "Terraform 관련 파일 수: $terraform_files"
        
        # total.log 내용 표시 (있는 경우)
        if [[ -f "$instance_name/total.log" ]]; then
            echo ""
            log_info "=== 실행 히스토리 (total.log) ==="
            cat "$instance_name/total.log"
        fi
        
    else
        log_warning "인스턴스 디렉토리: $instance_name/ (존재하지 않음)"
    fi
    
    # 기타 관련 디렉토리들
    echo ""
    log_info "=== 기타 디렉토리 정보 ==="
    for dir in */; do
        if [[ -d "$dir" && "$dir" != "modules/" && "$dir" != ".terraform/" ]]; then
            if ls "${dir}"plan.log >/dev/null 2>&1 || ls "${dir}"apply.log >/dev/null 2>&1 || ls "${dir}"destroy.log >/dev/null 2>&1; then
                local dir_size=$(du -sh "$dir" 2>/dev/null | cut -f1)
                log_info "- $dir (크기: $dir_size)"
            fi
        fi
    done
    
    echo ""
}

# 메인 실행 로직
main() {
    log_info "Terraform 실행 스크립트 시작"
    log_info "명령어: $COMMAND"
    log_info "작업 디렉토리: $(pwd)"
    
    local instance_name
    
    case $COMMAND in
        help)
            show_help
            ;;
        status)
            show_status
            ;;
        clean)
            clean_directories
            ;;
        plan)
            validate_files
            instance_name=$(get_instance_name)
            terraform_init "$instance_name"
            terraform_plan
            ;;
        apply)
            validate_files
            instance_name=$(get_instance_name)
            terraform_init "$instance_name" 
            terraform_apply
            ;;
        destroy)
            validate_files
            instance_name=$(get_instance_name)
            terraform_init "$instance_name"
            terraform_destroy
            ;;
        *)
            log_error "지원하지 않는 명령어: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@"