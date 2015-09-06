Description
-----------

Tests simple CRUD operations against Riak's HTTP API, logging each response.
Includes a simplified HTTP client abstraction in front of `cohttp`.

Usage
-----

```sh
$ make
```

The default Make target (`all`) will perform everything:

- install deps
- clean
- build
- run the example

See `Makefile` if you only want to run a subset of the operations.
``
