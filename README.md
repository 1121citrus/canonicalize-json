# canonicalize-json

A containerized [JCS (RFC 8785)](https://datatracker.ietf.org/doc/html/rfc8785) compliant JSON formatter, utilizing the [Python JCS](https://pypi.org/project/jcs) library.

The main author of the [Python JCS](https://pypi.org/project/jcs) library is
[Anders Rundgren](https://github.com/cyberphone). The original source code is at [cyberphone/json-canonicalization](https://github.com/cyberphone/json-canonicalization/tree/master/python3) including comprehensive test data.

## Usage

### Ordinary canonicalization

```sh
$ cat json | \
> tee >(sed 's/^/BEFORE: /' >/dev/stderr) | \
> docker run -i --rm 1121citrus/canonicalize-json:latest | \
> sed 's/^/AFTER: /'
BEFORE: {"z":{"o":"172","d":"122","h":"7A"},"1":{"h":"31","o":"61","d":"49"}}
AFTER: {"1":{"d":"49","h":"31","o":"61"},"z":{"d":"122","h":"7A","o":"172"}}
```

### Prettified canonicalization

```sh
$ cat json | \
> tee >(jq . | sed 's/^/BEFORE: /' >/dev/stderr) | \
> docker run -i --rm -e PRETTIFY=true 1121citrus/canonicalize-json:latest | \
> sed 's/^/AFTER: /'
BEFORE: {
BEFORE:   "z": {
BEFORE:     "o": "172",
BEFORE:     "d": "122",
BEFORE:     "h": "7A"
BEFORE:   },
BEFORE:   "1": {
BEFORE:     "h": "31",
BEFORE:     "o": "61",
BEFORE:     "d": "49"
BEFORE:   }
BEFORE: }
AFTER: {
AFTER:   "1": {
AFTER:     "d": "49",
AFTER:     "h": "31",
AFTER:     "o": "61"
AFTER:   },
AFTER:   "z": {
AFTER:     "d": "122",
AFTER:     "h": "7A",
AFTER:     "o": "172"
AFTER:   }
AFTER: }
```

## Configuration

| Variable       | Default | Notes                                                                                     |
| -------------- | :-----: | ----------------------------------------------------------------------------------------- |
| `DEBUG`        | `false` | If `true` then the shell script will enable options `xtrace` and `verbose`                  |
| `PRETTIFY`     | `false` | If `true` then the usual whitespace is inserted into the canonical JSON to make it pretty. |
| `PRETTY_PRINT` | `false` | Synonym for `PRETTIFY`.                                                                     |

## Building

1. `docker buildx build --sbom=true --provenance=true --provenance=mode=max --platform linux/amd64,linux/arm64 -t 1121citrus/canonicalize-json:latest -t 1121citrus/canonicalize-json:x.y.z --push .`

## Testing

Individual tests are `test/*.test`. To run all tests invoke `bash test/run-all-tests`

<!--
## Releasing

1. [Draft a new release on GitHub](https://github.com/1121citrus/canonicalize-json/releases/new)
-->
