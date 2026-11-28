#!/usr/bin/env bash
# EP3 / IE2 — Crea el cluster EKS en AWS Academy Learner Lab.
# Lo ejecuta el workflow "Infraestructura EKS" (.github/workflows/infra-eks.yml), no una persona.
# Learner Lab no permite crear roles IAM: cluster y nodos usan el rol existente "LabRole".
set -euo pipefail

CLUSTER="${CLUSTER_NAME:-contratos-eks}"
REGION="${AWS_REGION:-us-east-1}"
NODE_TYPE="${NODE_TYPE:-t3.medium}"
NODES="${NODES:-3}"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT}:role/LabRole"

# VPC por defecto; EKS no admite la zona us-east-1e
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)
SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'Subnets[?AvailabilityZone!=`us-east-1e`].SubnetId' --output text | tr '\t' ' ')
SUBNETS_CSV=$(echo "$SUBNETS" | tr ' ' ',')
echo "Cuenta=$ACCOUNT VPC=$VPC_ID Subnets=$SUBNETS_CSV"

if aws eks describe-cluster --name "$CLUSTER" --region "$REGION" >/dev/null 2>&1; then
  echo "El cluster $CLUSTER ya existe"
else
  aws eks create-cluster --region "$REGION" --name "$CLUSTER" \
    --role-arn "$ROLE_ARN" \
    --resources-vpc-config subnetIds="$SUBNETS_CSV",endpointPublicAccess=true \
    --access-config authenticationMode=API_AND_CONFIG_MAP,bootstrapClusterCreatorAdminPermissions=true \
    --tags proyecto=ep3,app=contratos-svc
fi
echo "Esperando que el control plane quede ACTIVE (10-15 min)..."
aws eks wait cluster-active --name "$CLUSTER" --region "$REGION"

if aws eks describe-nodegroup --cluster-name "$CLUSTER" --nodegroup-name nodos --region "$REGION" >/dev/null 2>&1; then
  echo "El nodegroup ya existe"
else
  # shellcheck disable=SC2086
  aws eks create-nodegroup --region "$REGION" --cluster-name "$CLUSTER" \
    --nodegroup-name nodos --node-role "$ROLE_ARN" \
    --subnets $SUBNETS \
    --instance-types "$NODE_TYPE" --capacity-type ON_DEMAND \
    --scaling-config minSize=2,maxSize="$NODES",desiredSize="$NODES" \
    --tags proyecto=ep3
fi
echo "Esperando nodos (5 min aprox.)..."
aws eks wait nodegroup-active --cluster-name "$CLUSTER" --nodegroup-name nodos --region "$REGION"

aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION"
kubectl get nodes -o wide
