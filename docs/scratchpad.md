## Step 1 - Repo setup
- Created the GitHub repo and the folders: terraform/, argocd/, k8s/, docs/, .github/workflows/
- Checked the domain's DNS, is already set up correctly from previous project.
- Decision: reuse the same domain and add a new subdomain, eks.abdijalil.dev, instead of creating a new domain.

## Step 2 - memos local build
- Built memos on my laptop first, to make sure the app works before putting it in Docker.
- Error "No embeddable frontend found": the website part (frontend) must be built first, then the Go program. The Go build copies the frontend files inside the finished program, so the wrong order leaves them out.
- memos' older docs are out of date. The default port is 8081.
- Fixed .gitignore so build output (dist/, node_modules/, build/) and local database files (*.db) don't get committed.

## Step 3 - Postgres with Docker Compose
- Wrote docker-compose.local.yml to run memos and Postgres together on my laptop. It is for local testing only and is not used in the final project.
- Added a healthcheck so memos waits until Postgres is actually ready, not just started.
- Fixed the compose file: removed the obsolete version line, changed the port to 8081, and passed --driver and --dsn through command: (both flags confirmed in --help).
- memos and Postgres run together. The 13 tables in Postgres show memos is using it, not its own SQLite file.
- A note survived docker compose down and up. Only down -v would delete it.

## Step 4 - Dockerfile
- Moved the code up one folder (memos/web instead of memos/src/web) to keep the paths simple.
- A Docker build starts empty and only has the files I COPY in. My first attempt failed at pnpm install. package.json points to a patch file in web/patches, and pnpm-workspace.yaml configures it. I hadn't copied either, so I added both before running pnpm install.
- The build still failed on Alpine even though the same install worked on my laptop. Fix: install libc6-compat before installing pnpm. This is a common Alpine fix, since some pnpm dependencies expect glibc. With the patch files copied and libc6-compat installed, the install worked.
- The frontend build writes its output to ../server/frontend/dist, so web/ and server/ have to sit side by side inside the container.
- Simplified the Dockerfile to three stages: build the frontend (Node), build the backend (Go), run the app (Alpine).
- Chose Alpine over scratch for the final image (see decisions.md).
- Added a .dockerignore. The image builds (`docker build -t memos-custom:local .`) and runs on port 8081 (`docker run --rm -p 8081:8081 memos-custom:local`). Pushed to ECR in Step 5.

## Step 5 - Push image to ECR
- Built with --platform linux/amd64 because my Mac is arm64 and the EKS nodes will be Intel. The Go build takes about 4 minutes under emulation.
- ECR repo: memos, us-east-2, immutable tags, scan on push.
- Pushed tag: cf084ac (the git commit hash)
- This tag goes into k8s/memos/deployment.yaml later.

## Step 6 - Remote state
- Created the S3 bucket memos-eks-tfstate-<account id> by hand (versioning on, encrypted, public access blocked).
- Locking will use Terraform's built-in S3 locking (use_lockfile) instead of a DynamoDB table. I created a DynamoDB table first, then deleted it before using it.
- Made by hand because Terraform needs a place to store its state before it can create anything. I must not destroy the bucket when I tear down the project.

## Step 7 - Terraform: VPC and IAM modules

Setup
- Terraform on my laptop is v1.16.4. The pipeline must use the same version.
- AWS provider is pinned to ~> 6.24, because the regional NAT needs 6.24 or newer. It installed 6.67.0. The lock file in environments/prod is committed.
- Common tags use default_tags in provider.tf, so each resource only needs a Name tag.
- Renamed the module folders to eks and sg to keep the names short.
- Skipped the manual ClickOps EKS walkthrough. Terraform builds the cluster.

VPC module
- Contains: 3 public subnets, 3 private subnets, an internet gateway, one regional NAT gateway, two route tables with their associations, and outputs.
- Subnet values come in as variables, are grouped in a locals map, and are created with for_each.
- Considered the community VPC module. Chose a custom module instead (see decisions.md).

IAM module
- Contains: a control plane role and a worker node role.
- No instance profile is needed, because the managed node group creates one.
- It takes one variable (name) and outputs both role ARNs.

Things I learned
- terraform validate only checks the folder it is run in. I ran it one folder too high and it passed on an empty configuration.
- The region in provider.tf needs quotes.
- cluster_name was an unused variable, so I deleted it.
- Renaming a for_each row (like s1) makes Terraform destroy that subnet and create a new one, because it tracks resources by that name.
- There are two different locks. .terraform.lock.hcl pins provider versions and gets committed. The state lock (use_lockfile) stops two runs at once and lives in S3.

## Step 7 (continued) - sg, eks, root module

sg module
- Custom node security group on the worker nodes. One ingress rule per public subnet CIDR, TCP 30000-32767 (NodePort range) for load balancer traffic. The port range is a starting point to confirm when Traefik is deployed.
- The EKS-created cluster security group already allows node-to-node and node-to-control-plane traffic. My node SG does not replace it.
- A managed node group can only use a custom SG through a launch template, so the launch template attaches both: my node SG and the cluster SG (`vpc_config[0].cluster_security_group_id`).
- A new security group has no outbound rule. The nodes get outbound from the cluster SG.

eks module
- Three pieces: cluster, launch template, node group. 11 variables. Three outputs: cluster_name, cluster_endpoint, cluster_certificate.
- Cluster endpoint: public and private access both on. Public so my laptop and the pipeline can reach the API, private so nodes talk to it inside the VPC.
- Instance type goes on the node group only. Putting it in the launch template as well causes a conflict.
- Added depends_on on the iam outputs (role attachments) so the cluster and nodes wait for their policies. Added depends_on on the NAT gateway for the internet gateway.

Root module (environments/prod)
- main.tf calls the modules, variables.tf declares inputs, terraform.tfvars holds the values (no defaults), outputs.tf passes the eks outputs up.
- Modules connect through outputs: module.vpc.vpc_id, module.iam.node_role_arn, module.sg.node_sg_id, and so on.
- First manual apply: 30 resources, cluster took about 9 minutes. 3 nodes Ready on Kubernetes 1.37. Destroyed afterwards to save cost.

Things I learned
- Variables are inputs, outputs are return values, and the root module connects them. Resources inside the same module use type.label.attribute, not var.
- Referencing aws_eks_cluster.main.name (not retyping the string) is what makes Terraform build the cluster before the node group.
- validate does not read tfvars, so a wrong value only shows at plan.
- "1.34" was a stale pick. Check the EKS version list first, and remember upstream Kubernetes versions arrive on EKS later.
- Helm chart versions are plain strings. 10.10.05 failed at plan, 10.10.5 worked.

## Step 8 - ArgoCD via Terraform
- Added the hashicorp/helm provider (~> 3.0, installed 3.3.0). It connects with the cluster endpoint, the decoded certificate, and an aws eks get-token exec.
- helm_release for argo-cd chart 10.10.5 in the argocd namespace, depends_on module.eks.
- All 7 ArgoCD pods Running. Destroy removes ArgoCD too.
- Next: bootstrap app-of-apps manifest, then Kubernetes manifests, Traefik, ExternalDNS, monitoring.

## Step 9 - Secrets groundwork (nothing applied yet)

Namespace
- Wrote k8s/namespaces/memos.yaml. One namespace for the whole app (memos + Postgres). Infrastructure tools get their own later.
- The file only creates the empty section. Every other file says `namespace: memos` to put its objects in it.

OIDC provider (eks module)
- Added aws_iam_openid_connect_provider to the eks module, plus two outputs: oidc_provider_arn and oidc_provider_url.
- It registers the cluster with AWS as a trusted badge issuer, so programs inside the cluster can be given IAM roles (IRSA) with no stored keys. ESO, ExternalDNS and the EBS CSI driver will all use it.
- client_id_list is a list, so it needs [ ] even with one item. url is a single value, so no brackets.

external-secrets module
- New module: an IAM role only the ESO service account can use (namespace external-secrets, account external-secrets), allowed to do only GetSecretValue and DescribeSecret on secrets starting with memos-eks/prod/.
- The names in the trust rule must match what ESO is installed as later, or AWS refuses the badge.
- data blocks look things up (region, account number). Resource blocks build things. locals are named values inside a module.
- Root module got a module block, a secret_prefix variable, a tfvars line and an output.
- The secret itself is not created yet. It will be made once by hand with the AWS CLI, so the password never lands in Terraform state.

Things I learned
- A typo in a folder name (external-secrects) gives "Unreadable module directory" and an empty source in the error. Check with ls.
- Outputs have no type line. Variables do.
- Lists take [ ]. If a name ends in _list or _ids, it takes a list.
- Base64 is not encryption. A Secret in git is a password in git.

