# Contributing to Developer Tutorials

Thank you for your interest in contributing to Developer Tutorials! We greatly value feedback and contributions from our community.

## Reporting Issues

If you find a bug or have a suggestion for improving the Developer Tutorials, please open an issue in our GitHub repository. When filing an issue, please include:

- A clear description of the issue or suggestion
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Any relevant logs or error messages
- Your environment (OS, Python version, etc.)

## Contributing Code

We welcome code contributions through pull requests. Here's how to get started:

1. Fork the repository
2. Create a new branch for your feature or bug fix
3. Make your changes
4. Add or update tests as necessary
5. Run the test suite to ensure all tests pass
6. Commit your changes with clear, descriptive commit messages
7. Push your branch to your fork
8. Open a pull request against the main repository

## Development Setup

To set up your development environment:

```bash
# Clone the repository
git clone https://github.com/aws-samples/sample-developer-tutorials.git

# Navigate to the project directory
cd sample-developer-tutorials
```

## Generating tutorials

Follow the instructions in [instra/README.md](instra/README.md)

## Testing

All new scripts and tutorials need to be tested by the author. Attach a log from a successful test run to the pull request.

## Cleanup

The tool generates a lot of artifacts including intermediate script revisions that generate errors. Submit a pull request with only the final revision of the script and tutorial. Rename these after the use case follow this convention.

```
├── 001-lightsail-gs
│   ├── README.md
│   ├── lightsail-gs.md
│   └── lightsail-gs.sh
```

## Documentation

Add a readme for your contribution that describes its use case.

## Code of Conduct

This project adheres to the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## License

By contributing to Developer Tutorials, you agree that your contributions will be licensed under the project's [Apache License 2.0](LICENSE).
