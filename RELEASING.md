# Release Process for Singularity.Workflow

This document describes how to publish a new release of Singularity.Workflow to Hex.pm.

## Prerequisites

Before creating a release, ensure:

1. **HEX_API_KEY Secret**: Add your Hex.pm API key to GitHub repository secrets
   - Go to repository Settings → Secrets and variables → Actions
   - Create a new secret named `HEX_API_KEY`
   - Get your API key from: https://hex.pm/dashboard/keys

2. **Production Environment**: Configure manual approval for releases
   - Go to repository Settings → Environments
   - Create an environment named `production`
   - Add required reviewers who can approve releases

3. **All Changes Committed**: Ensure all changes are committed and pushed

## Quick Release

Use the automated release script:

```bash
./scripts/release.sh 0.1.0
```

This will:
- Create a git tag `v0.1.0`
- Push the tag to GitHub
- Trigger the automated publish workflow

## Manual Release Steps

If you prefer to do it manually:

### 1. Create and Push Tag

```bash
# Create annotated tag
git tag -a v0.1.0 -m "Release v0.1.0"

# Push tag to GitHub
git push origin v0.1.0
```

### 2. GitHub Actions Workflow

The tag push automatically triggers `.github/workflows/publish.yml` which:

1. **CI Tests** (automatic):
   - Runs full test suite
   - Checks code formatting
   - Runs Credo quality checks
   - Runs security audit with Sobelow

2. **Manual Approval** (requires human):
   - Workflow pauses for manual approval
   - Configured reviewers must approve in the GitHub UI
   - Go to Actions → Publish to Hex.pm → Review deployments

3. **Publish** (automatic after approval):
   - Publishes package to Hex.pm
   - Creates GitHub release with changelog
   - Tags release with version

### 3. Verify Publication

After the workflow completes:

- Check Hex.pm: https://hex.pm/packages/singularity_workflow
- Check GitHub releases: https://github.com/Singularity-ng/singularity-workflows/releases

## Version Preparation Checklist

Before creating a release tag, ensure:

- [ ] Version updated in `mix.exs`
- [ ] `CHANGELOG.md` updated with release notes
- [ ] `README.md` references correct version
- [ ] All tests passing (`mix test`)
- [ ] Code quality checks passing (`mix quality`)
- [ ] Documentation reviewed and updated
- [ ] Security audit passing (`mix sobelow`)

## Troubleshooting

### Tag Already Exists

If you need to re-release:

```bash
# Delete local tag
git tag -d v0.1.0

# Delete remote tag
git push origin :refs/tags/v0.1.0

# Recreate tag
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

### Workflow Fails

Check the GitHub Actions logs:
- Go to repository → Actions tab
- Find the failed workflow run
- Review error messages in each job

Common issues:
- Missing `HEX_API_KEY` secret
- Test failures (check PostgreSQL service)
- Missing approval environment configuration

### Hex.pm Authentication Issues

Ensure your `HEX_API_KEY` secret:
- Is valid and not expired
- Has write permissions for the package
- Is properly configured in repository secrets

## Post-Release Tasks

After successful release:

1. Announce the release (optional)
2. Update any dependent projects
3. Close related GitHub issues
4. Update project board/roadmap

## Local Testing Before Release

Test the package locally before releasing:

```bash
# Clean build
mix deps.clean --all
mix clean

# Reinstall and test
mix deps.get
mix test

# Check package content
mix hex.build
tar tzf singularity_workflow-0.1.0.tar | head -20
```

## Emergency Rollback

If you need to yank a release from Hex.pm:

```bash
mix hex.retire singularity_workflow 0.1.0 --reason security
```

Note: Yanking doesn't delete the release, it just marks it as retired.
