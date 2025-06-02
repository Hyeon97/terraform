output "instance_directory" {
  description = "생성된 인스턴스 디렉토리 경로"
  value       = var.instance_name
}

output "created_files" {
  description = "생성된 파일 목록"
  value = {
    instance_info_file    = "${var.instance_name}/instance_info.json"
    terraform_backup     = "${var.instance_name}/terraform_state_backup.txt"
    creation_log        = "${var.instance_name}/creation.log"
  }
}

output "ssh_command" {
  description = "SSH 접속 명령어"
  value = var.use_keypair ? (
    "ssh -i ${var.keypair_name} ubuntu@${var.external_ip}"
  ) : (
    "ssh ubuntu@${var.external_ip}"
  )
}