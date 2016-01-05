Baptize
===

Baptize is an extension for Capistrano, that allows for server provisioning. The API resembles [Sprinkle](https://github.com/sprinkle-tool/sprinkle), but the underlying implementation is quite different. Where Sprinkle tries to compile a static payload of commands and push to the server, Baptize is executed in runtime. It also reuses much more of Capistrano, than Sprinkle does. Basically, each Baptize package is a capistrano task - Baptize just adds some helpers and fancy dsl on top, to make it look declarative.

For now, there is virtually no documentation. Have a peek at `sample/` for an idea of how it works.
