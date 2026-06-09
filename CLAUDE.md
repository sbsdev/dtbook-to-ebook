# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A standalone Maven OSGi bundle that converts DTBook XML to EPUB3 for SBS (Swiss Library for the Blind). It wraps the standard DAISY Pipeline `dtbook-to-epub3` script with SBS-specific pre/post-processing, replacing an unmaintained fork of the Nordic EPUB3 DTBook Migrator.

Pipeline:
```
DTBook → SBS preprocessing (14 XSLTs) → daisy:dtbook-to-epub3 → SBS post-processing → EPUB3
```

## Requirements

- Java 8
- Maven 3.5+

## Commands

```sh
mvn clean package          # build
mvn test                   # run all tests
mvn test -Dxspec.includes=**/addBoilerplate.xspec  # run a single XSpec test
./scripts/compare-epub.bb compare-epub-config.edn  # regression test against production EPUBs
```

## Architecture

The SBS delta is composed of:
- **14 preprocessing XSLTs** (boilerplate injection, footnote relocation, image ref wiring, etc.) applied before the standard conversion
- **`accessibility.css`** with SBS-specific visual adjustments
- **Post-processing** for OPF accessibility metadata and content structure corrections
- **`translations.xml`** for i18n boilerplate (Italian, Sursilvan)

The main XProc entry point (`sbs-dtbook-to-epub3.xpl`) calls the upstream `dtbook-to-epub3.xpl` as a sub-step. The standard pipeline converts DTBook → ZEDAI → HTML → EPUB3.

Every SBS requirement in `doc/Requirements.org` must be covered by an XSpec test.

## Implementation plan (from ADR)

1. Write XSpec tests for every requirement (failing)
2. Copy 14 preprocessing XSLTs from the old module verbatim
3. Wire `dtbook-to-epub3.xpl` as the base step in `sbs-dtbook-to-epub3.xpl`
4. Port XSLT overrides (epigraph, prodnote-as-span, caption order, namespace cleanup, OPF metadata) as post-processing until XSpec tests pass
5. Add one end-to-end Maven integration test
6. Run regression tests against 100 production books via `scripts/compare-epub.bb`
7. Add module as Maven dependency to pipeline assembly; remove old `epub3-dtbook-migrator` subrepo

## Key documentation

- `doc/Architecture_Decision_Records.org` — why this approach was chosen over maintaining the fork
- `doc/Requirements.org` — full list of SBS-specific requirements (CSS, boilerplate, content structure, images/captions, OPF accessibility metadata, navigation, i18n)

## Regression testing

`scripts/compare-epub.bb` (Babashka) compares EPUB output between two Pipeline instances. Config (`compare-epub-config.edn`):
```clojure
{:prod-url   "https://pipeline.prod.example.com"
 :test-url   "https://pipeline.test.example.com"
 :token      "Token <your-jwt-token>"
 :output-dir "/tmp/epub-cmp"
 :limit      100}
```
