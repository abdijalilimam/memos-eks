## App choice: memos + Postgres

Chose memos (notes app) with a dedicated Postgres database, over memos+SQLite or a simpler static app (2048). SQLite would have meant a single service with no internal networking to design. Postgres as a second service forces a real internal-vs-external traffic boundary — Postgres runs as a ClusterIP service, never exposed via Ingress, only reachable from memos.

## GitOps pattern: app-of-apps

Terraform's scope is deliberately minimal: create the VPC, IAM roles, EKS cluster, install ArgoCD, and apply one bootstrap manifest (`argocd/bootstrap/app-of-apps.yaml`). Every other tool — Traefik, ExternalDNS, kube-prometheus-stack, and the memos/Postgres app itself — is installed and managed exclusively through ArgoCD, watching `argocd/infra/` and `argocd/apps/`. Chose this over having Terraform install those tools directly via `helm_release`, because splitting "some things Terraform manages, some things ArgoCD manages" means two sources of truth instead of one.

## Ingress + TLS: Traefik with built-in Let's Encrypt, no cert-manager

Chose Traefik over NGINX Ingress Controller, and decided to use Traefik's built-in ACME/Let's Encrypt integration rather than installing cert-manager separately, since Traefik already includes this capability out of the box. Confirmed this with the course instructor/mentor before proceeding. This simplifies the stack by one moving piece — no separate cert-manager installation or ClusterIssuer needed.

## CI/CD deploys via Git commit, not direct kubectl/helm

The pipeline's last step updates the image tag inside `k8s/memos/deployment.yaml` and commits that change to Git, rather than running `kubectl apply` or `helm upgrade` directly. ArgoCD detects the change and performs the actual deploy. This keeps the pipeline responsible for triggering a deployment while ArgoCD/Git remains the sole mechanism that actually touches the cluster.

## VPC: explicit private/public subnet split

Worker nodes run in private subnets; the Traefik load balancer lands in public subnets. A deliberate two-tier split with a NAT Gateway so private subnets retain outbound internet access.

## Security groups scoped to minimum required access

Security group rules avoid `0.0.0.0/0` except where genuinely required for public load balancer traffic on ports 80/443. Node-to-node and control-plane-to-node rules are scoped narrowly.

## IAM: least-privilege node role

Worker node IAM role attaches only the managed policies actually required (`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`), rather than broader permissions.

## Domain: reused existing hosted zone, new subdomain only

`abdijalil.dev` is an existing Route 53 hosted zone (already used for a prior ECS project's `it-tools.abdijalil.dev`). Rather than creating a new hosted zone, this project adds a new record under the same zone: `eks.abdijalil.dev`, managed automatically by ExternalDNS.

## Building a custom Docker image from source

Chose to fork and clone memos' actual source code and write an original Dockerfile, rather than wrapping the pre-built upstream image. This gives the CI/CD pipeline a real build-and-scan step to perform against code that's actually mine, not someone else's pre-built artifact.

## Single environment for now

Running one environment (prod) rather than dev/staging/prod in parallel. Multi-environment setup (e.g., staging auto-syncing via ArgoCD, prod requiring manual sync approval) is a valid future extension but was deliberately deferred to keep the first full build focused and achievable within the project timeline.

## Monitoring: explicit dashboard coverage

kube-prometheus-stack's default Grafana dashboards cover node and pod health, but not Ingress traffic. Adding a separate community Traefik dashboard to explicitly cover the four things that matter: CPU/memory usage, pod health, node statuses, and Ingress traffic — not just the three that come by default.