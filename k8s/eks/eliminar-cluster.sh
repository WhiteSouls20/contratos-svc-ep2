#!/usr/bin/env bash
# EP3 — Elimina el cluster EKS para no consumir el presupuesto del Learner Lab (50 USD)
# entre sesiones. El control plane de EKS cobra por hora aunque los nodos esten apagados.
set -euo pipefail
CLUSTER="${CLUSTER_NAME:-contratos-eks}"
REGION="${AWS_REGION:-us-east-1}"

if aws eks describe-nodegroup --cluster-name "$CLUSTER" --nodegroup-name nodos --region "$REGION" >/dev/null 2>&1; then
  aws eks delete-nodegroup --cluster-name "$CLUSTER" --nodegroup-name nodos --region "$REGION"
  aws eks wait nodegroup-deleted --cluster-name "$CLUSTER" --nodegroup-name nodos --region "$REGION"
fi
if aws eks describe-cluster --name "$CLUSTER" --region "$REGION" >/dev/null 2>&1; then
  aws eks delete-cluster --name "$CLUSTER" --region "$REGION"
  aws eks wait cluster-deleted --name "$CLUSTER" --region "$REGION"
fi
echo "Cluster $CLUSTER eliminado"
