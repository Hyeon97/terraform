[Command]
terraform init
terraform plan    --var-file "./terraform.json"
terraform apply   --var-file "./terraform.json" --auto-approve
terraform destroy --var-file "./terraform.json" --auto-approve
terraform fmt -recursive

openstack에서는 테라폼이 병신이라
각 모듈 상단에
```
terraform {
  # required_version = ">= 1.4.0"
  required_providers {
    openstack = {
        source = "terraform-provider-openstack/openstack"
    }
  }
}
```
선언 해줘야 하며
모듈 선언시
```
providers = {
  openstack = openstack
}
```
를 무조건 붙여줘야함


[error]
> become ready: unexpected state 'ERROR', wanted target 'ACTIVE'. last error: %!s(<nil>)
  - vm 생성에 필요한 리소스 부족
