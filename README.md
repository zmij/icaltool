#  icaltool

![image](https://user-images.githubusercontent.com/2694027/80321246-47060b00-8824-11ea-85af-722a80ea3b0f.png)

A command-line utility to work with OS X calendar events.

It queries the OC X calendar and outputs events in json format

## Usage

The usage is pretty straightforward, you execute the program in terminal passing it arguments. Without any arguments the program executes `events today` subcommand. You can get a desription of options and arguments by running the program with `--help` option.

```
OVERVIEW: Outputs events from calendar to console

USAGE: calendar-command <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  events                  Work with events
  list-calendars          List calendars
  list-date-formats       List supported input date formats
```

### Subcommands

#### events

Common options for `events` and it's subcommands:
* `calendar` use this calendar to get events, if not specified - get events from all available calendars
* `my-status` filter events by the status of current user, e.g. `pending`, `accepted`, `tentative`. Useful to filter events that overlap
* `all-day` filter all day events, options are: 
  * `show` don't filter all day events out
  * `dont-show`  filter all day event out
  * `only` show only all day events
* `recurring` filter recurring events, options are similar as for all day events
* `sort-order` the order to apply to output of events. Available options:
  * `none` just output the events in the order the calendar returns them
  * `start-date` sort events by their start date in ascending order 
  * `end-date` sort events by their end date in ascending order
  * `title` sort events by their title in ascending order
* `reverse-order` reverse the order of output. Doesn't apply to sort order `none`
* `show-attendees` show attendees in json output. By the attendees output is off
* `recurrency-rules` show recurrency rules in json output. By the recurrency rules output is off
* `date-format` output dates in specified format

The `events` command expects two options
* `start` Show events that start after this date
* `end` Show events that start before this date

When working with `events`' subcommands, the `events` command can be dropped

```
OVERVIEW: Display events in a range of dates

USAGE: calendar-command events <options> <subcommand>

OPTIONS:
  -c, --calendar <calendar>
                          Name of calendar to use
  -m, --my-status <my-status>
                          Show only events with my status equal to specified
  -a, --all-day <all-day> Filter all-day events (available options show, dont-show, only) (default: show)
  -u, --recurring <recurring>
                          Filter recurring events (available options show, dont-show, only) (default: show)
  -s, --sort-order <sort-order>
                          Event sort order (available options none, start-date, end-date, title) (default: none)
  -r, --reverse-order/--no-reverse-order
                          Sort in reverse order (default: false)
  --show-attendees/--no-show-attendees
                          Show event attendees (default: false)
  --recurrency-rules/--no-recurrency-rules
                          Show event recurrency rules (default: false)
  -f, --date-format <date-format>
                          Ouput date format (default: yyyy-MM-dd'T'HH:mm::ssZZZZZ)
  --start <start>         Events starting after, in ISO 8601 format (yyyy-MM-dd'T'HH:mm::ssZZZZZ)
  --end <end>             Events ending before, in ISO 8601 format (yyyy-MM-dd'T'HH:mm::ssZZZZZ)
  -h, --help              Show help information.

SUBCOMMANDS:
  now                     Events happening now
  today                   Events happening today
  at                      Events happening at a certain point of time
  in                      Events happening soon
  on                      Events happening on a specific date
```


##### today

Show events that happen today (that start after 00:00 and end before 24:00), no additional options.


##### now

Show events that happen now (that start before current moment and end after it), no additional options.

##### at

Show events that happen at a certan point of time (that start before the point of time and end after it), it requires an argument with the date

```bash
$ icaltool events at 2020-04-27T17:30 # Events that happen at 17:30, 27th April, 2020

$ icaltool at 2020-04-27T17:30 # Same effect
```

##### in

Show events that happen in some time distance from now (that start before the point of time and end after it), it requires an argument with the date interval. The interval format is [ISO 8601 Duration format](https://en.wikipedia.org/wiki/ISO_8601#Durations).

```bash
$ icaltool events in PT5M # Events that will be going on in 5 minutes, please note the T
$ icaltool events in P5M  # Events that will happen in 5 months, same as above without T 
```

##### on

Show events that happen on specified date (time part is ignored, events that start after 00:00 and end before 24:00 on that date are displayed).

#### list-calendars

This subcommand doesn't have any options. It just outputs avalilable calendars in json format.

#### list-date-formats

List supported input date formats for reference. Currently supported input formats are:
```
yyyy-MM-dd'T'HH:mm:ssZZZZZ
yyyy-MM-dd'T'HH:mm:ssZ
yyyy-MM-dd'T'HH:mm:ss
yyyy-MM-dd'T'HH:mm
yyyy-MM-dd
```

## Output

The output format is one-line json, no pretty-printing is provided. You can alway use [jq tool](https://stedolan.github.io/jq/) to format and filter JSON data.

### Calendars

The output for `list-calendars` is a JSON array containing JSON objects with calendar descriptions.

Example:
```json
{
  "uid": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "title": "dailies",
  "type": "calDAV",
  "subscribed": false,
  "immutable": false,
  "allow-content-modification": true,
  "color": "#b3dc6cff"
}
```

| field name                  | type    | description                                                       |
|-----------------------------|---------|-------------------------------------------------------------------|
| uid                         | string  | Identity of calendar                                              |
| title                       | string  | Human-readable name of calendar, you can use this name with `events` subcommand. Put it into quotes on the command line if it contains spaces |
| type                        | string  | Type of calendar                                                  |
| subscribed                  | bool    | true if the calendar is subscribed                                |
| immutable                   | bool    | true if you cannot modify attributes of the calendar or delete it |
| allow-content-modification  | bool    | true if you can add, remove, or modify items in this calendar     |
| color                       | string  | Hex RGBA color. The color can be modified in the Calendar.app     |

### Events

The output for `events` and subcommands is a JSON array containing events in JSON notation

Example:
```json
{
  "uid": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "calendar-id": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "url": "https://calendar.example.com/event?event_id=100500",
  "title": "Daily meeting",
  "notes": "Discussing daily stuff",
  "location": null,
  "start": "2020-04-28T10:00::00+03:00",
  "end": "2020-04-28T10:15::00+03:00",
  "all-day": false,
  "recurrent": true,
  "recurrence-rules": [
    {
      "interval": 1,
      "first-day-of-the-week": 2,
      "days-of-the-week": [
        {
          "day-of-the-week": "tuesday",
          "week-number": 0
        },
        {
          "day-of-the-week": "wednesday",
          "week-number": 0
        },
        {
          "day-of-the-week": "thursday",
          "week-number": 0
        },
        {
          "day-of-the-week": "friday",
          "week-number": 0
        }
      ],
      "frequency": "weekly",
      "reccurence-end": null
    }
  ],
  "detached": false,
  "occurrence-date": "2020-04-28T10:00::00+03:00",
  "status": "none",
  "availabilty": "busy",
  "my-status": "accepted",
  "attendees": [
    {
      "status": "accepted",
      "type": "person",
      "current_user": true,
      "url": "user@example.com",
      "name": "John Doe",
      "role": "required"
    },
    {
      "status": "accepted",
      "type": "person",
      "current_user": false,
      "url": "boss@example.com",
      "name": "Jane Doe",
      "role": "required"
    }
  ],
  "organizer": {
    "status": "accepted",
    "type": "person",
    "current_user": false,
    "url": "boss@example.com",
    "name": "Jane Doe",
    "role": "chair"
  },
  "color": "#0e61b9ff"
}
```

| field name                  | type    | description                                                             |
|-----------------------------|---------|-------------------------------------------------------------------------|
| uid                         | string  | Identity of the event                                                   |
| calendar-id                 | string  | Identity of the calendar event belongs to                               |
| url                         | string  | URL of the event as provided by the calendar server                     |
| title                       | string  | Title of the event, may be null                                         |
| notes                       | string  | Notes attached to the event, may be null                                |
| location                    | string  | Text description of the event's location, may be null                   |
| start                       | string  | Event start date in `dateFormat`                                        |
| end                         | string  | Event end date in `dateFormat`                                          |
| all-day                     | bool    | Is the event all day event                                              |
| recurrent                   | bool    | Is the event recurrent                                                  |
| recurrence-rules            | array of recurrence-rule | Objects describing recurrence<sup>[1](#fnote1)</sup>   |
| detached                    | bool    | Is the recurrent event detached from series<sup>[1](#fnote1)</sup>      |
| occurence-date              | string  | Date of recurrent event occurrence<sup>[1](#fnote1)</sup>               |
| status                      | string  | Status of the event                                                     |
| availabiltiy                | string  | Availability of event's attendees                                       |
| my-status                   | string  | Current user's status in this event                                     |
| attendees                   | array of attendees | Objects desribing participants<sup>[2](#fnote2)</sup>        |
| organizer                   | object  | Object describing participant that organizes the event                  |
| color                       | string  | Hex RGBA color of the calendar event belongs to. Optional               |


<a name="fnote1">[1]</a>: Shown only if `recurrence-rules` option is on<br/>
<a name="fnote2">[2]</a>: Shown only if `show-attendees` option is on
