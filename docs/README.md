# Singularity.Workflow Documentation

Complete documentation for the Singularity.Workflow library.

---

## 📚 Documentation Index

### Getting Started

- **[README](../README.md)** - Project overview, features, quick start, and installation guide
- **[CHANGELOG](../CHANGELOG.md)** - Version history and release notes

### Core Documentation

- **[API_REFERENCE](API_REFERENCE.md)** - Complete API documentation with examples
  - All public APIs with type specs
  - What each API does and what problems it solves
  - Phoenix integration examples
  - Usage guidance and best practices

- **[ARCHITECTURE](ARCHITECTURE.md)** - System architecture and design
  - PostgreSQL + pgmq messaging architecture
  - DAG execution engine
  - Multi-node coordination
  - Database schema overview

### Feature Guides

- **[HTDAG_ORCHESTRATOR_GUIDE](HTDAG_ORCHESTRATOR_GUIDE.md)** - Goal-driven orchestration
  - Why HTDAG exists (AI/LLM workflows)
  - Goal decomposition
  - Workflow composition
  - Optimization strategies

- **[DYNAMIC_WORKFLOWS_GUIDE](DYNAMIC_WORKFLOWS_GUIDE.md)** - Runtime workflow creation
  - FlowBuilder API
  - AI/LLM integration patterns
  - Dynamic step creation
  - Use cases and examples

- **[DEPLOYMENT_GUIDE](DEPLOYMENT_GUIDE.md)** - Production deployment
  - Multi-node setup
  - PostgreSQL configuration
  - Performance tuning
  - Monitoring and observability

- **[TESTING_GUIDE](TESTING_GUIDE.md)** - Testing workflows
  - Unit testing strategies
  - Integration testing
  - TestClock for deterministic tests
  - Mocking and fixtures

- **[INPUT_VALIDATION](INPUT_VALIDATION.md)** - Input validation patterns
  - Workflow input validation
  - Type safety
  - Error handling
  - Best practices

### Community

- **[CONTRIBUTING](../CONTRIBUTING.md)** - How to contribute
- **[SECURITY](../SECURITY.md)** - Security policy and reporting
- **[LICENSE](../LICENSE.md)** - MIT License

---

## 🚀 Quick Navigation

### I want to...

**Start using the library:**
→ [README](../README.md) (includes installation and quick start)

**Understand the API:**
→ [API_REFERENCE](API_REFERENCE.md)

**Build AI/LLM workflows:**
→ [HTDAG_ORCHESTRATOR_GUIDE](HTDAG_ORCHESTRATOR_GUIDE.md) → [DYNAMIC_WORKFLOWS_GUIDE](DYNAMIC_WORKFLOWS_GUIDE.md)

**Integrate with Phoenix:**
→ [API_REFERENCE - Phoenix Integration](API_REFERENCE.md#phoenix-integration)

**Deploy to production:**
→ [DEPLOYMENT_GUIDE](DEPLOYMENT_GUIDE.md)

**Understand the architecture:**
→ [ARCHITECTURE](ARCHITECTURE.md)

**Test my workflows:**
→ [TESTING_GUIDE](TESTING_GUIDE.md)

**Contribute to the project:**
→ [CONTRIBUTING](../CONTRIBUTING.md)

---

## 📖 Documentation Philosophy

This documentation follows these principles:

1. **Problem-Focused:** Each API explains what problem it solves, not just what it does
2. **Example-Heavy:** Real-world code examples for every feature
3. **Production-Ready:** Deployment, testing, and operational guidance included
4. **AI-Ready:** Special focus on LLM/agent integration patterns
5. **Complete:** Every public API is documented with type specs and examples

---

## 🔗 External Resources

- **Hex Package:** https://hex.pm/packages/singularity_workflow
- **GitHub Repository:** https://github.com/Singularity-ng/singularity-workflows
- **Issue Tracker:** https://github.com/Singularity-ng/singularity-workflows/issues

---

## 📝 Documentation Versioning

Documentation is versioned alongside the library. Current version: **0.1.5**

For previous versions, check the [CHANGELOG](../CHANGELOG.md) and git tags.
