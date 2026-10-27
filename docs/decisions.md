## App choice: memos + Postgres
memos with a dedicated Postgres database, instead of SQLite or a static app. A second service forces a real internal-vs-external traffic boundary: Postgres is a ClusterIP Service and is never exposed through the Ingress.

## Single environment for now
One environment (prod) instead of dev/staging/prod. Multi-environment (for example staging auto-sync and prod manual sync) is deferred to keep the first full build achievable.

## Domain: existing hosted zone, new subdomain
Reused the Route 53 zone abdijalil.dev and add only eks.abdijalil.dev, which ExternalDNS manages. No new hosted zone is needed.

## Custom Docker image built from source
Built memos from its source with my own Dockerfile instead of wrapping the upstream image. That gives the CI/CD pipeline a real build-and-scan step.

## Docker image: three stages, Alpine final image
Stages are Node (frontend), Go (backend) and a runtime image with only the finished binary, running as non-root. Alpine over scratch because it has a shell for debugging on EKS; scratch is a possible later hardening step compared with Trivy results.

## Image tags: git commit hash, immutable in ECR
Images are tagged with the short commit hash (for example cf084ac), never latest, and ECR tag immutability is on. Each tag maps to one build, so rollbacks are a tag change, and the pipeline's tag commit is what triggers the ArgoCD deploy. Built with --platform linux/amd64 because the laptop is arm64 and the nodes are Intel.

## Terraform state: S3 with native locking, created outside Terraform
Versioned, encrypted S3 bucket with public access blocked, and locking via use_lockfile (Terraform 1.10+) instead of the deprecated DynamoDB locking. Created by hand because the backend must exist before Terraform runs, and kept out of teardown.

## Custom Terraform modules instead of the community VPC module
Modules are vpc, iam, sg, eks, external-secrets and external-dns. A custom VPC module keeps every resource visible in the repo, so I can explain and change each one. Subnet values come in as variables, are grouped in a locals map and created with for_each.

## Shared tags: default_tags in the provider
Project and ManagedBy are set once in provider.tf. Each resource only sets its own Name tag, so there is no merge() on every resource.

## Version pinning: Terraform 1.16.x, AWS ~> 6.24, Helm ~> 3.0
required_version is ~> 1.16.4 and the pipeline must match. AWS provider ~> 6.24 because the regional NAT gateway needs 6.24+. The lock file is committed so the laptop and the pipeline install identical provider versions.

## VPC: public/private split with one regional NAT gateway
Worker nodes run in private subnets and the Traefik load balancer lands in public subnets. A single regional NAT gateway covers all three AZs, so losing one zone doesn't cut outbound internet for the private subnets.

## Security groups: custom node SG on top of the EKS cluster SG
The EKS cluster SG already handles control-plane-to-node and node-to-node traffic, so I leave it alone. The custom node SG only allows TCP 30000-32767 from the three public subnet CIDRs (CIDRs because the load balancer is created later by Traefik, so there is no SG ID to reference), and no 0.0.0.0/0 on the nodes. Both SGs attach through a launch template, and the port range may need adjusting once Traefik is deployed.

## IAM: separate roles for the control plane and the nodes
The cluster role trusts eks.amazonaws.com with AmazonEKSClusterPolicy. The node role trusts ec2.amazonaws.com with AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy and AmazonEC2ContainerRegistryReadOnly. No instance profile in code, because the managed node group creates it. The role ARN outputs depend_on the policy attachments, so nothing uses a role before its policies exist.

## Root module: variables and tfvars, no defaults
environments/prod holds main.tf (module calls only), variables.tf (typed and described inputs), terraform.tfvars (values) and outputs.tf. Environment-specific values have no defaults, so a missing value fails the plan instead of silently using a default.

## Cluster sizing and version
Kubernetes 1.37, the newest version on EKS, because AWS recommends the latest for new clusters. Three t3.medium nodes (min 2, max 4), since ArgoCD, Traefik and kube-prometheus-stack share the nodes with the app.

## ArgoCD installed by Terraform
A helm_release in the root module with the chart version pinned (10.10.5), authenticated with the cluster endpoint, the decoded CA and an aws eks get-token exec. Terraform stops there, and everything else is ArgoCD's job.

## GitOps pattern: app-of-apps
Terraform creates the VPC, IAM, cluster and ArgoCD, then applies one bootstrap manifest (argocd/bootstrap/app-of-apps.yaml). Traefik, ExternalDNS, kube-prometheus-stack, ESO and the memos/Postgres app are managed only through ArgoCD, so there is one source of truth instead of two.

## Ingress and TLS: Traefik with built-in Let's Encrypt, no cert-manager
Traefik over NGINX Ingress, using its built-in ACME integration instead of cert-manager. Approved by the mentor, and it removes one moving part (no ClusterIssuer).

## CI/CD deploys via a Git commit, not kubectl or helm
The pipeline's last step updates the image tag in k8s/memos/deployment.yaml and commits it. ArgoCD detects the change and deploys, so Git and ArgoCD are the only things that touch the cluster.

## Monitoring: explicit dashboard coverage
The default kube-prometheus-stack dashboards cover node and pod health but not Ingress traffic. A community Traefik dashboard is added to cover all four required areas: CPU/memory, pod health, node status and Ingress traffic.

## First deploy by hand, then destroyed
I ran the first apply from my laptop to find problems before writing the pipeline, then destroyed everything to avoid cost. The pipeline will repeat the same init, plan and apply. The state bucket and ECR repo are outside this state and survive a destroy.

## One namespace for the app
memos and Postgres share the memos namespace. Secrets are namespace-scoped, so this means one copy of the password and the short address postgres for the connection. Infrastructure tools (Traefik, monitoring, ArgoCD) get their own namespaces.

## Secrets: AWS Secrets Manager with the External Secrets Operator
No password is committed to git. ESO reads the secret from Secrets Manager and builds the normal Kubernetes Secret, so the StatefulSet doesn't change, and the repo holds only a SecretStore and an ExternalSecret. Chosen over Sealed Secrets and plain Secret files because Kubernetes Secrets are only base64 and git keeps history. The secret is created once with the AWS CLI so it never enters Terraform state.

## One cluster OIDC provider, a separate IAM role per helper
The eks module creates the OIDC provider once. ESO, ExternalDNS and the EBS CSI driver each get their own IRSA role that trusts one specific service account and has only the permissions it needs, so no access keys exist in the cluster.

## Persistent storage: EBS CSI driver as an EKS add-on
EKS can't create AWS disks by default, so Postgres needs the EBS CSI driver. Installed as an EKS add-on (AWS manages updates) with AWS's managed AmazonEBSCSIDriverPolicy, and its role lives in the eks module because it only needs the cluster and the OIDC provider. EBS disks are single-AZ, so Postgres can only run in its disk's zone, which is fine with nodes in all three.

## ExternalDNS: own module, scoped to one zone
The role can edit records only in the abdijalil.dev zone, found with a data lookup instead of a hardcoded zone ID. Because that zone also holds the earlier project's records, ExternalDNS will be configured to manage only eks.abdijalil.dev.

## CI/CD bootstrap folder: small, built with the pipeline
The pipeline needs an AWS role before it can run Terraform, so the pipeline can't create it. A small separate Terraform folder with its own state will hold only the GitHub OIDC provider and role, applied by hand once. The state bucket and ECR repo stay manual.