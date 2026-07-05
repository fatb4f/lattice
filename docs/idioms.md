# CUE Idioms

The idiom catalog is the canonical lattice surface for reusable CUE patterns.

The source registry lives in `idioms/` and records local kernel references,
official CUE documentation, example corpora, tutorials, and projection
substrates. Pattern entries in `patterns/` reference those source IDs directly,
so typos bottom during CUE validation.

Export the catalog with:

```sh
cue export ./exports -e cueIdiomCatalog
```

