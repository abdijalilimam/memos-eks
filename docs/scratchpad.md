## Step 1 - Repo setup
- created repo, folder structure (terraform/, argocd/, k8s/, docs/, .github/workflows/)
- forgot to actually commit after creating folders - git status showed "no commits yet" even though structure was there. 
- confirmed abdijalil.dev Route 53 hosted zone already works (proven indirectly - old ECS project's it-tools.abdijalil.dev subdomain still resolves, so nameserver delegation is already correct, no need to re-check with dig)
- decided: reuse abdijalil.dev hosted zone, add new eks.abdijalil.dev subdomain rather than creating a new hosted zone
## Step 2 - memos local build
- hit "no embeddable frontend found" - had to build frontend (pnpm release) BEFORE go build, since Go embeds dist/ at compile time, not runtime
- memos CLI flags differ from older docs - no --mode flag, actual flags are --driver, --dsn, --port, --instance-url (confirmed via --help)
- had to fix .gitignore - dist/, node_modules, build/, *.db were getting tracked/untracked incorrectly at first