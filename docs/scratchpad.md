## Step 1 - Repo setup
Created the GitHub repo with terraform/, argocd/, k8s/, docs/ and .github/workflows/. Reused the existing Route 53 zone abdijalil.dev and added the subdomain eks.abdijalil.dev instead of creating a new domain.

## Step 2 - memos local build
Built memos locally to validate the app before containerizing it. The frontend must be built before the Go binary, because the Go build embeds the frontend output (otherwise: "No embeddable frontend found"). Default port is 8081, and build output and *.db files are in .gitignore.

## Step 3 - Postgres with Docker Compose
docker-compose.local.yml (local testing only) runs memos and Postgres together, with a healthcheck so memos waits for Postgres readiness and --driver/--dsn passed through command:. 13 tables in Postgres confirmed memos uses it instead of SQLite, and data survives down/up (only down -v deletes it).

## Step 4 - Dockerfile
Three stages: Node (frontend), Go (backend), Alpine (runtime, non-root). The pnpm install needs web/patches and pnpm-workspace.yaml copied in first and libc6-compat on Alpine, and the frontend writes to ../server/frontend/dist, so web/ and server/ must sit side by side. Alpine over scratch for a debug shell (see decisions.md).

## Step 5 - Push image to ECR
Built with --platform linux/amd64 (arm64 Mac, Intel EKS nodes; the Go build takes about 4 minutes under emulation). Pushed to ECR repo memos (us-east-2, immutable tags, scan on push) as tag cf084ac, the git commit hash.

## Step 6 - Remote state
Created the S3 state bucket by hand (versioned, encrypted, public access blocked), because the backend must exist before Terraform can use it, and it is excluded from teardown. Locking uses native S3 locking (use_lockfile), so DynamoDB is not needed (the table I created was deleted unused).

## Step 7 - Terraform: VPC and IAM modules
Terraform v1.16.4 and AWS provider ~> 6.24 (needed for the regional NAT gateway), with default_tags in provider.tf and the lock file committed. The vpc module builds 3 public and 3 private subnets from a locals map with for_each, an internet gateway, one regional NAT gateway and two route tables. The iam module builds a cluster role (AmazonEKSClusterPolicy) and a node role (three managed policies, no instance profile, since the managed node group creates one).

## Step 7 (continued) - sg, eks, root module
The sg module creates a node security group with ingress TCP 30000-32767 from each public subnet CIDR, using CIDRs because the load balancer is created later by Traefik and has no known security group ID. The eks module creates the cluster (public and private endpoint), a launch template attaching the node SG and the EKS cluster SG, and a managed node group in the private subnets, with depends_on on the iam outputs and NAT gateway. The root module wires the modules through outputs, and variables.tf has no defaults, with values in terraform.tfvars. First apply created 30 resources with 3 nodes Ready on Kubernetes 1.37, then it was destroyed.

## Step 8 - ArgoCD via Terraform
Added the hashicorp/helm provider (~> 3.0, installed 3.3.0), authenticating to the cluster with the endpoint, the decoded CA and an aws eks get-token exec. A helm_release installs argo-cd chart 10.10.5 into the argocd namespace with depends_on module.eks, and all 7 pods reached Running.

## Step 9 - Secrets groundwork (not applied yet)
Wrote k8s/namespaces/memos.yaml, one namespace for memos and Postgres, and added an OIDC provider to the eks module (with oidc_provider_arn and oidc_provider_url outputs) to enable IRSA. The external-secrets module creates an IAM role trusted only by the service account external-secrets/external-secrets, allowed GetSecretValue and DescribeSecret on memos-eks/prod/* only. The secret itself will be created once with the AWS CLI, so the password never enters Terraform state.

## Step 10 - Disk driver and DNS role (not applied yet)
The eks module now installs the EBS CSI driver as an EKS add-on with an IRSA role (AmazonEBSCSIDriverPolicy, trusting ebs-csi-controller-sa in kube-system) and depends_on the node group; EBS volumes are single-AZ, and a StorageClass is still needed in the Postgres manifests. The external-dns module creates an IRSA role for the service account external-dns/external-dns with ChangeResourceRecordSets scoped to the abdijalil.dev zone (found with a data lookup). ExternalDNS must be restricted to eks.abdijalil.dev at install time, since that zone also holds the earlier project's records.

## Step 11 - First full run
Created the Postgres password once in AWS Secrets Manager (memos-eks/prod/postgres, JSON key `password`, random hex from openssl), so it never touches git or Terraform state. `terraform apply` built 39 resources, the two role ARN outputs matched the ArgoCD files, and applying `app-of-apps.yaml` made ArgoCD create all five Applications.

## Step 12 - Fixes during the first sync
Two Applications showed Unknown because `targetRevision` was still a placeholder, so I pinned real chart versions (external-dns 1.23.0, kube-prometheus-stack 92.17.1; external-secrets 2.14.0, traefik 42.2.0). memos stayed 0/1 Ready because Kubernetes injects a MEMOS_PORT variable from the memos Service, so memos read port 0; `enableServiceLinks: false` fixed it. ExternalDNS created nothing until domainFilters matched the zone name (abdijalil.dev, not eks.abdijalil.dev), then it created the A, AAAA and two TXT ownership records.

## Step 13 - HTTPS certificate (open)
Traefik requested the Let's Encrypt certificate before DNS existed (NXDOMAIN), then again seconds after a restart, before the pod was routable (connection refused), and it does not retry on its own. curl later completed a TLS handshake on 443, so the network path and security group are fine; the next attempt should be triggered while Traefik is already running, not by restarting it.

## Step 14 - Teardown order
Scale the ArgoCD controller to 0, delete the Ingress (ExternalDNS removes the records), delete the Traefik Service (removes the load balancer), delete the apps and their PVCs, check `kubectl get pv` is empty, then `terraform destroy` (39 destroyed). The PVCs must go first, or the EBS disks stay in the account and keep billing.