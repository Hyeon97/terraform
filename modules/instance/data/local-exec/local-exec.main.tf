terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

# 현재 시간 가져오기
resource "time_static" "creation_time" {}

# 인스턴스 디렉토리 생성
resource "null_resource" "create_instance_directory" {
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p "${var.instance_name}"
      echo "==================================================" > "${var.instance_name}/creation.log"
      echo "Terraform Apply Started: $(date)" >> "${var.instance_name}/creation.log"
      echo "Instance Name: ${var.instance_name}" >> "${var.instance_name}/creation.log"
      echo "==================================================" >> "${var.instance_name}/creation.log"
    EOT
  }
  
  triggers = {
    instance_name = var.instance_name
    timestamp     = time_static.creation_time.id
  }
}

# 인스턴스 정보 파일 생성
resource "local_file" "instance_info" {
  depends_on = [null_resource.create_instance_directory]
  
  filename = "${var.instance_name}/instance_info.json"
  content = jsonencode({
    instance_name      = var.instance_name
    creation_time      = time_static.creation_time.rfc3339
    instance_id        = var.instance_id
    external_ip        = var.external_ip
    internal_ip        = var.internal_ip
    flavor_name        = var.flavor_name
    image_uuid         = var.image_uuid
    security_groups    = var.security_groups
    keypair_name       = var.keypair_name
    network_info = {
      network_name = var.network_name
      subnet_name  = var.subnet_name
    }
    additional_volumes = var.additional_volumes
  })
  
  file_permission = "0644"
}

# Terraform 상태 백업
resource "local_file" "terraform_state_backup" {
  depends_on = [null_resource.create_instance_directory]
  
  filename = "${var.instance_name}/terraform_state_backup.txt"
  content = <<-EOT
# Terraform State Information for ${var.instance_name}
# Created: ${time_static.creation_time.rfc3339}

Instance ID: ${var.instance_id}
External IP: ${var.external_ip}
Internal IP: ${var.internal_ip}

# To destroy this instance:
terraform destroy -target="module.instance"

# To get instance info:
terraform output instance_info

# SSH Connection:
ssh -i ${var.keypair_name} ubuntu@${var.external_ip}
EOT
  
  file_permission = "0644"
}

# 상세 인스턴스 생성 로그 및 검증
resource "null_resource" "detailed_creation_log" {
  depends_on = [
    local_file.instance_info,
    local_file.terraform_state_backup
  ]
  
  provisioner "local-exec" {
    command = <<-EOT
      # 인스턴스 생성 완료 로그
      echo "==================================================" >> "${var.instance_name}/creation.log"
      echo "Instance Creation Completed: $(date)" >> "${var.instance_name}/creation.log"
      echo "Instance ID: ${var.instance_id}" >> "${var.instance_name}/creation.log"
      echo "External IP: ${var.external_ip}" >> "${var.instance_name}/creation.log"
      echo "Internal IP: ${var.internal_ip}" >> "${var.instance_name}/creation.log"
      echo "Flavor: ${var.flavor_name}" >> "${var.instance_name}/creation.log"
      echo "Image UUID: ${var.image_uuid}" >> "${var.instance_name}/creation.log"
      echo "Keypair: ${var.keypair_name}" >> "${var.instance_name}/creation.log"
      echo "Network: ${var.network_name}" >> "${var.instance_name}/creation.log"
      echo "Subnet: ${var.subnet_name}" >> "${var.instance_name}/creation.log"
      echo "Security Groups: ${join(", ", var.security_groups)}" >> "${var.instance_name}/creation.log"
      echo "==================================================" >> "${var.instance_name}/creation.log"
      
      # 생성된 파일 목록
      echo "" >> "${var.instance_name}/creation.log"
      echo "Created Files:" >> "${var.instance_name}/creation.log"
      ls -la "${var.instance_name}/" >> "${var.instance_name}/creation.log"
      echo "" >> "${var.instance_name}/creation.log"
      
      # OpenStack CLI로 인스턴스 상태 확인 (있는 경우)
      echo "OpenStack Instance Status Check:" >> "${var.instance_name}/creation.log"
      if command -v openstack >/dev/null 2>&1; then
        echo "Instance Details from OpenStack CLI:" >> "${var.instance_name}/creation.log"
        openstack server show ${var.instance_id} >> "${var.instance_name}/creation.log" 2>&1 || echo "OpenStack CLI command failed" >> "${var.instance_name}/creation.log"
        echo "" >> "${var.instance_name}/creation.log"
        
        echo "Floating IP Details:" >> "${var.instance_name}/creation.log"
        openstack floating ip list --server ${var.instance_id} >> "${var.instance_name}/creation.log" 2>&1 || echo "Floating IP list command failed" >> "${var.instance_name}/creation.log"
        echo "" >> "${var.instance_name}/creation.log"
        
        echo "Volume Attachments:" >> "${var.instance_name}/creation.log"
        openstack volume list --server ${var.instance_id} >> "${var.instance_name}/creation.log" 2>&1 || echo "Volume list command failed" >> "${var.instance_name}/creation.log"
      else
        echo "OpenStack CLI not available for status check" >> "${var.instance_name}/creation.log"
      fi
      
      echo "" >> "${var.instance_name}/creation.log"
      echo "==================================================" >> "${var.instance_name}/creation.log"
      echo "Terraform Apply Process Completed: $(date)" >> "${var.instance_name}/creation.log"
      echo "==================================================" >> "${var.instance_name}/creation.log"
      
      # 네트워크 연결성 테스트
      echo "" >> "${var.instance_name}/creation.log"
      echo "Network Connectivity Test:" >> "${var.instance_name}/creation.log"
      if ping -c 3 ${var.external_ip} >/dev/null 2>&1; then
        echo "✓ External IP ${var.external_ip} is reachable" >> "${var.instance_name}/creation.log"
      else
        echo "✗ External IP ${var.external_ip} is not reachable (may need time to initialize)" >> "${var.instance_name}/creation.log"
      fi
      
      # SSH 연결 테스트 (키 파일이 있는 경우)
      if [ "${var.use_keypair}" = "true" ] && [ -f "${var.keypair_name}" ]; then
        echo "SSH Connectivity Test:" >> "${var.instance_name}/creation.log"
        timeout 10 ssh -i ${var.keypair_name} -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@${var.external_ip} 'echo "SSH connection successful"' >> "${var.instance_name}/creation.log" 2>&1 || echo "SSH connection test failed (instance may still be initializing)" >> "${var.instance_name}/creation.log"
      fi
      
      echo "" >> "${var.instance_name}/creation.log"
      echo "Log completed at: $(date)" >> "${var.instance_name}/creation.log"
    EOT
  }
  
  triggers = {
    instance_id = var.instance_id
    external_ip = var.external_ip
    timestamp   = timestamp()
  }
}

# 인스턴스 삭제 시 로그
resource "null_resource" "log_destruction" {
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      if [ -d "${self.triggers.instance_name}" ]; then
        echo "==================================================" >> "${self.triggers.instance_name}/deletion.log"
        echo "Instance Deletion Started: $(date)" >> "${self.triggers.instance_name}/deletion.log"
        echo "Instance ID: ${self.triggers.instance_id}" >> "${self.triggers.instance_name}/deletion.log"
        echo "==================================================" >> "${self.triggers.instance_name}/deletion.log"
        
        # 삭제 전 최종 상태 확인
        if command -v openstack >/dev/null 2>&1; then
          echo "Final instance status before deletion:" >> "${self.triggers.instance_name}/deletion.log"
          openstack server show ${self.triggers.instance_id} >> "${self.triggers.instance_name}/deletion.log" 2>&1 || echo "Instance already deleted or CLI error" >> "${self.triggers.instance_name}/deletion.log"
        fi
        
        echo "Deletion completed at: $(date)" >> "${self.triggers.instance_name}/deletion.log"
        echo "==================================================" >> "${self.triggers.instance_name}/deletion.log"
      fi
    EOT
  }
  
  triggers = {
    instance_name = var.instance_name
    instance_id   = var.instance_id
  }
}