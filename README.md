# homebrew-deadsnakes

This Homebrew tap provides formulas for Python versions that have been
deprecated and removed from the main Homebrew repository.

It also contains alpha/beta release of the next major Python version.

## Usage

To install Python 3.5:

```console
$ brew tap lithammer/deadsnakes
$ brew install python@3.5
```

To avoid conflicts, only the versioned Python binary in the format `pythonX.Y`
is symlinked to `${HOMEBREW_PREFIX:-/usr/local}/bin`.

## Supported Python versions

- 2.7 (2.7.18)
- 3.5 (3.5.10)
- 3.6 (3.6.12)
- 3.10 (3.10.0a3)

## License

MIT
