"""Compatibility CLI wrapper for the authoritative :mod:`lattice` package."""

from lattice.cli import main

if __name__ == "__main__":
    raise SystemExit(main())
