[![Build Status](https://travis-ci.org/ALShum/hashids-r.svg?branch=master)](https://travis-ci.org/ALShum/hashids-r)

# Hashids in R

An R port of the [hashids library](http://www.hashids.org).  hashids generates YouTube-like ids (hashes) from integers or vector of integers.  Hashes generated from integers are relatively short, unique and non-sequential and can be used to generate unique ids for URLs and hide database row numbers from the user.  By default hashids will avoid generating common English cursewords by preventing certain letters being next to each other.

For example, integers like `1`, `2` and `3` will be encoded as strings like `NV`, `6m` and `yD` respectively.  Vectors like `c(1, 2, 3, 4)` will be encoded as a string like `agHLu9hm` and `c(1, 1, 1, 1)` as `2bHEH5HY`.

## Why should I use Hashids?
1. Unguessable: incremental numbers encoded to prevent predictability.
2. Unique: no need to worry about hash collisions.
3. Customizable: custom alphabet and salt to customize generated hashids.
4. Two way function: decoding is done as easily as encoding.
5. Can specify minimum length for hashid.
6. By default, prevents curse words from being generated.

## Why should I NOT use Hashids?
* hashids is NOT cryptographically secure -- do NOT use to encode passwords.
* hashids is NOT cryptographically secure -- DO NOT USE TO ENCODE PASSWORDS.
* hashids is NOT CRYPTOGRAPHICALLY SECURE -- DO NOT USE TO ENCODE PASSWORDS!

## Other restrictions
1. Can only encode integers -- this is to prevent you from doing something stupid.  Like encoding sensitive information.
2. Integers must be non-negative.

## Installing
This package is now on CRAN!  Install using `install.packages("hashids")`.  Alteratively you can install using devtools to install the github version.  If you don't have devtools install using `install.packages('devtools')` from your R session.  Install using `devtools::install_github('ALShum/hashids-r')`.

## Summary
The following are the most relevant functions:

1. `hashid_settings`: used to set minimum length, salt, custom alphabet and custom guard.

2. `encode`: gives encoded string given integer and settings list from `hashid_settings`.

3. `decode`: gives integer given encoded string and settings list from `hashid_settings`.

4. `encode_hex`: similar to `encode` but works with hexadecimal.

5. `decode_hex`: similar to `decode` but works with hexadecimal.

## Example
Set your salt, min_length and any other settings using the `hashid_settings` function -- this will generate a list of important parameters for encoding and decoding:

`h = hashid_settings(salt = 'this is my salt', min_length = 5)`

Encode requires an integer and the settings as a list of parameters:

`encode(1234, h ) #"ABBQA"`

`encode(c(1, 2, 3, 4), h) #"agHLu9hm"`

Decode follows a similar workflow:

`decode("ABBQA", h) #1234`

`decode("agHLu9hm", h) #c(1, 2, 3, 4)`

## About
hashids was originally written by Ivan Akimov.  This version hashids was translated along with some of the unit tests from python version of hashids written by David Aurelio.  For more information please go to http://www.hashids.org.

## Compatibility
Compatible with version 1.0.* of the javascript version of hashids.

## Contact
Does my code suck?  Contact me and tell me!  [@notalexshum](http://twitter.com/notalexshum) on twitter more info about me @ http://www.ALShum.com.
