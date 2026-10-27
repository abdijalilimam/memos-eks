# Errors and fixes

| Step | Where | Error | Cause | Fix |
|---|---|---|---|---|
| 2 | memos build | "No embeddable frontend found" | The Go build embeds the frontend output, and the frontend hadn't been built yet | Build the frontend first, then the Go binary |
| 4 | Docker build | `pnpm install` fails on Alpine | `web/patches` and `pnpm-workspace.yaml` weren't copied in, and Alpine lacked glibc compatibility | COPY both files before the install, and add `libc6-compat` before installing pnpm |
| 7 | Git | Changes in other folders not committed | `git add .` only adds the current folder and below | Run `git add -A` from the repo root |
| 7 | Terraform | `validate` passed on an empty config | Ran it one folder too high, and it only checks the folder it's in | Run it inside each module and in `environments/prod` |
| 7 | Terraform | Region value rejected in `provider.tf` | The region string had no quotes | Quote it: `"us-east-2"` |
| 7 | Terraform | "Missing required provider" on `validate` | Deleted `.terraform` before running `validate`, and `init` downloads the provider into it | Run `init`, then `validate`, then clean up |
| 8 | Helm | "Planned version is different from configured version" | Chart version written as `10.10.05` | Use `10.10.5` |
| 9 | Terraform | "Unreadable module directory" | Typo in the module folder name (`external-secrects`) | Rename the folder to match the `source` path, and check with `ls` |