# CourseMgmt

Course management scripts. Used to create appointments (calendar events) for courses and weeks.

**Note** Unlike most titles in this repository, these scripts are licensed under [GPL v2](LICENSE.md).

Currently, these scripts are only partially tested for Exchange accounts.

## Usage

The usage pattern is the following:

1. Use `.\New-Term.ps1` to create a term and store it in a variable (e.g., `$term`).
2. Use `.\New-Course.ps1` to create courses, store each course in a separate variable (or together in an array).
3. Use `.\Select-OutlookFolder.ps1` to select an Outlook calendar folder and store it in a variable (e.g., `$folder`).
4. Use `.\Publish-Term.ps1 -Term $term -OutlookFolder $folder` to publish the week numbers to the calendar.
5. Use `.\Publish-Course.ps1 -Term $term -Course $course -OutlookFolder $folder` to publish the courses to the calendar.

**Note** All operations are done with the default time zone, which is the current system time zone. You should adjust to the time zone for your academic institution before performing operations.

After publishing the items, the term/course objects will contain unique information that is hard to recover once lost. You should serialise all term/course objects (JSON would be good enough) for future reference. **Note** that if you are using `ConvertTo-Json`, use a large `Depth` parameter, e.g., 10.

The unique information is called a correlation identifier. All appointments created by the two `Publish-` scripts will have a user property `CourseMgmtCorrId`, which is a string of the “N” form of a GUID. The scripts use this property to further manipulate the appointments. This property is stored in the `CorrId` note property in term/course objects.

You might add/drop courses during the term. If you want to remove a course, deserialise it and use the following commands:

```PowerShell
# The following line removes all FUTURE occurrences of the course.
.\Unpublish-Appointments.ps1 -Target $course -OutlookFolder $folder

# The following line removes all occurences of the course.
.\Unpublish-Appointments.ps1 -Target $course -OutlookFolder $folder -IncludePast
```

You can set the `$term` as `Target` to remove week number appointments if you created the week numbers with wrong information.

If you are sure that you will take a course, and would like to remove the correlation identifiers, use `.\Unregister-AppointmentCorrelation.ps1`.

Note that even if you unpublish/unregister a term/course, the `CorrId` property in the object will not be automatically removed. This is by design and aims to prevent accidental loss of the identifier. A non-`null` `CorrId` prevents a term/course from being published. If you want to publish it again (for example if you are sure that appointments previously created for it have been deleted and you want to start over after modifying the object a bit), just set `CorrId` to `$null` to get going again.

## Notes on interactive editing and objects

### Term object

A term object consists of the following properties:

| Property | Description |
| :------- | :---------- |
| `Name` | The name of this term. |
| `Campus` | The campus for this term. |
| `Week1Monday` | The date of the Monday in week 1. This may not be the *first* Monday (there might be a week 0). |
| `MinWeek` | The lower bound of week numbers (inclusive). |
| `MaxWeek` | The upper bound of week numbers (inclusive). |
| `WeekBeginsOnMonday` | Whether a week begins on Monday. |
| `CorrId` | Optional. The correlation identifier. |

For all `n` between `MinWeek` and `MaxWeek`, an appointment with subject `<Name>: Week <n>` is created. All the appointments will have the same location (`Campus`) and is one-week long.

If you invoke `.\New-Term.ps1`, you will be able to interactively create a term object. You will be prompted for the properties in the order listed above (except for `CorrId`).

To create a term object without interaction, use the parameters. You should specify exactly one of `WeekBeginsOnMonday` and `WeekBeginsOnSunday`. If you supply neither, you will be asked for a choice interactively. If you supply both, a terminating error is thrown.

### Course object

A course object consists of the following properties:

| Property | Description |
| :------- | :---------- |
| `Subject` | The default title of this course. |
| `Location` | The default location for this course. |
| `Reminder` | The default number of minutes before each class when a reminder should appear. A negative value indicates no reminder should be created. |
| `Occurrences` | An array of recurring patterns (occurrence objects). |
| `CorrId` | Optional. The correlation identifier. |

An occurence object consists of the following properties:

| Property | Description |
| :------- | :---------- |
| `Weeks` | An array of integers, indicating the weeks in which this pattern produces an instance. |
| `Day` | The day of week (1 to 7 for Monday to Sunday) on which this pattern produces an instance. |
| `StartHour`/`StartMinute`/`EndHour`/`EndMinute` | The time slot for this pattern. |
| `OverrideSubject` | Optional. If present, overrides the default title. |
| `OverrideLocation` | Optional. If present, overrides the default location. |
| `OverrideReminder` | Optional. If present, overrides the default minutes for reminder. |

There are two approaches to managing a course. You could include sections/lab hours as occurrences of a course object. Or you could store them in another course object. In the former case, you mostly have to use `Override*` properties. It also makes sense to override the reminder if some occurrences are immediately after occurrences of another course. You can fine-tune the overridden reminder for different commuting situations.

If you invoke `.\New-Course.ps1`, you will be prompted to interactively create a course. A course will always be created interactively — at least the occurrence part. To avoid interaction, pre-create a course and distribute a serialised version (without `CorrId`). It is also possible to directly populate JSON.

The prompt will first ask for `Subject`, `Location` and `Reminder` (if they are missing in the parameters). Then, it enters a loop, allowing you to enter the occurrences. Each iteration begins by selecting the day of week. Choose “Cancel (X)” to finish the loop. If you choose any day, you will enter a new occurrence object. You can set the weeks using the “Page range” syntax in a print dialog. Week numbers can appear more than once and unordered, but they will always be sorted and deduplicated by the program. Use format similar to `09:50-14:20` for the time slot. Leave the input blank if you do not want to override the settings at course level.
