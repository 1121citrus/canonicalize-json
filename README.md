# canonicalize-json
A containerized [JCS (RFC 8785)](https://datatracker.ietf.org/doc/html/rfc8785) compliant JSON formatter

## Usage

```sh
cat json | docker run -i --rm 1121citrus/canonicalize-json:latest > canonical-json
```
