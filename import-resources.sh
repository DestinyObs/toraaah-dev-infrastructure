#!/bin/bash
# Terraform Import Script
# Run this to import existing AWS resources into Terraform state

set -e

echo "========================================"
echo "Terraform Import Script for Dev Server"
echo "========================================"
echo ""

# Change to the directory containing this script
cd "$(dirname "$0")"

# Step 1: Initialize Terraform (if not already done)
echo "Step 0: Initializing Terraform..."
terraform init

# Step 2: Get Elastic IP Allocation ID
echo ""
echo "Step 1: Getting Elastic IP Allocation ID..."
EIP_ALLOC_ID=$(aws ec2 describe-addresses \
  --filters "Name=public-ip,Values=52.14.115.188" \
  --region us-east-2 \
  --query 'Addresses[0].AllocationId' \
  --output text)

if [ -n "$EIP_ALLOC_ID" ] && [ "$EIP_ALLOC_ID" != "None" ]; then
    echo "Found EIP Allocation ID: $EIP_ALLOC_ID"
else
    echo "ERROR: Could not find EIP Allocation ID"
    exit 1
fi

# Step 3: Import Elastic IP
echo ""
echo "Step 2: Importing Elastic IP..."
terraform import aws_eip.dev_eip "$EIP_ALLOC_ID" || echo "Already imported or failed"

# Step 4: Import EC2 Instance
echo ""
echo "Step 3: Importing EC2 Instance..."
terraform import aws_instance.dev_server i-0756a27c9a873ff4a || echo "Already imported or failed"

# Step 5: Get EIP Association ID
echo ""
echo "Step 4: Getting EIP Association ID..."
EIPASSOC_ID=$(aws ec2 describe-addresses \
  --filters "Name=public-ip,Values=52.14.115.188" \
  --region us-east-2 \
  --query 'Addresses[0].AssociationId' \
  --output text)

if [ -n "$EIPASSOC_ID" ] && [ "$EIPASSOC_ID" != "None" ]; then
    echo "Found EIP Association ID: $EIPASSOC_ID"
    
    # Step 6: Import EIP Association
    echo ""
    echo "Step 5: Importing EIP Association..."
    terraform import aws_eip_association.dev_eip_assoc "$EIPASSOC_ID" || echo "Already imported or failed"
else
    echo "WARNING: Could not find EIP Association ID"
    echo "This is normal if the instance is stopped"
fi

echo ""
echo "========================================"
echo "Import Complete!"
echo "========================================"
echo ""
echo "Next Steps:"
echo "1. Run: terraform plan"
echo "2. Review the changes"
echo "3. Run: terraform apply"
echo ""
