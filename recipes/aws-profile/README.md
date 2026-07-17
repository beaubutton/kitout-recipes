# aws-profile

Scaffold a named AWS profile in `~/.aws/config` — region, output format, and
optional SSO wiring — **with no secrets**, as a kitout-managed block.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.aws/config`
(`# >>> recipes:aws-profile >>>` … `# <<< recipes:aws-profile <<<`). The block
holds a `[profile …]` section with the **non-sensitive** knobs the AWS CLI and
SDKs read from `config`: `region`, `output`, and (optionally) the IAM Identity
Center / SSO fields (`sso_session`, `sso_account_id`, `sso_role_name`, and an
`[sso-session]` block). No script.

`~/.aws/config` is INI, and AWS's parser treats lines beginning with `#` as
comments — so kitout's `#`-prefixed marker lines are valid and invisible to the
AWS CLI. Everything outside the markers (your `[default]`, other profiles) is
untouched.

## Requirements

- None to *write* the file. To *use* the profile you'll want the `awscli`
  (macOS: `brew "awscli"`), but that's not required for this step.
- If you use SSO, an IAM Identity Center start URL and the account/role you're
  entitled to (fill those into the block).

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest. There's nothing to
   copy into `steps/` — this is pure `block-in-file`.
2. Rename `[profile dev]` and set `region`/`output` to taste. For SSO, uncomment
   the `sso_*` lines and the `[sso-session …]` block and fill in your org's values.
3. `kitout apply`, then authenticate: `aws sso login --profile dev` (SSO) or drop
   long-lived keys into `~/.aws/credentials` (see Security), and test with
   `aws sts get-caller-identity --profile dev`.

## Caveats

- **Config only, not credentials.** This writes `~/.aws/config`. Static access
  keys belong in the *separate* `~/.aws/credentials` file (or, better, come from
  SSO) — this recipe deliberately never touches either.
- **`~/.aws/config` must be valid INI.** Keep entries inside the block as
  `key = value` under a `[profile name]` header. Don't paste TOML-isms.
- If you already have a `[profile dev]` **outside** the managed block, you'll now
  have two — AWS uses the last one wins per key, which is confusing. Pick one home
  for a given profile.
- Renaming the profile later leaves the old name only if it lived outside the
  block; inside the block, kitout rewrites the whole region, so renames are clean.

## Security

**No secrets are written — but this file shapes which account your CLI hits.**

- **Contains nothing sensitive.** `region`, `output`, and the `sso_*` pointers are
  not credentials — an SSO start URL and account/role names are safe to commit.
  This recipe writes **only** those. It never writes access keys, session tokens,
  or passwords.
- **Credentials live elsewhere, by design:** short-lived SSO tokens are cached
  under `~/.aws/sso/cache` by `aws sso login`; long-lived keys (avoid if you can)
  go in `~/.aws/credentials`. Neither is managed here — keep
  `~/.aws/credentials` out of version control (`chmod 600`), and prefer SSO so no
  static key ever lands on disk.
- **No sudo, no network.** It edits one user-owned file in your home directory.
  Writing it authenticates nothing and contacts no AWS endpoint; that only happens
  later when *you* run `aws sso login` / an `aws` command.
- **Blast radius:** a wrong `region` or a profile pointed at the wrong account is
  the realistic footgun — review the account id/role before applying, especially
  if a profile can reach production.
- **Reverse it:** delete the block (or remove the recipe and re-apply). Revoke any
  SSO session with `aws sso logout`.
