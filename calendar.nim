import math

# type definition moved to type_defs
import type_defs


## Taken from Incursion
##"Reprise", "Icemelt", "Turnleaf", "Blossom" --spring/summer
## "Suntide", "Harvest", "Leafdry", "Softwind", --summer/fall
## "Thincold", "Deepcold", "Midwint", "Arvester", --fall/winter


var calendar_data = [
    (30, "Arvester"),
    (1, "Midwinter"),
    (30, "Reprise"),
    (30, "Icemelt"),
    (30, "Turnleaf"), # April
    (1, "Greengrass"),
    (30, "Blossom"), # May
    (30, "Suntide"), # June
    (30, "Harvest"),
    (1, "Midsummer"),
    (30, "Leafdry"), # August
    (30, "Softwind"),
    (1, "Highharvestide"),
    (30, "Thincold"),
    (30, "Deepcold"), # November
    (1, "Year Feast"),
    (30, "Midwint") #December
  ]

var MINUTE = int(60/10);
var HOUR = MINUTE*60
var DAY = HOUR*24
var YEAR = DAY*365


# constructor so that we can provide default values
proc newCalendar*(start_year=1370, start_day=1, start_hour=1) : Calendar =

    var d = 0;
    # set up calendar days (year length)
    for m in calendar_data:
        d = d + m[0]

    Calendar(start_year: start_year, start_day: start_day, start_hour: start_hour, days: d);

proc get_time(cal: Calendar, turn: int) : (int, int) =
    var turn = turn + cal.start_hour * HOUR
    var minute = int(math.floor((turn mod DAY) / MINUTE))
    var hour = int(math.floor(minute / 60))
    minute = minute mod 60
    return (hour, minute)

proc get_day(cal: Calendar, turn: int) : (int, int) =
    var turn = turn + cal.start_hour * HOUR
    var d = int(math.floor(turn / DAY)) + (cal.start_day)
    var y = int(math.floor(d / 365))
    d = d mod 365
    return (d, cal.start_year + y)

proc get_month_num(cal: Calendar, day:int) : int =
    var i = len(calendar_data)

    while i > 0 and (day < cal.days):
        i -= 1

    return i

proc get_month_name(cal: Calendar, day: int) : string =
    var month = cal.get_month_num(day)
    return calendar_data[month][1]

proc get_time_date*(cal: Calendar, turn: int) : string =
    var data = cal.get_day(turn)
    var month = cal.get_month_name(data[0])
    var time = cal.get_time(turn)
    return ("Today is " & $data[0] & " " & $month & " of " & $data[1] & " DR. The time is " & $time[0] & ":" & $time[1]);