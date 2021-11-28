# rmapper

The rmapper module aims to take away the boilerplate of implementing mapping functions from and to Erlang's records.

This module is based on the idea that a Record should have a unique mapping specification for encoding and decoding, per format.

A same record can then easily be re-used to encode from/to JSON but also from/to your database layer.

## Status

The current version of the library is 0.1.0 and is subject for breaking changes until it reaches its first stable version.
