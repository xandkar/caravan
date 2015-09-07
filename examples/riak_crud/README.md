Description
-----------

Tests simple CRUD operations against Riak's HTTP API, logging each response.
Includes a simplified HTTP client abstraction in front of `cohttp`.

Usage
-----

```sh
$ make
```

Example output when Riak is off:

![1 fail, 3 skip](https://raw.githubusercontent.com/ibnfirnas/caravan/master/examples/riak_crud/screenshot-riak-off.png)

Children of a failed test are skipped, since they're assumed to depend on state
produced by the parent test.

The default Make target (`all`) will perform everything:

- install deps
- clean
- build
- run the example

See `Makefile` if you only want to run a subset of the operations.
