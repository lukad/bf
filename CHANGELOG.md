# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v2.0.0](https://github.com/lukad/bf/compare/v1.4.0...v2.0.0) (2026-10-22)
### Breaking Changes:

* require Elixir 1.16 by [@lukad](https://github.com/lukad)

* stream input and output explicitly in Bf.run by [@lukad](https://github.com/lukad)

* return structured parse errors with positions by [@lukad](https://github.com/lukad)

* read 0 at the end of the input by [@lukad](https://github.com/lukad)

* require Elixir 1.15 and switch CI to setup-beam by [@lukad](https://github.com/lukad)

* return :ok from Bf.run/1 by [@lukad](https://github.com/lukad)

* make the program format opaque by [@lukad](https://github.com/lukad)

* move instruction and program types to Bf by [@lukad](https://github.com/lukad)

* replace Combine parser with hand-written parser and optimizer by [@lukad](https://github.com/lukad)



### Features:

* optimize multiplication loops by [@lukad](https://github.com/lukad)

* optimize clear loops, scan loops, and set in new optimizer by [@lukad](https://github.com/lukad)

### Bug Fixes:

* exit cli quietly when stdout is closed by [@lukad](https://github.com/lukad)

### Performance Improvements:

* replace Enum.each in mul_run with a recursive function by [@lukad](https://github.com/lukad)

* skip rem for nearby addresses in Bf.wrap/1 by [@lukad](https://github.com/lukad)

* inline private Bf.put/2, Bf.get/2 and Bf.wrap/2 by [@lukad](https://github.com/lukad)

* use :atomics for interpreter memory by [@lukad](https://github.com/lukad)

## [v1.4.0](https://github.com/lukad/bf/compare/v1.3.0...v1.4.0) (2018-10-18)




### Features:

* optimize add after loop into set by Luka Dornhecker

* use erlang array to improve performance by Luka Dornhecker [(#8)](https://github.com/lukad/bf/pull/8)

### Bug Fixes:

* don't sum sets by Luka Dornhecker

## [v1.3.0](https://github.com/lukad/bf/compare/v1.2.0...v1.3.0) (2018-09-28)




### Features:

* use binary as memory to improve performance by Luka Dornhecker

### Bug Fixes:

* don't eliminate empty loops unconditionally (#7) by Luka Dornhecker [(#7)](https://github.com/lukad/bf/pull/7)

* parse empty loop with comments inside correctly by Luka Dornhecker

* don't change cell when read returns eof by Luka Dornhecker

## [v1.2.0](https://github.com/lukad/bf/compare/v1.1.0...v1.2.0) (2017-05-01)




## [v1.1.0](https://github.com/lukad/bf/compare/v1.0.0...v1.1.0) (2017-04-30)




## [v1.0.0](https://github.com/lukad/bf/compare/v0.1.0...v1.0.0) (2017-04-28)




## [v0.1.0](https://github.com/lukad/bf/compare/v0.1.0...v0.1.0) (2017-01-23)



