#!/bin/bash
#DEFAULT-PARAMETERS
echo "---------------[1] Parameters---------------"
read -p "Enter your EKS Cluster Name: " EKS_CLUSTER_NAME
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output json | jq '.Account' | sed 's/\"//g')
AWS_IAM_SA="aws-load-balancer-controller"
CONTROLLER_POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
CONTROLLER_VERSION="v2.1.3"
CHART_URL="https://aws.github.io/eks-charts"
#SERVICE-ACCOUNT-CREATION
echo "---------------[2] Service Account creation---------------"
eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster $EKS_CLUSTER_NAME \
    --approve
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/$CONTROLLER_VERSION/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name $CONTROLLER_POLICY_NAME \
    --policy-document file://iam_policy.json
eksctl create iamserviceaccount \
    --name=$AWS_IAM_SA \
    --namespace=kube-system \
    --cluster=$EKS_CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$CONTROLLER_POLICY_NAME \
    --override-existing-serviceaccounts \
    --approve
#HELM-INSTALLTION
echo "---------------[3] Helm installation---------------"
curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm version --short
helm repo add stable https://charts.helm.sh/stable --force-update
helm repo add eks $CHART_URL --force-update
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=$AWS_IAM_SA \
  -n kube-system
#CONTROLLER-VERIFICATION
sleep 20
echo "---------------[4] Controller verification---------------"
kubectl get deployment -n kube-system aws-load-balancer-controller
