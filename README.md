# Atlantis testdrive

Public demo repository: <https://github.com/dev-velo/atlantis-testdrive>.

A disposable Terraform repository for testing a locally built Atlantis against
real GitHub pull requests. It creates no cloud infrastructure and needs no cloud
credentials. Both projects use the built-in `terraform_data` resource without
provisioners or external provider downloads.

## Projects

| Project | Directory | Workspace |
| --- | --- | --- |
| networking-staging | terraform/networking | staging |
| networking-production | terraform/networking | production |
| storage-production | terraform/storage | production |

Terraform 1.16.5 is selected by `.terraform-version` and `atlantis.yaml`.
No custom Atlantis workflows or relaxed server-side permissions are required.

## Connect local Atlantis

1. Clone this repository, or fork it into your account for your own test server.
2. Build Atlantis from the `dev-ui` branch with `make build-service`.
3. Forward port 4141 through an HTTPS tunnel, such as `ngrok http 4141`.
4. Configure a GitHub App installed only on this sandbox, or dedicated test-user
   credentials and a signed repository webhook. Use the public tunnel URL as
   the Atlantis URL, and `<tunnel-url>/events` as the webhook endpoint.
5. Start the built Atlantis binary with an exact repository allowlist:
   `github.com/dev-velo/atlantis-testdrive`, not `*`. If using your own fork,
   substitute its owner and repository name.
6. Open `http://localhost:4141/beta` for the production beta dashboard.

For a GitHub App, use `ATLANTIS_GH_APP_ID`, `ATLANTIS_GH_APP_KEY_FILE`, and
`ATLANTIS_GH_WEBHOOK_SECRET`. Start with `--write-git-creds`, required for App
cloning. App-managed webhooks do not need a second repository webhook.

After configuring the App credentials and web authentication environment
variables locally, run this from your Atlantis source checkout:

```sh
./atlantis server \
  --atlantis-url='https://YOUR-TUNNEL-HOST' \
  --repo-allowlist='github.com/dev-velo/atlantis-testdrive' \
  --allow-fork-prs=false \
  --write-git-creds \
  --web-basic-auth=true \
  --port=4141
```

The environment must contain the App variables above, plus
`ATLANTIS_WEB_USERNAME` and `ATLANTIS_WEB_PASSWORD`. Use the webhook secret
generated for your App. Installing this App only on this test repository limits
its repository access. Use a separate Atlantis data directory if you already
have another Atlantis instance.

Keep all credentials, App keys, and webhook secrets outside this repository.
Enable Atlantis web basic authentication before exposing the dashboard. Do not
commit tokens or paste them into PRs/chat. GitHub CLI login is not automatically
an Atlantis credential configuration.

Official setup references:

- [Testing locally](https://www.runatlantis.io/guide/testing-locally)
- [GitHub App setup](https://www.runatlantis.io/docs/access-credentials#github-app)
- [Web basic authentication](https://www.runatlantis.io/docs/server-configuration#web-basic-auth)

## First real pull request

After the server and webhook are configured:

1. Create a branch, e.g. `test/networking-change`.
2. Change the default value of `revision` in
   `terraform/networking/main.tf` from `initial` to `first-pr`.
3. Commit, push, and open a PR. Atlantis should autoplan both networking
   workspaces and comment the results on the PR.
4. Open `/beta` and check workspace grouping, locks, filters, and PR links.
5. Open the job link from the PR/dashboard to check real terminal output.

PR comments for exercising one project at a time:

```text
atlantis plan -p networking-staging
atlantis apply -p networking-staging
atlantis plan -p networking-production
atlantis plan -p storage-production
```

To produce a genuine failed plan, add
`terraform/storage/failure.auto.tfvars` containing `fail_plan = true` on a
separate PR branch. To recover, delete that file and push another commit.
For a second PR/workspace group without conflicting networking locks, change
`revision` in `terraform/storage/main.tf` on a separate branch.

Current beta limitations: success/failure/running badges are not implemented;
the view shows tracked jobs and active locks, not every open GitHub PR. These
small plans may complete too quickly to watch live, but the PR comments and job
output still exercise real execution.

## State and safety

This repository intentionally uses local state. State belongs to Atlantis's
working directory and can disappear when PR checkout directories are cleaned
up, so this is not a production backend or a durable infrastructure setup.
Atlantis recommends private repositories for security. This repository is
public to demonstrate the integration; that does not make exposing a local
Atlantis server risk-free. Keep fork PR processing disabled, use a signed
webhook, exact repo allowlist, and web authentication, and do not enable custom
workflows. Restrict who can push branches and inspect changes before running
them. Public PR comments can trigger commands even on trusted PRs. Terraform
executed by Atlantis is code running on your computer, even when the initial
example is harmless. Never point this local development instance at production
repos or give it production credentials.

See [Atlantis security guidance](https://www.runatlantis.io/docs/security).

When finished, stop Atlantis and the tunnel. Disable the sandbox webhook or
uninstall the test App from this repository. Do not leave a stale webhook
pointing at an expired/reassigned tunnel URL.
