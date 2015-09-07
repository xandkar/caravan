Description
-----------

Simplest example, which doesn't even contact any external systems (the intended
use-case for `caravan`), just tries simple arithmetic tests.

Usage
-----

```sh
$ make
```

Example output:

![1 pass, 1 fail](https://raw.githubusercontent.com/ibnfirnas/caravan/master/examples/hello/screenshot.png)


The default Make target (`all`) will perform everything:

- install deps
- clean
- build
- run the example

See `Makefile` if you only want to run a subset of the operations.
