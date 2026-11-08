# Terraform for finaltask

Two separate Terraform folders. Each one has its own state and is applied on its own.

```
terraform/
├── eks/   1. Infrastructure: VPC + EKS cluster + worker nodes   (apply once, rarely changes)
└── app/   2. Application:   Namespace + Deployment + Service    (apply on every new version)
```

**Why two folders?** The `app/` folder talks to Kubernetes, which only works once the
cluster exists. Keeping them apart avoids that chicken-and-egg problem, and it is a common
real-world pattern: infrastructure changes rarely, the app is redeployed often.

## What gets created

**`eks/`** (uses the official `terraform-aws-modules` modules)

| Resource | What it does |
|----------|--------------|
| VPC with 2 public + 2 private subnets in 2 AZs | Our own private network, spread over 2 data centers |
| 1 NAT gateway | Lets the private nodes reach the internet (e.g. to pull images) |
| EKS cluster `ugergo-finaltask` | The managed Kubernetes control plane |
| Managed node group: 2 × `t3.small` | The machines that run our pods; allowed to pull from ECR |

**`app/`**

| Resource | What it does |
|----------|--------------|
| Namespace `finaltask` | A separate "folder" in the cluster for our app |
| Deployment `finaltask` | Runs 2 pods of our nginx + React image and restarts them if they crash |
| Service `finaltask` | One stable in-cluster address that load-balances between the pods |

## Cost - remember to destroy!

While `eks/` is applied, AWS bills roughly **$0.20/hour (~$5/day, ~$145/month)**:
EKS control plane ~$0.10/h, NAT gateway ~$0.05/h, 2 × t3.small ~$0.05/h.

## Step by step

### 1. Create the cluster (~15-20 minutes)

```bash
cd terraform/eks
terraform init      # download the AWS provider and modules (only needed once)
terraform plan      # preview - nothing is created yet
terraform apply     # create everything (type "yes" to confirm)
```

### 2. Connect kubectl to the new cluster

```bash
aws eks update-kubeconfig --region eu-central-1 --name ugergo-finaltask
kubectl get nodes   # should list 2 nodes with STATUS "Ready"
```

### 3. Deploy the app

```bash
cd ../app
cp terraform.tfvars.example terraform.tfvars   # check image_tag
terraform init
terraform plan
terraform apply
kubectl -n finaltask get pods                  # should show 2 Running pods
```

### 4. Open the app

```bash
kubectl -n finaltask port-forward service/finaltask 8080:80
```
Then visit <http://localhost:8080>.

## Deploying a new version

Every push to `main` builds an image tagged with the commit SHA. List the tags with:
```bash
aws ecr describe-images --repository-name ugergo/finaltask --query 'imageDetails[].imageTags' --output text
```
Put the new tag into `app/terraform.tfvars` and run `terraform apply` in `app/`.
Kubernetes replaces the pods one by one (a "rolling update"), so the app stays available.

## Removing everything (in reverse order!)

```bash
cd terraform/app && terraform destroy   # first the app...
cd ../eks        && terraform destroy   # ...then the cluster (~10-15 minutes)
```
Destroy `app/` first: if the cluster is deleted first, the app's Terraform state points
at a cluster that no longer exists.

## Files in each folder

| File | Purpose |
|------|---------|
| `versions.tf` | Required Terraform/provider versions and how to connect (AWS or Kubernetes) |
| `variables.tf` | Settings you can change |
| `main.tf` | The resources themselves |
| `outputs.tf` | Values printed after apply |
| `.terraform.lock.hcl` | Pins exact provider versions - commit this file |
| `app/terraform.tfvars.example` | Example values - copy to `terraform.tfvars` |
