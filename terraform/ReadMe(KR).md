# Terraform OpenStack 인스턴스 관리 가이드

## 명령어

### 인스턴스 생성 및 관리 워크플로우
```txt
# 인스턴스 생성
1. plan: plan 실행을 통해 현재 인스턴스 구성 정보 검증
2. apply: plan에서 검증된 구성을 사용하여 인스턴스 생성

# 인스턴스 삭제
1. destroy: 생성된 인스턴스 제거
```

### run_terraform.sh 스크립트 사용
```bash
1. run_terraform.sh plan
2. run_terraform.sh apply
```

### Terraform 명령어 직접 사용
```bash
terraform plan --var-file "/path/to/terraform.tfvars"
terraform apply --var-file "/path/to/terraform.tfvars" --auto-approve
```

## 실행 상세 내용

### Plan 명령어 실행
- terraform.tfvars에 지정된 `instance_name` 값으로 디렉토리 자동 생성
- 해당 디렉토리 내에 `plan.log`, `plan.tfplan` 파일 자동 생성
- 인스턴스 생성에 사용할 `credentials.json`, `terraform.tfvars` 파일 자동 복사

### Apply 명령어 실행
- plan 명령어 실행 시 생성된 디렉토리 내에 `apply.log` 파일 자동 생성
- 완료(성공/실패) 시 `backend.tf`, `credentials.json` 파일 생성
- 성공적으로 완료 시 `instance_info.json`, `terraform_state_backup.txt` 파일 생성

### Destroy 명령어 실행
- plan 명령어 실행 시 생성된 디렉토리 내에 `destroy.log` 파일 자동 생성

## 프로젝트 구조

```
terraform/
├── modules/
│   ├── instance/          # 인스턴스 생성 메인 모듈
│   └── volume/            # 인스턴스 추가 디스크 모듈
├── credentials.json       # OpenStack 인증 정보
├── main.tf               # 인스턴스 생성 메인 코드
├── output.tf             # 인스턴스 생성 결과 출력 코드
├── provider.tf           # 프로바이더 설정 코드
├── ReadMe.md             # 문서화
├── run_terraform.sh      # 자동화 스크립트 파일
├── terraform.tfvars      # 인스턴스 생성용 변수 파일
└── variables.tf          # 변수 명세서
```

## terraform.tfvars 변수 설정

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| **인증 정보** | | |
| `credentials_file_path` | `"./credentials.json"` | OpenStack 인증 정보 파일 경로 |
| **네트워크 설정** | | |
| `network_name` | `"private"` | 인스턴스 연결용 내부 네트워크 |
| `subnet_name` | `"pri_sub"` | private 네트워크의 서브넷 |
| `external_network_name` | `"public"` | Floating IP용 외부 네트워크 |
| **보안 그룹 설정** | | |
| `security_group_names` | `["default"]` | 적용할 보안 그룹 목록 |
| `create_new_security_groups` | `false` | 보안 그룹이 존재하지 않을 경우 자동 생성 |
| `allowed_ssh_cidr` | `"192.168.1.0/24"` | SSH 접근 허용 CIDR 블록 (보안 강화) |
| `create_default_sg_rules` | `true` | 기본 보안 그룹 규칙 생성 |
| **인스턴스 설정** | | |
| `instance_name` | `"TEST-VM-created-by-terraform"` | 생성할 인스턴스 이름 |
| `image_uuid` | `"6bcc1303-48ac-4723-8d53-c88136c95be7"` | 사용할 이미지의 UUID |
| `flavor_id` | `"27008444-3320-46b6-9129-962666130aa9"` | 인스턴스 사양용 Flavor ID |
| **스토리지 설정** | | |
| `volume_size` | `20` | 루트 볼륨 크기 (GB) |
| `additional_volumes` | `[20]` | 추가 디스크 크기 (GB). 여러 개는 `[1,2,3,4]` 형태로 지정 |
| `volume_type` | `""` | 볼륨 타입 (예: "ssd", "standard" 또는 기본값으로 공백) |
| **리소스 사양** | | |
| `cpu` | `1` | CPU 개수 (flavor_id 지정 시 무시됨) |
| `memory` | `512` | 메모리 크기 (MB 단위, flavor_id 지정 시 무시됨) |
| `region` | `"RegionOne"` | OpenStack 리전 |
| **사용자 데이터** | | |
| `user_data_file_path` | `""` | 적용할 user-data 파일 경로 |
| **키페어 설정** | | |
| `use_keypair` | `true` | SSH 키페어 사용 여부 |
| `keypair_name` | `"key-pair"` | 키페어 이름 (create_new_keypair가 false일 때 사전 등록된 키페어 이름이어야 함) |
| `public_key_path` | `""` | 실제 공개키 파일 경로 (create_new_keypair가 false일 때 공백) |
| `create_new_keypair` | `false` | `true`: 새 키페어 생성, `false`: 기존 키페어 사용 |

## 주의사항

- `flavor_id`를 사용할 경우, `cpu`와 `memory` 설정은 flavor에서 정의되므로 무시됩니다
- 여러 개의 추가 볼륨의 경우, 크기를 배열로 지정하세요: `[10, 20, 30]`
- `create_new_keypair`가 `false`로 설정된 경우, 지정된 `keypair_name`이 OpenStack에 존재하는지 확인하세요
- `allowed_ssh_cidr`은 네트워크 보안 요구사항에 따라 구성해야 합니다