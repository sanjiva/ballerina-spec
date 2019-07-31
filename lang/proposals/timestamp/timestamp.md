# Date and time

The Ballerina language does not provide any built-in types relating to date and time. Many comparable systems (XML Schema datatypes, SQL, Google protocol buffers) provide support one or more data types relating to date and time.


## Timestamp type

This document proposes the addition of a new simple basic type, called timestamp, based on [RFC 3339 Date and Time on the Internet: Timestamps](https://tools.ietf.org/html/rfc3339).

RFC 3339, which is a profile of ISO 8601, defines a standard format for a string representation of date+time, which uses the Gregorian calendar to specify unambiguously an instant of time on the UTC time scale.

RFC 3339 allows for the use of time zone offsets, with Z meaning +00:00, so the following are all equivalent, in the sense that they refer to the same time:

```
1996-12-19T16:39:57-08:00
1996-12-20T00:39:57Z
1996-12-20T00:39:57+00:00
```

Note that RFC 3339 does not allow use of time zone names (other than Z), since that would not be a self-contained unambiguous representation of an instant of time.

The timestamp type would support at least the following fundamental operations:

*   equality: two timestamps are == if they refer to the same instant in time
*   ordering: ordering of timestamps follows the ordering of the instants of time they represent, and so is consistent with ==
*   string conversion: timestamps can be converted to and from strings using the RFC 3339 representation
*   identity: two timestamps are === if their string representations are ==
*   scalar conversion: timestamps can be converted to and from a value representing the duration in seconds from some epoch
*   break down: conversion to and from a broken down format, in which each component (year/day/month/hour/minute/second etc) would be available separately

The distinction between equality and identity for timestamps is similar to what we already have for decimal where 1.0 is == to 1.00 but not ===.

There are a number of detailed issues to work out:

*   precision: RFC 3339 allows an arbitrary number of digits after the decimal point; how many digits should timestamp preserve
*   range: RFC 3339 allows any four digit year; what should timestamp allow?
*   duration: what Ballerina value should scalar conversion use to represent duration in seconds
*   epoch: what should the epoch for scalar conversion be
*   lexical significance: if you convert from a string to a timestamp and back again, what information, if any, is lost
*   leap seconds: how to handle leap seconds
*   standard library: the date/time facilities of the standard library need to be designed to work smoothly with this

### Rationale

Why call it `timestamp`?

*   Makes it clear what it is
*   Consistent with main relevant standard (RFC 3339)
*   SQL standard uses `timestamp` to mean the combination date and time, although it provides variants both with and without time zone
*   Google protobuf uses [timestamp](https://developers.google.com/protocol-buffers/docs/reference/java/com/google/protobuf/Timestamp)

Another possible name would be `datetime`.

Why a built-in type?

*   By making it a built-in simple type, we can at the same time
    *   support widely used RFC3339/ISO8601 syntax for time
    *   support equality/ordering operation
    *   support scalar conversion
*   Timestamps are important for distributed computing
*   Most systems of data types include this type

What about other date/time related types? Mostly they should be done as library types. Other possible types are:



*   date-time without timezone (meaning in local time)
    *   not supported by any RFC
    *   limited utility in an application that may be distributed globally, over multiple time zones
    *   problems with daylight savings time; one hour's worth of values can get repeated when clocks go back
    *   semantics are not self-contained: only really meaningful w.r.t. some time zone
    *   time zone database will be in standard library, not in lang library
*   date
    *   not supported by any RFC
    *   time zone problem
        *   if it conceptually refers to a 24 hour time internal, then a time zone is needed to unambiguously specifi
        *   ISO 8601 date syntax does not include time zone
        *   XML Schem


## Literal syntax

RFC3339 timestamp can be allowed as literal syntax. This would be particularly useful when we have the Ballerina equivalent of JSON (which we have been calling BVN).

Constructor

We can use the functional constructor syntax. It would support either



*   a single positional string argument, same as the literal syntax,


## Precision

Proposed precision is nanoseconds: timestamp would round to the nearest nanoseconds.


### Rationale

There seems to be a good degree of consensus that nanoseconds (i.e. at most 9 digits after the decimal point) is just about right for timestamps:



*   Java 8 does nanoseconds
*   Go does nanoseconds
*   the difference between master atomic clocks that maintain UTC is of the order of a few nanoseconds
*   modern POSIX/Linux uses a struct timespec, which uses nanoseconds
*   Apple's latest filesystem (APFS) uses nanosecond timestamps
*   current financial regulations (e.g. MiFID II) require microsecond timestamp granularity
*   most advanced GPS receivers as of 2019 can do 5ns accuracy
*   Win32 timestamps are 100 nanoseconds
*   Google protobuf does nanosecond

For measuring short periods of time, you might want a bit more (a modern CPU cycle is about 0.3 nanoseconds).


## Leap seconds

RFC 3339 has support for leap seconds. For example, this (from the RFC) \



```
    1990-12-31T15:59:60-08:00
```


represents the leap second inserted at the end of 1990. The timestamp data type can correctly handle timestamps for instants of time occurring during leap seconds.

Most operations have an obvious, well-defined behaviour as regards such instants, specifically:



*   equality
*   identity
*   ordering
*   string conversion
*   break down

Scalar conversion should not include either positive or negative leap seconds. In other words, you measure time duration by advancing in sync with TAI, except that you



*   do not advance for one second during a positive leap second, and
*   skip forward one second during a negative leap second.

There would then be a separate operation to return the duration of a partially elapsed leap second.


### UTC and leap seconds

Historically, timekeeping was based on astronomy. One day means one rotation of the earth on its axis; a second was defined as 1/86,400 of a day (26*60*60 = 86,400). Now in fact the time the earth takes to rotate about its axis is not perfectly uniform, and the invention of quartz clocks and later atomic clocks made it possible to measure this. This results in what might be called the fundamental trilemma of precision timekeeping: there are three "obvious" properties that  a timekeeping system should have, but any timekeeping system can only provide two of them:



1. A "second" should have a precise, uniform duration
2. A "day" should mean one rotation of the earth on its axis
3. Every "day" should have the same number of "seconds"

Leap seconds, which are part of the definition of the UTC time scale, are the solution that the relevant standards body, the International Telecommunications Union (ITU), devised to this trilemma, and it involves giving up on property 3.

The current version of UTC, which includes the concept of leap seconds, went into effect in 1972 and works like this:



*   UTC seconds are always SI seconds of uniform duration defined in terms of a network of atomic clocks.
*   A normal UTC day consist exactly 86,400 of these SI seconds.
*   There is an international body, International Earth Rotation and Reference Systems Service (IERS), responsible for using astronomical observations to monitor the rotation of the earth
*   The last UTC day of a month may have 86,401 or 86,399 seconds if the IERS determines that this is necessary in order to keep UTC diverging by more than 0.9s from astronomical time (called UT1). A second that is inserted or omitted in this way is called a leap second. A leap second occurs simultaneously throughout the world at midnight UTC.
*   So far every leap second has been a positive leap second (resulting in a day with 86,401 seconds), and it is currently expected that all future leap seconds will be positive leap seconds.
*   Preference is given to June and December as the months for leap seconds. So far it has never been necessary to have leap seconds in other months.
*   IERS usually publishes a bulletin in January and July announcing whether there will be a leap second at the end of the following June or December

IERS also make available on the Web a [leap seconds lists](https://hpiers.obspm.fr/iers/bul/bulc/ntp/leap-seconds.list), which is a text file listing all leap seconds that have occurred or have been announced. It also includes an expiry date, beyond which the occurrence of leap seconds has not yet been determined.

There is another time scale, called TAI (French for International Atomic Time), which does not have leap seconds. The difference between TAI and UTC is always a fixed number of seconds. At the introduction of UTC, TAI was 10 seconds ahead; each time a positive leap second is introduced into UTC, the difference increases by 1 second. As of 2019, it is 37 seconds ahead. The leap seconds list includes the offset between TAI and UTC immediately after each leap second.

The UTC standard (ITU-R TF.460-6) specifies how to date events that occur in the vicinity of a leap second, by allowing the seconds' component of the date to be >= 60 during a positive leap second.

UTC has been universally adopted as the basis of civil timekeeping, and is enshrined in legislation in many countries. Financial regulations in the US (FINRA) and Europe (MiFID II) require regulated institutions to have timestamp events traceable to UTC, with permitted deviations in some cases no more than 100 microseconds.


### Implementation

Most computer systems maintain time as a number of seconds and fractions of a second from some epoch. They typically use one of the following strategies to deal with positive leap seconds:

*   ignore them: after a leap second, the system clock will be wrong, and will eventually get corrected in the same way as it gets corrected after it becomes wrong for other reasons
*   put the clock back by one second:  the clock can be put back immediately before or immediately after the leap second; this means that two events one second apart in the vicinity of a leap second will have the same timestamp
*   smooth them: make seconds in the vicinity of a positive leap second be slightly longer than usual
*   use TAI (or some fixed offset from TAI): the clock maintains time in UTC, and then use the leap seconds list to convert that to UTC

There are many systems that work together to enable accurate UTC timekeeping. Notably:


*   the IANA time zone database includes leap second information; this database is continually updated with changes to time zones throughout the world (such as rules on daylight saving time); these updates get including in operating system and other platform updates
*   GPS (and some other GNSS constellations) maintains time as a fixed offset from TAI (19 seconds behind); GPS satellites periodically (every 12.5 minutes) broadcast information about leap seconds, including the current offset from UTC time, so that GPS receivers can report time in UTC; some GPS receivers make the offset from TAI available to clients (the Russian GNSS constellation, GLONASS, maintains time in UTC)
*   NTP timestamps are seconds and binary fractions of a second in UTC, i.e. ignoring leap seconds. NTP messages include flags saying whether the current UTC day has a positive or negative leap second. After a positive leap second occurs, the NTP timestamps go back one second (i.e. one seconds worth of timestamps are repeated). These repeated timestamps can be distinguished from a timestamp representing the start of the following day because the flag saying the day has a positive leap section will be set for the repeated timestamps. The leap seconds list specifies the time of leap seconds as NTP timestamps.
*   When Linux is used in conjunction with NTP, the NTP client tells the kernel the day has a positive or negative leap second, and this will cause the kernel to adjust the system clock backwards or forwards by one second at the start of the leap second. There is a system call (ntp_adjtime) to get the NTP leap second flags, and this can be used to get correct UTC timestamps. If you don’t take advantage of this, you will get a second’s worth of repeated timestamps. Some NTP clients (notably chrony) have the ability to do smoothing to avoid this.
*   Google and AWS have started using the same smoothing technique (they call it leap smearing), whereby the leap second is smoothed over the noon to noon period that includes the leap second; each "second" during this period is 86401/86400 of an SI second, and the clock will thus be different from UTC by 0.5s at midnight when the leap second occurs. In effect this is using a different solution to the trilemma, where uniformity of seconds is dropped. Google and AWS implement this by having NTP servers report smeared time and do not report leap seconds. This is not compatible with how public NTP servers are supposed to behave and problems smearing servers are mixed with non-smearing servers. NTP clients do smoothing differently from the Google/AWS leap smearing.
*   Microsoft for both Windows and Azure has decided not to do leap second smearing. In recent versions of Windows, processes can opt in to getting system time including leap seconds. Their argument against smearing is that it is incompatible with regulatory requirements. This is partly marketing: if you have a well-defined smear like the Google/AWS and you know that you have this smear, then you can convert accurately between smeared time and UTC time (using the leap second list).
*   RFC 3339, following ISO 8601, specifies a syntax for timestamps for instants that occur during a positive leap second: following the UTC standard, the seconds field is allowed to have a value >= 60 and < 61.


### Conclusions

*   The language should not be dogmatic about how to handle leap seconds, and should work well in environments that handle leap seconds in different ways.
*   Leap second smearing, particularly in the form done by Google and AWS, is a pragmatic approach for many kinds of application, but is not really a correct way to deal with UTC as it has been standardized and is a poor fit for applications where regulations require that UTC is dealt with precisely as standardized.
*   It should be possible to do conversion between timestamp and a duration without relying on the leap second list and without being limited to the expiry date of the leap second list.
*   This means that the number returned by scalar conversion cannot include leap seconds in the past.
*   If the scalar conversion does not include past leap seconds, it is more consistent for it not to include any leap seconds at all, including parts of leap seconds that immediately precede the instant of the timestamp.


## Lexical significance

Will not preserve:

*   more than nanosecond precision
*   use of T vs t to separate date and time (RFC 3339 allows both)
*   use of Z vs z vs +00:00 to represent a time zone offset of 0 (RFC 3339 says they are equivalent)

Will preserve:

*   time zone offset
*   precision of seconds component (i.e. number of digits following decimal point) up to 9 (since we already do this for decimal)

Not sure:

*   use -00:00 vs +00:00.
    *   RFC 3339 says:

            If the time in UTC is known, but the offset to local time is unknown, this can be represented with an offset of "-00:00".  This differs semantically from an offset of "Z" or "+00:00", which imply that UTC is the preferred reference point for the specified time.

    *   Probably should since we distinguish +0 and -0 for binary floating point

The information that affects === but not == can be packed easily in 16 bits:



*   11 bits for unsigned time zone offset in minutes (60 * 24 = 1440 < 2048 = 2<sup>11</sup>)
*   1 bit for time zone offset sign
*   4 bits for precision


## Epoch

Epoch is 2000-01-01T00:00:00Z


### Rationale

It's a  "round" number, which is close to but not before the current time.

It's better to be reasonably close to the current time because:


*   Ballerina's numeric types are signed
*   it's useful if available precision increases as time gets closer to the present (identifying an event thousands of years in the past or future with nanosecond precision is of limited utility)

Common computer epochs are:


*   Unix: 1970-01-01T00:00:00Z (the first version of Unix was written in 1970)
*   NTP: 1900-01-01T00:00:00Z (first version of NTP appeared in 1980)
*   Win32: 1601-01-01T00:00:00Z (the start of a 400-year cycle of the Gregorian calendar)

It would be more calendrically elegant to use 2001-01-01T00:00:00Z, but I think it's a bit too obscure.


## Time duration

A duration of time is represented using a decimal value containing a number of seconds.

This should be used not just in conjunction with the timestamp type, but throughout the standard library. In particular, the standard library will need to support a concept of monotonic time, which is a duration of time since an epoch which may be different between invocations of a Ballerina program, but which is guaranteed to be monotonically increasing even in the presence of system clock changes. Monotonic time would be represented by a decimal, giving the duration in seconds from the epoch.

We can also support int as a representation for when only whole numbers of seconds are involved and the range is guaranteed to fit in an int.

We could also allow `s` as a floating point suffix with the same meaning as `d`. So when writing a duration, you can write e.g. write 10 seconds as `10s` instead of `10d`.


### Rationale

Why not a separate duration type?



*   It is tempting to have a separate duration type and make arithmetic timestamp/duration arithmetic work
    *   timestamp + duration => timestamp
    *   duration + duration => duration
    *   timestamp - duration => timestamp
    *   timestamp - timestamp => duration
*   No way to make this work consistently with leap seconds
*   Time measured in seconds is just one of several SI base units (along with length in metres, mass in kilograms, amperes for electrical current). No reason to specially privilege duration. Can have general concept of quantity (number with units), for which one can define a system of arithmetic. 2m / 2s = 1 m/s

Why decimal rather than float/int and why seconds as the unit?



*   Decimal has enough precision to represent the lifetime of the earth in nanoseconds
*   For shorter durations (e.g. centuries), decimal has more than enough precision to represent time which as much precision as could conceivably be needed.
*   Decimal includes a concept of precision, which can work in conjunction with the precision of the timestamp
*   RFC 3339 timestamps use decimal seconds, and this will represent them exactly
*   Computer representations of time are typically as one or more integers representing a decimal fraction of seconds (e.g. milliseconds or seconds+nanoseconds). These representations can be converted exactly into a decimal value
*   Decimal means that users do not have to know or care what the precision is
*   Users will not have to worry about overflow
*   The SI unit of time is a duration
*   Ballerina is unlike other languages in having a decimal type from the beginning; so we ought to take advantage of this.
*   This will not be optimally efficient for a Java-based implementation, particularly one that used BigDecimal for its representation of decimal. However, this can be improved by using an implementing a fixed-size 128-bit implementation of decimal.
*   XML schema part 2 uses decimal seconds as the value space for timelines
*   Google protobuf3 represents duration as 64-bit signed sconds

Alternative

Google protobuf3 has duration as 64-bit signed seconds plus 32-bit signed nanoseconds


## Range

The number of seconds since the epoch is limited to what is representable by a 64-bit signed integer.


### Rationale

We ought to enable a fixed size representation. 64 bits is not viable given nanosecond precision, and the lexical information that we need to preserve. So it makes sense to aim for 128-bits (the same size as decimal).

We should support a range that conveniently fit into a 128-bit representation of timestamp, assuming nanosecond precision e.g.


```
struct timestamp {
  // signed seconds since the epoch, excluding leap seconds
  int64 seconds;
  // Nanoseconds part of time since the epoch.
  // Always positive.
  // Normally this is less than 1,000,000,000
  // but timestamps during a positive leap second are represented
  // with a nanoseconds fields that is >= 1,000,000,000
  // and < 2,000,000,000.
  // If nanoseconds field is n >= 1,000,000,000 then
  // n - 999,999,999 nanoseconds of the leap second have elapsed.
  // A timestamp whose string representation
  // has a seconds field of "60.000" will have a
  // nanoseconds field of 1,0000,000,000;
  // if the string has "60.999999999",
  // then the nanoseconds field will be 1,999,999,999.
  // Converting to a scalar value will
  // use max(nanoseconds, 999999999).
  unsigned32 nanoseconds;
  // time zone offset that was used to specify the timestamp,
  // in minutes;
  // the seconds and nanoseconds fields are in UTC
  short timeZoneOffsetMinutes;
  // this is non-zero only if timeZoneOffset is zero
  // it means use -00:00 instead of Z
  char localTimeZoneOffsetUnknown;
  // number of digits after decimal point, in seconds field
  char secondsPrecision;
};
```


(This representation is inspired by an [old proposal](https://www.cl.cam.ac.uk/~mgk25/time/c/) for ISO C.)

Background info:



*   Java 8 Instant type uses long seconds + int nanoseconds (i.e. 96 bits)
*   Gregorian calendar was first adopted in 1582
    *   dates before were typically reckoned using the Julian calendar
    *   _proleptic_ Gregorian calendar means to the use of the Gregorian calendar to refer to dates that occurred before the Gregorian calendar was adopted
    *   RFC 3339 and ISO 8601 use proleptic Gregorian calendar
    *   year 0 in proleptic Gregorian calendar is 1 BC 
*   Julian day numbers, which are the most well-established standard form of day numbering, starts from 1 January 4713 BC (in the proleptic Julian calendar); these are commonly used in astronomy and applications where elapsed days are important (like food expiry)
*   modified Julian dates (roughly leaving out first two decimal digits of Julian day numbers) start in 17 November 17 1858
*   Holocene epoch (current geological epoch, starting at the end of the last ice age) about 11,700 years ago
*   RFC 3339 grammar allows for any 4 digit year number
    *   Because of time zone offsets, the timestamps allowed by the grammar do not correspond to a range of time instants (e.g. 9999-12-31T23:00:00-08:00 is allowed by RFC 3339, but its equivalent with +00:00 time zone offset is not)
*   ISO 8601 says proleptic use of Gregorian calendar should only be by agreement between the partners in information interchange
*   64-bit signed count of nanoseconds can express a range of about ±292 years
*   Unix signed 32-bit seconds will overflow in year 2038


## Lang library

See [lang.timestamp module](timestamp.bal).

## Standard library


### Current time

Functions to return current values of



*   monotonic time as a decimal
*   wall-clock time as a timestamp
    *   should have named argument specifying precision, which should default to something reasonable (0 probably); a default of 0 will discourage people from using wall-clock time when they should be using monotonic time
    *   what should the time-zone offset be, or should there be an argument controlling this?
        *   Z time-zone offset (not really correct if this is not in fact the local time-zone offset)
        *   local-time zone offset (how useful is this for network distributed applications, where different parts may well be running in different time zones?)
        *   unspecified/unknown local time-zone (i.e. -00:00)
    *   should there be some control over leap-second handling?
        *   the default should be whatever the system gives you
        *   should there be an optional argument to smooth?
*   time-zone offset; this is a time duration so it should be returned as a decimal number of seconds
    *   this can presumably change during the execution of a program, for example if daylight saving time comes into effect, or if the computer moves between time zones


### Leap second list

The standard library will have a leap second list, which can be used to provide a number of useful operations. Note that these operations will fail if they are applied to times beyond the expiry of the leap second list.



*   Convert between timestamps using smoothed time (either the Google/AWS smear, or some other smear) and timestamps that correctly follow the definition of UTC (and RFC 3339)
*   Convert between UTC and TAI
*   Determine the elapsed time (i.e. time including leap seconds) between two UTC timestamps

One interesting issue is how to deal with updates to the leap second list, which might potentially happen during a long-lived Ballerina process.


## Alternative approach to leap seconds

Just say no!



*   Do not support leap seconds in the timestamp basic type
*   fromString on an RFC 3339 timestamp with seconds >= 60 returns an error

Deal with leap seconds as follows:



*   Require the system to use some technique to provide a model in which every day has 86,400 seconds and to generate timestamps using this model. Technique could be
    *   unaware of leap seconds
    *   put the clock back
    *   smoothing
    *   fixed offset from TAI
*   Provide a library function for the user to find out which technique the system is using (e.g. as a string enumeration); one value will be unknown
*   In the case where the system is using a technique that has a well-defined mapping to and from UTC, provide functions to perform this mapping
*   in the case where fromString is applied to a valid RFC 3339 timestamp that is during a leap second, return a specific subtype of error (e.g. LeapSecondError), which includes the timestamp of the start of the leap second, and the duration of the elapsed part of the leap second
*   make BrokenDown type allow leap seconds, and provide conversions between BrokenDown and timestamp, and between BrokenDown and RFC3339 strings
    *   BrokenDown is thus conceptually the intermediate step in converting between timestamps and RFC 3339 strings
    *   converting from BrokenDown to timestamp could cause a LeapSecondError
    *   converting between BrokenDown and RFC3339 strings does allow leap seconds
    *   the result of an unsmoothing operation would be a BrokenDown value
    *   probably BrokenDown would be in the standard library, not the timestamp lang module
    *   probably BrokenDown would be an object

