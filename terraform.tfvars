# OpenStack 인증 정보 파일 경로
credentials_file_path = "./credentials.json"

# 네트워크 설정
network_name          = "private"    # 인스턴스가 연결될 내부 네트워크 (private)
subnet_name           = "pri_sub"    # private 네트워크의 서브넷
external_network_name = "public"     # Floating IP용 외부 네트워크 (public)

# 보안 그룹 설정
security_group_names         = ["default"]
create_new_security_groups = false  # 존재하지 않으면 자동 생성
allowed_ssh_cidr            = "192.168.1.0/24"  # 특정 네트워크에서만 SSH 허용 (보안 강화)
create_default_sg_rules     = true  # 기본 룰 생성

# 인스턴스 설정
instance_name = "HS-TEST-VM-created-by-terraform"
image_uuid    = "6bcc1303-48ac-4723-8d53-c88136c95be7"
flavor_id     = "27008444-3320-46b6-9129-962666130aa9"

# 스토리지 설정
volume_size        = 20
additional_volumes = [20]
volume_type        = ""  # 또는 "ssd", "standard" 등 사용 가능한 타입

# 리소스 사양
cpu    = 1
memory = 512
region = "RegionOne"

# 사용자 데이터
# user_data_file_path = "./root_login.sh"

# Keypair 설정 (SSH 로그인용)
use_keypair        = true
keypair_name       = "RIM_Oracle" # create_new_keypair가 false인 경우 사전에 등록되어 있는 key-pair 이름이어야 함
public_key_path    = ""  # 실제 public key 파일 경로로 변경, create_new_keypair가 false인 경우 ""
create_new_keypair =  false  # true: 새로 생성, false: 기존 것 사용