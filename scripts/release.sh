#!/bin/bash
# Release script for Singularity.Workflow
# Creates a git tag and pushes it to trigger the GitHub Actions publish workflow

set -e

VERSION=${1:-"0.1.0"}
MODE=${2:-"github"}  # "github" or "hex"

echo "🚀 Preparing to release version ${VERSION} (mode: ${MODE})"
echo ""

# Check if we're on a clean branch
if [[ -n $(git status -s) ]]; then
    echo "❌ Error: You have uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Check if tag already exists
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo "❌ Error: Tag v${VERSION} already exists."
    echo "   To re-release, delete the tag first with:"
    echo "   git tag -d v${VERSION}"
    echo "   git push origin :refs/tags/v${VERSION}"
    exit 1
fi

echo "📝 Creating tag v${VERSION}..."
git tag -a "v${VERSION}" -m "Release v${VERSION}"

echo "⬆️  Pushing tag to GitHub..."
git push origin "v${VERSION}"

echo ""
echo "✅ Tag v${VERSION} pushed successfully!"
echo ""

if [ "$MODE" = "hex" ]; then
    echo "📦 GitHub Actions workflow will now:"
    echo "   1. Run all tests and quality checks"
    echo "   2. Wait for manual approval in the 'production' environment"
    echo "   3. Publish to Hex.pm (requires HEX_API_KEY secret)"
    echo "   4. Create a GitHub release with changelog"
    echo ""
    echo "🔗 Monitor progress at:"
    echo "   https://github.com/Singularity-ng/singularity-workflows/actions/workflows/publish.yml"
    echo ""
    echo "⚙️  Setup required (if not done yet):"
    echo "   1. Add HEX_API_KEY secret to GitHub repository settings"
    echo "   2. Configure 'production' environment in repository settings for manual approval"
else
    echo "📦 GitHub Actions workflow will now:"
    echo "   1. Run all tests and quality checks"
    echo "   2. Create a GitHub release with changelog"
    echo ""
    echo "🔗 Monitor progress at:"
    echo "   https://github.com/Singularity-ng/singularity-workflows/actions/workflows/release-github-only.yml"
    echo ""
    echo "💡 To publish to Hex.pm later, run:"
    echo "   mix hex.publish"
fi
echo ""
