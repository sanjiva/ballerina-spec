# lang.timestamp module
# public omitted to fit in line-length

# Convert from RFC3339 string
# Leap seconds allowed at the end of a UTC month only.
# Allow years that are not four digits
function fromString(string) returns timestamp|error;

// Epoch

const timestamp EPOCH = 2000-01-01T00:00:00Z;
const int EPOCH_YEAR = 2000;

// Scalar durations

type Seconds decimal;

# Does not count leap seconds
function toEpochSeconds(timestamp ts) returns Seconds;

# Panic if out of range
function fromEpochSeconds(Seconds seconds) returns timestamp;

// Time zone offsets

function timeZoneOffset(timestamp ts) returns Seconds;

# Returns a timestamp that refers to the same instant as `ts`
# but has a time zone offset of `offset` seconds.
# Panics if offset is not an integral number of minutes.
# An offset of nil means the local time zone is unknown
function withTimeZoneOffset(timestamp ts, Seconds? offset)
  returns timestamp;

// Leap seconds

# Does this timestamp occur during a positive leap second?
function inLeapSecond(timestamp ts) returns boolean;

# For a timestamp that occurs during a positive leap second, the
# the part of the leap second that has elapsed.
# This is 0 if inLeapSecond() is false
# and otherwise is > 0.0 and <= 1.0
function leapSecondPart(timestamp ts) returns Seconds;

# Returns a timestamp that is the same as `ts`, except
# that its leap second part is equal to `leapSecondPart`,
# rounded to nanoseconds.
# Panics if leapSecondPart, before rounding, is < 0.0 or > 1.0
function withLeapSecondPart(timestamp ts,
                            Seconds leapSecondPart)
  returns timestamp;
# like fromString, but do not allow seconds field >= 60
function fromNoLeapSecondsString(string) returns timestamp|error;

// Broken down time

type TimeZoneOffset {|
  # -00:00 and +00:00 are not the same
  (+1|-1) sign;
  # in the range 0...23
  int hour;
  # in the range 0...59
  int minute;
|};

type BrokenDown record {|
  # year in the proleptic Gregorian calendar:
  # * 1 means 1 AD i.e. year 1 of the Common Era
  # * 0 means 1 BC
  # * -1 means 2 BC
  int year;
  # in the range 1..11
  int month;
  # in the range 1..31
  int day;
  # in the range 0..23
  int hour;
  # in the range 0..59
  int minute;
  # in the range 0..<61
  decimal second;
  TimeZoneOffset timeZone;
|};

function fromBrokenDown(BrokenDown bd) returns timestamp|error;
function breakDown(timestamp ts) returns BrokenDown;

// Other possibilities
# This is like toEpochSeconds but ignores
# the fractional part of the duration
# and represents the result as an int.
# This is convenient for manipulations related to date
function toEpochSecondsInt(timestamp ts) returns int;
function fromEpochSecondsInt(int seconds) return timestamp;
// XXX function to calculate difference in seconds
// between two timestamps, not including leap seconds