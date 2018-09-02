# watir

Watir Powered By Selenium!

[![Gem Version](https://badge.fury.io/rb/watir.svg)](http://badge.fury.io/rb/watir)
[![Travis Status](https://travis-ci.org/watir/watir.svg?branch=master)](https://travis-ci.org/watir/watir)
[![AppVeyor status](https://ci.appveyor.com/api/projects/status/9vbb7pp5p4uyoott/branch/master?svg=true)](https://ci.appveyor.com/project/p0deje/watir)
[![Code Climate](https://codeclimate.com/github/watir/watir.svg)](https://codeclimate.com/github/watir/watir)
[![Dependency Status](https://gemnasium.com/watir/watir.svg)](https://gemnasium.com/watir/watir)
[![Coverage Status](https://coveralls.io/repos/watir/watir/badge.svg?branch=master)](https://coveralls.io/r/watir/watir)

## Example

```ruby
require 'watir'

browser = Watir::Browser.new

browser.goto 'watir.com'
browser.link(text: 'Guides').click

puts browser.title
# => 'Guides – Watir Project'
browser.close
```

## Using Watir

Everything you need is on the [Watir website](http://watir.com): news, guides, additional resources, support information and more.

If you are interested in contributing to the project or the ecosystem, continue reading this README.

## Implementation

The majority of element methods Watir provides is autogenerated from specifications.
This is done by extracting the IDL parts from the spec and processing them with the WebIDL gem (link below).
Currently supported specifications are:

* [HTML](https://www.w3.org/TR/2017/PR-html51-20170803/single-page.html) (`lib/watir/elements/html_elements.rb`)
* [SVG](https://www.w3.org/TR/2016/CR-SVG2-20160915/single-page.html) (`lib/watir/elements/svg_elements.rb`)

## Specs

### WatirSpec

Watir uses WatirSpec for testing - an executable specification of Watir API.

#### Using In Other Gems

When developing Watir extension, you might want to make sure it's fully compatible with
existing API. To achieve that, you can run WatirSpec against your own extension. Assuming
your gem depends on Watir, you should do next:

First, add WatirSpec Rake tasks to your gem:

```ruby
# Rakefile
require 'watirspec/rake_tasks'
WatirSpec::RakeTasks.new
```

Second, initialize WatirSpec for your gem:

```bash
$ bundle exec rake watirspec:init
```

After initialized, just follow the instructions to customize Watir implementation in use.

### Watir-specific Specs

Specs specific to Watir are found in `spec/*_spec.rb`, with watirspec in `spec/watirspec/`.

### Doctests

Watir uses [yard-doctest](https://github.com/p0deje/yard-doctest) for testing documentation examples.

```bash
rake yard:doctest
```

## Note on Patches/Pull Requests

* Fork the project.
* Clone onto your local machine.
* Create a new feature branch (bonus points for good names).
* Make your feature addition or bug fix.
* Add tests for it. This is important so we don't unintentionally break it in a future version.
* Commit, do not change Rakefile, gemspec, or CHANGES files.
* Push to your forked repository.
* Send a pull request.

## Copyright

Copyright (c) 2009-2015 Jari Bakken
Copyright (c) 2015-2018 Alex Rodionov, Titus Fortner
See LICENSE for details
