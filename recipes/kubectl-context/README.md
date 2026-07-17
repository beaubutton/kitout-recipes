# kubectl-context

Set your default `kubectl` context to a named context that already lives in your
kubeconfig — a **local file edit that never contacts a cluster**.

## What it does

Runs `kubectl config use-context <name>`, which rewrites only the
`current-context` field in `~/.kube/config`. That's the context `kubectl` uses
when you don't pass `--context`. Nothing here reaches out to a Kubernetes API
server; it's purely a local kubeconfig mutation.

Two safety rails in the script:

- It first checks `kubectl config current-context` and no-ops if you're already
  on the target (this mirrors the step's `check`).
- It **refuses to switch to a context that isn't defined** (verified with
  `kubectl config get-contexts`), so it can never leave you pointed at a dangling
  context. Adding the context itself (from EKS/GKE/AKS/kubeadm) is out of scope —
  this recipe only *selects* among contexts you already have.

## Requirements

- The `kubectl` CLI (macOS: `brew "kubectl"`). Point the step's `needs` at
  whatever installs it.
- The target context must already exist in your kubeconfig. Populate it with your
  provider's tool first, e.g. `aws eks update-kubeconfig`,
  `gcloud container clusters get-credentials`, `az aks get-credentials`, or a
  manual `kubectl config set-context`.

## Adopt

1. Copy `kubectl-context.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. Change `docker-desktop` **in both files** — the `want=` line in the script and
   the `check` in `step.toml` — to the context name you want as default
   (see `kubectl config get-contexts`).
4. `kubectl apply`, then confirm with `kubectl config current-context`.

## Caveats

- **Selects, does not create.** If the context isn't in your kubeconfig the step
  fails with a hint rather than inventing one. This is deliberate — provisioning
  cluster credentials is a separate, provider-specific concern.
- The context name lives in **two** places (script `want=` and the `check`). Keep
  them identical or the step will loop between "pending" and "applied".
- Switching context also switches the default **namespace** if that context pins
  one. Use `kubectl config set-context --current --namespace=…` separately if you
  care about the namespace.

## Security

**Local kubeconfig edit only — it reads about clusters, it never talks to them.**

- **No network, no cluster contact.** `use-context` and `get-contexts` operate
  entirely on the local `~/.kube/config` file. This step will not authenticate to,
  query, or change any cluster. It cannot create or leak credentials.
- **No sudo.** It edits a file in your home directory owned by you. No privilege.
- **What it changes:** one field (`current-context`) in your kubeconfig. Its blast
  radius is "which cluster your *next* un-qualified `kubectl` command targets."
  That matters — pointing at prod by default is a footgun — so the script only
  ever switches to a context you already trust enough to have configured, and
  no-ops otherwise.
- **Reverse it:** `kubectl config use-context <previous-name>`, or edit
  `current-context` in `~/.kube/config` back.
