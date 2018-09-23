# NormaliseOutlookContacts

Used in conjunction with Outlook.com (Microsoft account, formerly Hotmail, Windows Live Mail and MSN Mail) and connection to Outlook (Windows Desktop) via Exchange protocol.

**IMPORTANT** Read the ‘Considerations’ section before using the script!

## Why

Because mobile contact editing sucks. Editing a contact on a mobile device (as well as editing it with People app for Windows) might cause the contact to have wrong full name or wrong file-as field, or to have thier e-mail display name ugly (bare e-mail address).

For example, if you create a contact named John Yuehan Smith (first name John, middle name Yuehan, last name Smith) from a mobile device, the resulting full name might be John Smith, instead of John Yuehan Smith. Furthermore, the file-as field might be empty (which is the case for People app) instead of (the default if in Outlook) Smith, John. If you add an e-mail address `text:someone@example.com` for him, the display name would be ‘someone@example.com’ instead of more polite and empathetic ‘John Yuehan Smith’, which would be the case if you used Outlook. If you have multiple e-mail addresses on file, Outlook will annotate them as ‘John Yuehan Smith (someone@example.com)’ and ‘John Yuehan Smith (sometwo@example.com)’.

Even better, you might want to annotate the e-mail addresses with their usages. For example, ‘Gee Law (Personal)’ for my Outlook.com address, and ‘Gee Law (Work - UCSB)’ for my current primarily affiliated institutional address, and ‘Gee Law (Other Work - UW)’ for my current secondarily affiliated institutional address.

## The scripts

`Repair-NameFields.ps1` will fix the file-as field and optionally the full name. You can supply Outlook Folder objects and/or Outlook Contact objects to `InputObject` (accepts pipeline input). If you do not supply any object, the script asks you to choose a folder interactively from Outlook. By default, the script does not fix full names. If you need to, supply `FixFullName` switch. Fixing full names can be time- and resource-consuming, because every contact will be touched and saved to regenerate the (correct) full name.

`Resolve-EmailAnnotation.ps1` resolves e-mail annotations with some heuristics. The optional `DomainDirectory` is a dictionary whose keys are domains and values are domain specification objects. A domain specification object consists of three properties, `Domain` (which will be the same as the key), `Type` a string among `Work`, `Personal`, `Other` and `code:` (the empty string), and `Name` an optional string. The directory is used to determine the name and type of an e-mail address, and subdomains override their ancestors. If `DomainDirectory` is omitted, it is gathered from the script directory (those `domain-*.csv` files). The parameters `(Personal/Work/Other)EmailAddress[Type]` (aliased as `Email(1/2/3)Address(Type)`) are optional and can receive value from pipeline by property name, which makes pipelining Contact objects to the script hassleless. Each pipeline input (or the only parameter input) produces a resolved annotation, suggesting appropriate annotations that are succinct and enough to distinct different addresses.

`Set-EmailDisplayName.ps1` sets the display names of e-mail address(es) when necessary and saves the update. It uses `Resolve-EmailAnnotation.ps1` as a subroutine. The script receives pipeline input as `InputObject`, which can be Folder or Contact objects. If no input object is supplied, the script prompts the user to select a folder from Outlook. The script also has a `DomainDirectory`, which works the same way as it does in `Resolve-EmailAnnotation.ps1`. Finally, there is an optional `DisplayNameComposer` parameter, which is a `ScriptBlock`. The script block receives an `args` array of length 2, the first element being a resolved annotation (`ByIndex.Email1` etc) and the second the contact object. The default composer creates the display name in the following way:

1. If the suggested annotation is the empty string, return the full name of the contact.
2. Otherwise, return `FullName (Annotation)`.

Therefore, it is a good practice to first repair name fields then normalises the display names.

## The CSVs

The CSVs supply default records for `DomainDirectory`. Branded domains as of 22 Sept 2018 and select ICANN/pre-ICANN TLDs are recorded. Outlook.com/Hotmail, Gmail and Foxmail are recognised as suitable for both personal and professional purposes (however, I do suggest putting an institutional address for work e-mail and leave them for the personal world). Other usual personal e-mail providers are recognised as personal e-mails. Note that the CSVs are there not only to classify the domains, but also to provide friendly names of the domains.

A subdomain with a type overrides the type of an ancestor, and so is the same for name.

You can contribute to this directory by adding proper records to the CSV files.

## Considerations

You should **NOT** use this program to annotate e-mail addresses in your corporate Exchange contact book. Most contacts in your corporate account will use Exchange Distinguished Name for e-mail address(es), which the scripts currently does not support.

For Outlook.com, accounts’ Exchange forests are separated, and the only Exchange Distinguished Name that can be resvoled by an account is the account itself.
