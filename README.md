![Homebrew](https://github.com/lithammer/homebrew-deadsnakes/workflows/Homebrew/badge.svg)

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

To avoid conflicts with, the formulas are installed as keg-only. Meaning
you will have to manually add them to your `$PATH` or create appropriate
symlinks.

## Supported Python versions

- 2.7 (2.7.18)
- 3.5 (3.5.9)
- 3.6 (3.6.10)
- 3.9 (3.9.0b1)

## License

MIT
