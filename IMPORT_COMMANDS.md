# Terraform Import Commands

## Quick Start

```bash
cd /mnt/c/Users/Desti/toraaah_dev_infra

# Make script executable


# Run the import script
./import-resources.sh
```

## Manual Commands (if needed)

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Import Elastic IP
```bash
# Get the allocation ID first
aws ec2 describe-addresses \
  --filters "Name=public-ip,Values=52.14.115.188" \
  --region us-east-2 \
  --query 'Addresses[0].AllocationId' \
  --output text

# Import (use the ID from above)
terraform import aws_eip.dev_eip <ALLOCATION_ID>
```

### 3. Import EC2 Instance
```bash
terraform import aws_instance.dev_server i-0756a27c9a873ff4a
```

### 4. Import EIP Association (if instance is running)
```bash
# Get the association ID first
aws ec2 describe-addresses \
  --filters "Name=public-ip,Values=52.14.115.188" \
  --region us-east-2 \
  --query 'Addresses[0].AssociationId' \
  --output text

# Import (use the ID from above)
terraform import aws_eip_association.dev_eip_assoc <ASSOCIATION_ID>
```

### 5. Verify Import
```bash
terraform state list
```

Should show:
- aws_eip.dev_eip
- aws_eip_association.dev_eip_assoc
- aws_instance.dev_server
- aws_security_group.dev_server_sg

### 6. Plan Changes
```bash
terraform plan
```

### 7. Apply Changes (create new security group and update instance)
```bash
terraform apply
```

## What This Does

1. **Imports existing resources** into Terraform state without recreating them
2. **Creates a NEW secure security group** with proper restrictions
3. **Updates the instance** to use the new security group
4. **Keeps your AMI** (ami-0d0e36b91e653afa2) and existing instance

## After Import

The instance will be updated with:
- ✅ New secure security group (only ports 22, 80, 443)
- ✅ SSH restricted to your IP (update in main.tf)
- ✅ Same instance, same data, same AMI
- ✅ Managed by Terraform going forward
