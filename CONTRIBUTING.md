# Contributing

## Local hooks

Install the project hooks once after cloning:

```bash
make hooks-install
```

The hooks enforce Conventional Commits, run Gitleaks when installed, and run
the ShellCheck, metadata, preflight, and module coverage gates. CI remains the
authoritative secret scan when Gitleaks is not installed locally.
