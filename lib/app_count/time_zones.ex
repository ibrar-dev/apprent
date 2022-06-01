# Sister file to `assets/js/data/timeZones.js`
defmodule AppCount.TimeZones do
  # We get the list of strings of timezones from:
  #
  # Tzdata.zone_list() |> Enum.filter(fn(tz) -> tz =~ ~r(US) end)
  #
  # That list will include Samoa (outside our range) as well as Indiana and
  # Michigan (neither of which observed DST when the IANA began compiling the
  # time zone list). We sort what's left, generally by UTC offset, and end up
  # with this list.
  def timezones() do
    [
      "US/Eastern",
      "US/Central",
      "US/Mountain",
      "US/Arizona",
      "US/Pacific",
      "US/Alaska",
      "US/Aleutian",
      "US/Hawaii"
    ]
  end
end
