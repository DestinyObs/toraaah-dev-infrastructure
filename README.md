# Toraaah Dev Infrastructure - Terraform

Infrastructure as Code for the Toraaah development server.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with credentials
- Access to AWS account `850782150363`

## Initial Setup - Importing Existing Resources

This infrastructure imports existing AWS resources into Terraform management.

### Step 1: Initialize Terraform

```powershell
cd c:\Users\Desti\toraaah_dev_infra
terraform init
```

### Step 2: Get Resource IDs

Get the Elastic IP allocation ID:
```powershell
aws ec2 describe-addresses --filters "Name=public-ip,Values=52.14.115.188" --region us-east-2 --query "Addresses[0].AllocationId" --output text
```

Get the EIP Association ID:
```powershell
aws ec2 describe-addresses --filters "Name=public-ip,Values=52.14.115.188" --region us-east-2 --query "Addresses[0].AssociationId" --output text
```

### Step 3: Import Resources

Replace the placeholders with your actual IDs:

```powershell
# Import Elastic IP
terraform import aws_eip.dev_eip <ALLOCATION_ID>

# Import EC2 Instance
terraform import aws_instance.dev_server i-0756a27c9a873ff4a

# Import EIP Association
terraform import aws_eip_association.dev_eip_assoc <ASSOCIATION_ID>
```

### Step 4: Create Security Group

```powershell
terraform plan
terraform apply
```

This will create the new secure security group.

### Step 5: Update Instance Security Group

After the security group is created, update the instance:

```powershell
# Get the new security group ID
$SG_ID = terraform output -raw security_group_id

# Apply it to the instance
aws ec2 modify-instance-attribute --instance-id i-0756a27c9a873ff4a --groups $SG_ID --region us-east-2
```

### Step 6: Verify

```powershell
terraform plan
# Should show: No changes
```

## Security Improvements Made

### 1. Security Group
- **Before**: 10+ ports open to 0.0.0.0/0 including PostgreSQL, Redis, Elasticsearch
- **After**: Only ports 22, 80, 443 exposed
  - Port 22 (SSH): Restricted to specific IP (update `allowed_ssh_cidr` in variables.tf)
  - Port 80 (HTTP): For Let's Encrypt and HTTPS redirect only
  - Port 443 (HTTPS): For application access

### 2. Docker Port Bindings
All internal services must bind to `127.0.0.1` instead of `0.0.0.0`:

**Before** (INSECURE):
```yaml
postgres:
  ports:
    - "5433:5432"  # Exposed to internet!
```

**After** (SECURE):
```yaml
postgres:
  ports:
    - "127.0.0.1:5433:5432"  # Localhost only
```

Services that need this fix:
- PostgreSQL (port 5433)
- Redis (port 6379)
- Backend web (port 8000)
- Frontend apps (ports 3000, 3001, 3002)
- GTM containers (ports 8081, 8082)

Only nginx should bind to `0.0.0.0` on ports 80 and 443.

## Updating Configuration

To get your current IP for SSH restriction:
```powershell
(Invoke-WebRequest -Uri "https://api.ipify.org").Content
```

Update `variables.tf`:
```hcl
variable "allowed_ssh_cidr" {
  default = "YOUR_IP/32"  # Replace with your IP
}
```

Then apply:
```powershell
terraform apply
```

## Outputs

```powershell
terraform output
```

Shows:
- `instance_id`: EC2 instance ID
- `instance_public_ip`: Public IP address
- `security_group_id`: New security group ID
- `ssh_command`: Command to SSH into the server

## AWS Abuse Response

After completing these steps, respond to AWS with:

```
Subject: Re: Your AWS Abuse Report [10468407181]

Hello AWS Trust & Safety,

We have investigated and resolved the reported abuse incident:

Root Cause:
- Overly permissive security groups exposing PostgreSQL (5432) and Redis (6379) to the internet
- Docker containers bound to 0.0.0.0 instead of localhost

Actions Taken:
1. Stopped compromised instance (i-0756a27c9a873ff4a)
2. Created forensic AMI backup (ami-0d0e36b91e653afa2)
3. Implemented new security group with only ports 22, 80, 443 exposed
4. Fixed Docker port bindings to localhost only (127.0.0.1)
5. Deployed infrastructure as code (Terraform) for consistent security
6. Restarted services with secure configuration
7. Enabled IMDSv2 enforcement

Preventive Measures:
- All infrastructure now managed via Terraform
- Security group changes require code review
- Regular security audits scheduled
- Monitoring enabled for unusual traffic patterns

The instance has been secured and is running with proper network isolation.

Please remove the port 80 UDP block on our account.

Best regards,
DevOps Team
```

## Troubleshooting

### AMI not found
If the AMI isn't ready yet, wait for status to be "Available" in AWS Console.

### Instance state mismatch
If Terraform shows changes to the instance, you may need to refresh state:
```powershell
terraform refresh
```

### Security group update fails
Ensure the instance is stopped before changing security groups, or use the AWS CLI command provided in Step 5.
