# AWS EKS Production Infrastructure Setup Guide

## Architecture Overview

This project provisions and configures a production-ready AWS infrastructure for Kubernetes applications using Amazon EKS.

### Components

* VPC
* Security Groups
* Bastion Host
* VPN (Optional)
* Amazon EKS
* Amazon RDS MySQL
* AWS Certificate Manager (ACM)
* AWS Load Balancer Controller (ALB Ingress)
* Amazon ECR
* CDN (Optional)

---

# Infrastructure Creation Sequence

The resources must be created in the following order:

| Order | Component                    | Required |
| ----- | ---------------------------- | -------- |
| 1     | VPC                          | Yes      |
| 2     | Security Groups              | Yes      |
| 3     | Bastion Host                 | Yes      |
| 4     | VPN                          | Optional |
| 5     | Amazon RDS                   | Yes      |
| 6     | ACM Certificate              | Yes      |
| 7     | EKS Cluster                  | Yes      |
| 8     | AWS Load Balancer Controller | Yes      |
| 9     | Amazon ECR                   | Yes      |
| 10    | CDN                          | Optional |

---

# 1. Create VPC

Create:

* Public Subnets
* Private Subnets
* Internet Gateway
* NAT Gateway
* Route Tables

Example CIDR:

| Resource         | CIDR         |
| ---------------- | ------------ |
| VPC              | 10.0.0.0/16  |
| Public Subnet A  | 10.0.1.0/24  |
| Public Subnet B  | 10.0.2.0/24  |
| Private Subnet A | 10.0.11.0/24 |
| Private Subnet B | 10.0.12.0/24 |

---

# 2. Create Security Groups

Create Security Groups for:

* Bastion Host
* EKS Cluster
* Worker Nodes
* RDS
* ALB

Configure required inbound and outbound rules.

---

# 3. Create Bastion Host

Purpose:

* Connect to EKS Cluster
* Connect to RDS
* Run kubectl commands
* Install DevOps tools

Required Tools:

```bash
aws
kubectl
helm
eksctl
terraform
git
```

---

# 4. Optional VPN

VPN allows developers to connect securely from local laptops without SSHing into Bastion Host.

---

# 5. Create Amazon RDS

Recommended:

* Engine: MySQL 8.x
* Multi-AZ: Enabled
* Backup: Enabled

Create database:

```sql
CREATE DATABASE expense;
```

Connect from Bastion Host:

```bash
mysql -h <RDS-ENDPOINT> -u root -p
```

Import schema:

```sql
SOURCE backend.sql;
```

Verify:

```sql
SHOW TABLES;
```

---

# 6. Create ACM Certificate

Request SSL certificate:

```bash
aws acm request-certificate \
--domain-name example.com \
--validation-method DNS
```

Validate certificate through Route53.

---

# 7. Create Amazon EKS Cluster

Configure kubectl:

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name <cluster-name>
```

Verify:

```bash
kubectl get nodes
```

Expected:

```bash
NAME                     STATUS
ip-10-0-1-100.ec2.internal Ready
ip-10-0-2-100.ec2.internal Ready
```

---

# 8. Install AWS Load Balancer Controller

## Associate IAM OIDC Provider

```bash
eksctl utils associate-iam-oidc-provider \
--region us-east-1 \
--cluster <cluster-name> \
--approve
```

---

## Download IAM Policy

```bash
curl -o iam-policy.json \
https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.1/docs/install/iam_policy.json
```

---

## Create IAM Policy

```bash
aws iam create-policy \
--policy-name AWSLoadBalancerControllerIAMPolicy \
--policy-document file://iam-policy.json
```

---

## Create IAM Service Account

Get AWS Account ID:

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
--query Account \
--output text)
```

Create Service Account:

```bash
eksctl create iamserviceaccount \
--cluster=<cluster-name> \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--approve
```

---

## Install Helm Chart

Add repository:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

Install controller:

```bash
helm install aws-load-balancer-controller \
eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=<cluster-name> \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller
```

Verify:

```bash
kubectl get pods -n kube-system
```

Expected:

```bash
aws-load-balancer-controller-xxxxx Running
aws-load-balancer-controller-yyyyy Running
```

---

# 9. Create Amazon ECR Repository

Create repository:

```bash
aws ecr create-repository \
--repository-name expense-backend
```

Login:

```bash
aws ecr get-login-password \
| docker login \
--username AWS \
--password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

Push image:

```bash
docker build -t expense-backend .

docker tag expense-backend:latest \
<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/expense-backend:latest

docker push \
<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/expense-backend:latest
```

---

# 10. Configure ALB Ingress

Example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: expense-ingress
  annotations:
    kubernetes.io/ingress.class: alb
spec:
  rules:
  - host: expense.example.com
```

Apply:

```bash
kubectl apply -f ingress.yaml
```

Verify:

```bash
kubectl get ingress
```

---

# Optional CDN

Use Amazon CloudFront in front of:

* ALB
* S3 Static Websites
* Frontend Applications

Benefits:

* Global Caching
* Reduced Latency
* Enhanced Security

---

# Verification Checklist

```bash
kubectl get nodes
kubectl get pods -A
kubectl get ingress
kubectl get svc
kubectl get deployments
```

Infrastructure is ready when:

* EKS nodes are Ready
* RDS is reachable
* ALB Controller is Running
* Ingress creates ALB successfully
* Images are pushed to ECR
* Application is accessible through HTTPS

```
```
