# homebrew-deadsnakes

:warning: DEPRECATION NOTICE: Use something like rtx[^1], asdf[^2] or Rye[^3]
to manage your installed Python version(s) instead.

[^1]: https://github.com/jdx/rtx
[^2]: https://asdf-vm.com
[^3]: https://rye-up.com

---

This Homebrew tap provides formulas for Python versions that have been
deprecated and removed from the main Homebrew repository.

It also contains alpha/beta release of the next major Python version.

## Usage

To install Python 3.5:

```sh
brew tap lithammer/deadsnakes
brew install python@3.5
```

To avoid conflicts, only the versioned Python binary in the format `pythonX.Y`
is symlinked to `${HOMEBREW_PREFIX:-/usr/local}/bin`.

## Supported Python versions

- 2.7 (2.7.18)
- 3.5 (3.5.10)
- 3.6 (3.6.15)
- 3.12 (3.12.0a6)

## License

MIT
