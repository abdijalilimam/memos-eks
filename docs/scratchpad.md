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
- Wrote docker-compose.local.yml to run memos and Postgres together on my laptop. It is for local testing only and is not used in project.
- Added a healthcheck so memos waits until Postgres is actually ready, not just started.
- Fixed the compose file: removed the obsolete version line, changed the port to 8081, and passed --driver and --dsn through command: (both flags confirmed in --help).
- memos and Postgres run together. The 13 tables in Postgres show memos is using it, not its own SQLite file.
- A note survived docker compose down and up. Only down -v would delete it.
## Step 4 - Dockerfile
- Moved the code up one folder (memos/web instead of memos/src/web) to keep the paths simple.
- A Docker build starts empty and only has the files I COPY in. My first attempt failed at pnpm install. One cause: package.json points to a patch file in web/patches, and pnpm-workspace.yaml configures it. I hadn't copied either. I added them, but the build still failed and I never saw the real error message. The same install worked on my laptop. Status: unresolved. I added libc6-compat as a precaution (a common fix on Alpine), but I haven't confirmed it is the cause.
- The frontend build writes its output to ../server/frontend/dist, so web/ and server/ have to sit side by side inside the container.
- Simplified the Dockerfile to three stages: build the frontend (Node), build the backend (Go), run the app (Alpine).
- Chose Alpine over scratch for the final image (see decisions.md).
- Next: add a .dockerignore, run docker build, then docker run on port 8081.
## Step 5 - Push image to ECR
- Built with --platform linux/amd64 because my Mac is arm64 and the EKS nodes will be Intel. The Go build takes about 4 minutes under emulation.
- ECR repo: memos, us-east-2, immutable tags, scan on push.
- Pushed tag: cf084ac (the git commit hash)
- This tag goes into k8s/memos/deployment.yaml later.
## Step 7 - Remote state
- Created the S3 bucket memos-eks-tfstate-<account id> by hand (versioning on, encrypted, public access blocked).
- Locking will use Terraform's built-in S3 locking (use_lockfile) instead of a DynamoDB table. I created a DynamoDB table first, then deleted it before using it.
- Made by hand because Terraform needs a place to store its state before it can create anything. I must not destroy the bucket when I tear down the project.