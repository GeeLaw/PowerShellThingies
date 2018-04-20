# New-Password

The cmdlet `New-Password` (with alias `newpwd`) creates a cryptographically safe password. By default it offers a password of length 16 with all the four categories of characters without similar characters and space character.

## Length

You can set the length of the desired output by supplying `[-Length] <int>`. The default is `16`. The length can be any number between `4` and `256` (inclusive).

## Random number generation algorithm

You can set a specific implementation of cryptographically safe random number generation algorithm by supplying `-RNGImplementation <string>` or `-RNGAlgorithm <string>`.

## Categories of characters

You can suppress any (but not all) of the four categories of characters by setting `-No<CategoryName>Characters` switch. The default is to includ all the four categories.

| `CategoryName` | Characters included |
| --- | --- |
| `UpperCase` | `ABCDEFGHIJKLMNOPQRSTUVWXYZ` |
| `LowerCase` | `abcdefghijklmnopqrstuvwxyz` |
| `Numeral` | `0123456789` |
| `Special` | <code>&#96;&#126;&#32;&#33;&#64;&#35;&#36;&#37;&#94;&#38;&#42;&#40;&#41;&#95;&#43;&#45;&#61;&#123;&#125;&#91;&#93;&#124;&#59;&#39;&#58;&#34;&#60;&#62;&#63;&#44;&#46;&#47;</code> (**note**: these include the space character) |

## Similar characters

Some groups of characters are visually similar except when rendered with a monospace font. They are:

- `1` (numeral), `l` (lower case Latin letter) and `I` (upper case Latin letter);
- `0` (numeral) and `O` (upper case Latin letter);
- <code>&#96;</code> (backtick), `'` (single quotation mark) and `"` (double quotation mark).

By default the cmdlet suppresses these characters from the generated password. You can disable this behaviour by setting `-AllowSimilarCharacters` switch.

## Space character

By default the cmdlet does not generate passwords containing the space character. You can disable this behaviour by setting `-AllowSpace` switch.

However, the generator will **never** generate a password with a leading or trailing space character.

## SecureString

The cmdlet returns a `string` by default. To get the password as a `System.Security.SecureString`, set `-UseSecureString` switch. Note that this is rarely helpful since one cannot know the password in the `SecureString` unless he decrypts it later with marshalling methods.

## The Elder

You can force the output to end with `+1s` by supplying `-Elder` switch. A more fashionable alias is `ls` so that the command line reads `New-Password -ls`. One second of your life is transferred to the Elder each time you use `-ls` as the switch name. The other alias is `o-o` and the command lines reads `New-Password -o-o`.
