# canonicalize-json
A containerized [JCS (RFC 8785)](https://datatracker.ietf.org/doc/html/rfc8785) compliant JSON formatter, utilizing the [Python JCS](https://pypi.org/project/jcs) library.

## Usage

### Example data
```sh
# cat data.son
{"z":{"dec":"122","hex":"7A","oct":"172"},"1":{"hex":"31","oct":"61","dec":"49"},"A":{"hex":"41", "dec":"65","oct":"101"}}
```

### Ordinary canonicalization
```sh
$ alias canonicalize-json='docker run -i --rm 1121citrus/canonicalize-json:latest'
$ cat data.json | canonicalize-json
{"1":{"dec":"49","hex":"31","oct":"61"},"A":{"dec":"65","hex":"41","oct":"101"},"z":{"dec":"122","hex":"7A","oct":"172"}}
```

### Prettified canonicalization
```sh
$ alias canonicalize-json-pretty='docker run -i --rm -e PRETTIFY=true 1121citrus/canonicalize-json:latest'
$ cat data.json | canonicalize-json-pretty
{
  "1": {
    "dec": "49",
    "hex": "31",
    "oct": "61"
  },
  "A": {
    "dec": "65",
    "hex": "41",
    "oct": "101"
  },
  "z": {
    "dec": "122",
    "hex": "7A",
    "oct": "172"
  }
}
```

## Configuration

Variable | Default | Notes
--- | --- | ---
`DEBUG` | `false` | If `true` then the shell script will enable options `xtrace` and `verbose`
`PRETTIFY` | `false` | If `true` then the usual whitespace is inserted into the canonical JSON to make it pretty.

## Building

1. `docker buildx build --platform linux/amd64,linux/arm64 -t 1121citrus/docker-volume-backup:latest .`
1. `docker buildx build --platform linux/amd64,linux/arm64 -t 1121citrus/docker-volume-backup:x.y.z .`

## Testing

Inididual tests are `test/*.test`. To run all tests iunvoke `bash test/run-all-tests`

<!--
## Releasing

1. [Draft a new release on GitHub](https://github.com/1121citrus/docker-volume-backup/releases/new)
-->
