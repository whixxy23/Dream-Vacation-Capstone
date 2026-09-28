# Git Workflow & Branch Protection

This repo's `Contributing.md` already defines the branching model - this doc
just adds the CI/CD and branch-protection mechanics on top of it.

## Branch strategy (from Contributing.md)

| Branch    | Purpose                                                        |
|-----------|-----------------------------------------------------------------|
| `main`    | Production-ready state. CD workflow builds & pushes images from here. |
| `staging` | Pre-production testing. Release branches merge here before `main`. |
| `develop` | Main development branch. All feature work lands here first.    |

Flow: `feature/*` → PR into `develop` → release branch → PR into `staging` →
tested → PR into `main`.

## Creating the repository (from scratch, not a fork)

```bash
gh repo create dream-vacation-capstone --public --description "Dream Vacation Destinations"

git init -b main
git remote add origin https://github.com/<you>/dream-vacation-capstone.git
git add .
git commit -m "chore: initial commit"
git push -u origin main

git checkout -b develop
git push -u origin develop

git checkout -b staging
git push -u origin staging
```

## Branch protection rules

Configure under **Settings → Branches → Add branch protection rule** for
`main`, `staging`, and `develop`.

Recommended for `main` and `staging` (matches Contributing.md's "sign-off of
two other developers" requirement):
- Require a pull request before merging - **2 approving reviews**.
- Require status checks to pass - select the CI workflow's `Backend - lint,
  test, build` and `Frontend - lint, test, build` jobs (these names only
  appear as selectable checks after CI has run at least once on the repo).
- Require branches to be up to date before merging.
- Require conversation resolution before merging.
- Disallow force pushes and deletions.

For `develop`, a lighter rule set is usually enough to keep iteration fast:
required status checks, but 0-1 required approvals.

Via `gh` CLI (run once CI has produced at least one check run):

```bash
gh api repos/<owner>/<repo>/branches/main/protection \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -f required_status_checks.strict=true \
  -f required_status_checks.contexts[]="Backend - lint, test, build" \
  -f required_status_checks.contexts[]="Frontend - lint, test, build" \
  -f enforce_admins=true \
  -f required_pull_request_reviews.required_approving_review_count=2 \
  -f restrictions=null
```

## Pull request template

`.github/pull_request_template.md` is already included, so every PR prompts
for a summary, testing notes, and target-branch checklist.
