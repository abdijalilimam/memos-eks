## App choice: memos + Postgres

Chose memos (notes app) with a dedicated Postgres database, over memos+SQLite or a simpler static app (2048). SQLite would have meant a single service with no internal networking to design. Postgres as a second service forces a real internal-vs-external traffic boundary — Postgres runs as a ClusterIP service, never exposed via Ingress, only reachable from memos.

## Single environment for now

Running one environment (prod) rather than dev/staging/prod in parallel. Multi-environment setup (e.g., staging auto-syncing via ArgoCD, prod requiring manual sync approval) is a valid future extension but was deliberately deferred to keep the first full build focused and achievable within the project timeline.

## Domain: reused existing hosted zone, new subdomain only

`abdijalil.dev` is an existing Route 53 hosted zone (already used for a prior ECS project's `it-tools.abdijalil.dev`). Rather than creating a new hosted zone, this project adds a new record under the same zone: `eks.abdijalil.dev`, managed automatically by ExternalDNS.

## Building a custom Docker image from source

Chose to clone memos' actual source code and write a Dockerfile, rather than wrapping the pre-built upstream image. This gives the CI/CD pipeline a real build-and-scan step to perform, instead of reusing someone else's pre-built image.

## Docker image: three stages, final image on Alpine (not scratch)

The Dockerfile has three stages: build the frontend with Node, build the backend with Go, then copy only the finished program into a small final image. The final image is Alpine rather than scratch (an empty image with nothing in it). Scratch is smaller and gives security scanners almost nothing to flag, but it has no shell, so I can't open a terminal inside the container to debug it, and file permissions and missing certificates are harder to sort out. Alpine is a few MB bigger and has a shell, which will help while I'm getting things working on EKS. The app runs as a non-root user either way. I also kept the Dockerfile simple (no cache mounts, fewer COPY steps) so there are fewer places for it to break. Once the whole pipeline works, I may switch to scratch as a hardening step and compare the Trivy results.

## Image tags: git commit hash, immutable in ECR

Images are tagged with the short git commit hash (for example cf084ac), never latest, and the ECR repository has tag immutability turned on. Each tag points at exactly one build, so I can trace a running pod back to its code and roll back by changing the tag. It also makes GitOps work: the pipeline's tag change in Git is what makes ArgoCD deploy. I build with --platform linux/amd64 because my laptop is arm64 and the EKS nodes will be Intel.

## Terraform state: S3 bucket with built-in S3 locking, created outside Terraform

State is stored in a versioned, encrypted S3 bucket with all public access blocked. Locking uses Terraform's native S3 lock file (use_lockfile) and not a DynamoDB table, because HashiCorp has deprecated DynamoDB locking and it's one less resource to run and secure. This needs Terraform 1.10 or newer. I created the bucket by hand since the state backend has to exist before Terraform can use it, and it is kept out of the project's teardown so destroying the project doesn't delete the state it depends on.

## Terraform modules: custom modules instead of the community VPC module

The infrastructure is split into separate modules: vpc, iam, sg and eks. For the VPC, the community terraform-aws-modules/vpc module was an option. I chose a custom module so every resource is visible in the repo, and I can explain and change each one.

The VPC module takes the subnet values (CIDRs, zones, names) as variables. It groups them in a locals table and creates the subnets with for_each.

## Shared tags: default_tags in the provider

Common tags (Project, ManagedBy) are set once in provider.tf with default_tags. Each resource only sets its own Name tag, so there is no merge() in every resource.

## Version pinning: Terraform 1.16.x and AWS provider ~> 6.24

required_version is ~> 1.16.4, which matches my laptop, and the pipeline must use the same version. The AWS provider is ~> 6.24 because the regional NAT gateway needs provider 6.24.0 or newer. The provider lock file (.terraform.lock.hcl) is committed so my laptop and the pipeline install the same provider version.

## VPC: explicit private/public subnet split

Worker nodes run in private subnets; the Traefik load balancer lands in public subnets. A deliberate two-tier split with a NAT Gateway so private subnets retain outbound internet access.

The NAT gateway is a single regional NAT gateway, not a zonal one. One gateway covers all three availability zones, so losing one zone does not cut outbound internet for the private subnets.

## Security groups scoped to minimum required access

Security group rules avoid `0.0.0.0/0` except where genuinely required for public load balancer traffic on ports 80/443. Node-to-node and control-plane-to-node rules are scoped narrowly.

## IAM: separate roles for the control plane and the worker nodes

There are two roles.

- Control plane role: trusts the EKS service and has one policy, AmazonEKSClusterPolicy.
- Worker node role: trusts EC2 and has only the policies the nodes need (AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly).

There is no instance profile in the code. The managed node group creates one from the node role automatically.

## GitOps pattern: app-of-apps

Terraform's scope is deliberately minimal: create the VPC, IAM roles, EKS cluster, install ArgoCD, and apply one bootstrap manifest (`argocd/bootstrap/app-of-apps.yaml`). Every other tool — Traefik, ExternalDNS, kube-prometheus-stack, and the memos/Postgres app itself — is installed and managed exclusively through ArgoCD, watching `argocd/infra/` and `argocd/apps/`. Chose this over having Terraform install those tools directly via `helm_release`, because splitting "some things Terraform manages, some things ArgoCD manages" means two sources of truth instead of one.

## Ingress + TLS: Traefik with built-in Let's Encrypt, no cert-manager

Chose Traefik over NGINX Ingress Controller, and decided to use Traefik's built-in ACME/Let's Encrypt integration rather than installing cert-manager separately, since Traefik already includes this capability out of the box. Confirmed this with the course instructor/mentor before proceeding. This simplifies the stack by one moving piece — no separate cert-manager installation or ClusterIssuer needed.

## CI/CD deploys via Git commit, not direct kubectl/helm

The pipeline's last step updates the image tag inside `k8s/memos/deployment.yaml` and commits that change to Git, rather than running `kubectl apply` or `helm upgrade` directly. ArgoCD detects the change and performs the actual deploy. This keeps the pipeline responsible for triggering a deployment while ArgoCD/Git remains the sole mechanism that actually touches the cluster.

## Monitoring: explicit dashboard coverage

kube-prometheus-stack's default Grafana dashboards cover node and pod health, but not Ingress traffic. Adding a separate community Traefik dashboard to explicitly cover the four things that matter: CPU/memory usage, pod health, node statuses, and Ingress traffic — not just the three that come by default.