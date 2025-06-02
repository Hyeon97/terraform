# Terraform OpenStack Instance Management Guide

## Command

### Instance Creation and Management Workflow
```txt
# Instance Creation
1. plan: Validates current instance configuration through plan execution
2. apply: Creates instance using validated configuration from plan

# Instance Deletion
1. destroy: Removes created instances
```

### Using run_terraform.sh Script
```bash
1. run_terraform.sh plan
2. run_terraform.sh apply
```

### Direct Terraform Commands
```bash
terraform plan --var-file "/path/to/terraform.tfvars"
terraform apply --var-file "/path/to/terraform.tfvars" --auto-approve
```

## Execution Details

### Plan Command Execution
- Automatically creates directory named after `instance_name` value specified in terraform.tfvars
- Automatically generates `plan.log` and `plan.tfplan` files within the directory
- Automatically copies `credentials.json` and `terraform.tfvars` files for instance creation

### Apply Command Execution
- Automatically generates `apply.log` file within the directory created during plan execution
- Creates `backend.tf` and `credentials.json` files upon completion (success/failure)
- Creates `instance_info.json` and `terraform_state_backup.txt` files upon successful completion

### Destroy Command Execution
- Automatically generates `destroy.log` file within the directory created during plan execution

## Project Structure

```
terraform/
├── modules/
│   ├── instance/          # Main module for instance creation
│   └── volume/            # Additional disk module for instances
├── credentials.json       # OpenStack authentication credentials
├── main.tf                # Main instance creation code
├── output.tf              # Instance creation output code
├── provider.tf            # Provider configuration code
├── ReadMe.md              # Documentation
├── run_terraform.sh       # Automation script file
├── terraform.tfvars       # Variable file for instance creation
└── variables.tf           # Variable specification file
```

## terraform.tfvars Variable Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| **Authentication** | | |
| `credentials_file_path` | `"./credentials.json"` | Path to OpenStack authentication credentials file |
| **Network Configuration** | | |
| `network_name` | `"private"` | Internal network for instance connection |
| `subnet_name` | `"pri_sub"` | Subnet of the private network |
| `external_network_name` | `"public"` | External network for Floating IP |
| **Security Group Settings** | | |
| `security_group_names` | `["default"]` | List of security groups to apply |
| `create_new_security_groups` | `false` | Auto-create if security groups don't exist |
| `allowed_ssh_cidr` | `"192.168.1.0/24"` | CIDR block allowed for SSH access (security enhancement) |
| `create_default_sg_rules` | `true` | Create default security group rules |
| **Instance Configuration** | | |
| `instance_name` | `"TEST-VM-created-by-terraform"` | Name of the instance to create |
| `image_uuid` | `"6bcc1303-48ac-4723-8d53-c88136c95be7"` | UUID of the image to use |
| `flavor_id` | `"27008444-3320-46b6-9129-962666130aa9"` | Flavor ID for instance specifications |
| **Storage Configuration** | | |
| `volume_size` | `20` | Root volume size (GB) |
| `additional_volumes` | `[20]` | Additional disk sizes (GB). Use `[1,2,3,4]` for multiple disks |
| `volume_type` | `""` | Volume type (e.g., "ssd", "standard", or empty for default) |
| **Resource Specifications** | | |
| `cpu` | `1` | Number of CPUs (ignored when flavor_id is specified) |
| `memory` | `512` | Memory size in MB (ignored when flavor_id is specified) |
| `region` | `"RegionOne"` | OpenStack region |
| **User Data** | | |
| `user_data_file_path` | `""` | Path to user-data file to apply |
| **Keypair Configuration** | | |
| `use_keypair` | `true` | Whether to use SSH keypair |
| `keypair_name` | `"key-pair"` | Name of keypair (must be pre-registered when create_new_keypair is false) |
| `public_key_path` | `""` | Path to actual public key file (empty when create_new_keypair is false) |
| `create_new_keypair` | `false` | `true`: Create new keypair, `false`: Use existing keypair |

## Notes

- When using `flavor_id`, the `cpu` and `memory` settings are ignored as they are defined by the flavor
- For multiple additional volumes, specify sizes as an array: `[10, 20, 30]`
- Ensure the specified `keypair_name` exists in OpenStack when `create_new_keypair` is set to `false`
- The `allowed_ssh_cidr` should be configured according to your network security requirements