# Contributing to Raspberry Pi AI Skill

Thank you for your interest in contributing to this project!

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in the [Issues](https://github.com/malkreide/raspberry-pi-ai-skill/issues) section
2. If not, create a new issue with a clear title and description
3. Include examples of the problematic behavior, if applicable
4. Tag the issue appropriately (Bug, Enhancement, Question, etc.)

### Submitting Changes

1. **Fork the repository** to your own GitHub account
2. **Create a new branch** for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** with clear, descriptive commit messages
4. **Rebuild and validate** — CI runs the same checks:
   ```bash
   ./scripts/build-skill.sh          # rebuild raspberry-pi-ai.skill
   python3 scripts/validate-skill.py # manifest, frontmatter, links, archive freshness
   shellcheck scripts/*.sh
   ```
   Commit the rebuilt `raspberry-pi-ai.skill` together with your changes — it is checked
   into the repository, and CI fails if it does not match the sources.
5. **Submit a Pull Request** with:
   - Clear description of what you changed and why
   - Reference to related issues
   - Examples of the improvement, if applicable

### Releasing (maintainers)

Pushing a `v*` tag publishes a GitHub Release with the built `raspberry-pi-ai.skill`
attached — this is what the download link in the README resolves to.

```bash
git checkout main && git pull
git tag v1.1.0
git push origin v1.1.0
```

Creating the release through the web UI works as well — the workflow detects the existing
release and only attaches the asset.

The release workflow re-runs the validation, rebuilds the package, verifies the build is
reproducible, and refuses tags that do not point at a commit contained in `main`.

To publish a tag whose run failed, or one created before this workflow existed:
**Actions → Release → Run workflow → enter the tag**.

### Areas for Contributions

We are particularly interested in contributions in these areas:

- **Hardware compatibility** – Testing with different Pi models, HATs, and sensors
- **Edge AI integrations** – New AI frameworks, model optimizations
- **Debugging playbook** – Additional troubleshooting patterns and solutions
- **Component catalog** – New components with verified specifications
- **Documentation improvements** – Clarity, examples, translations
- **Multilingual support** – Translations and cultural adaptations

### Guidelines

- Follow the existing code style and documentation format
- Keep changes focused and atomic
- Add or rename packaged files only in [`skill-manifest.txt`](skill-manifest.txt) — the
  build script and the validator both read it
- Write clear commit messages
- Update documentation according to your changes
- Be respectful and constructive in discussions
- Use Swiss German spelling conventions for German content (no ß, use ss instead)

### Language

The SKILL.md and internal documentation are maintained in German (the skill works in any language as Claude adapts to the user's language). README and CONTRIBUTING files are available in both English and German.

When contributing documentation:
- **English** is preferred for code comments and technical documentation
- **German** contributions are welcome and will be translated if needed

### Questions?

If you have questions about contributing, don't hesitate to:
- Open a [Discussion](https://github.com/malkreide/raspberry-pi-ai-skill/discussions)
- Reach out via Issues
- Check the existing documentation first

## Code of Conduct

We are committed to creating a welcoming and inclusive environment. Please:

- Be respectful and considerate
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other contributors

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping improve this skill! 🙏
