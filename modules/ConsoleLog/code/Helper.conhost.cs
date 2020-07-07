using System;
using System.Collections.Generic;
using System.Globalization;
using System.Management.Automation.Host;
using System.Text;

namespace GeeLaw.ConsoleCapture
{
    /// <summary>
    /// Represents a captured console.
    /// </summary>
    public sealed class ConsoleLog
    {
        public ConsoleColor Foreground { get; private set; }
        public ConsoleColor Background { get; private set; }
        public int Width { get; private set; }
        public IReadOnlyList<Line> Lines { get; private set; }

        internal ConsoleLog(ConsoleColor fg, ConsoleColor bg,
            int w, IReadOnlyList<Line> lines)
        {
            Foreground = fg;
            Background = bg;
            Width = w;
            Lines = lines;
        }
    }

    /// <summary>
    /// Represents a line in the console.
    /// </summary>
    public sealed class Line
    {
        public ConsoleColor Foreground { get; private set; }
        public ConsoleColor Background { get; private set; }
        public IReadOnlyList<Span> Spans { get; private set; }

        internal Line(ConsoleColor fg, ConsoleColor bg, IReadOnlyList<Span> pending)
        {
            Foreground = fg;
            Background = bg;
            Spans = pending;
        }
    }

    /// <summary>
    /// Represents a block of text with formatting.
    /// </summary>
    public sealed class Span
    {
        public ConsoleColor Foreground { get; private set; }
        public ConsoleColor Background { get; private set; }
        /// <summary>
        /// The number of half-width characters this actually takes up.
        /// Each CJK character is counted as two half-width characters.
        /// This value could be different from Content.Length even if
        /// Content only consists of Latin characters, due to removal
        /// of trailing space characters.
        /// </summary>
        public int Width { get; private set; }
        public string Content { get; private set; }

        internal Span(ConsoleColor fg, ConsoleColor bg, int w, string content)
        {
            Foreground = fg;
            Background = bg;
            Width = w;
            Content = content;
        }
    }

    /// <summary>
    /// Specifies how trailing space should be handled.
    /// </summary>
    public enum TrailingSpaceBehavior
    {
        /// <summary>
        /// Keep all trailing space.
        /// </summary>
        KeepAll,
        /// <summary>
        /// Remove all trailing space.
        /// </summary>
        IgnoreAll,
        /// <summary>
        /// Remove all trailing space on the background of the line.
        /// For example, a non-formatted "1 " will be captured as "1".
        /// However, if we have a space on red followed by a space on
        /// blue, only the second space is removed (the line will have
        /// background blue).
        /// </summary>
        IgnoreDefaultColors
    }

    /// <summary>
    /// Provides capturing facilities.
    /// </summary>
    public sealed class Capturer
    {
        private sealed class PendingSpan
        {
            public int Width { get; set; }
            public string Content { get; set; }
            public string Trimmed { get; set; }
            public ConsoleColor Foreground { get; set; }
            public ConsoleColor Background { get; set; }

            public PendingSpan(int cjk, string content, string trimmed,
                ConsoleColor fg, ConsoleColor bg)
            {
                Width = cjk + content.Length;
                Content = content;
                Trimmed = trimmed;
                Foreground = fg;
                Background = bg;
            }

            public Span ToSpan()
            {
                return new Span(Foreground, Background, Width, Content);
            }
        }

        TrailingSpaceBehavior behavior;
        int width;
        ConsoleColor fgDefault, bgDefault;
        ConsoleColor fgCurrent, bgCurrent;
        int space, cjk;
        StringBuilder sb;
        List<PendingSpan> pending;

        private Capturer(TrailingSpaceBehavior tsb, int w, ConsoleColor fg, ConsoleColor bg)
        {
            behavior = tsb;
            width = w;
            fgDefault = fg;
            bgDefault = bg;
            fgCurrent = fg;
            bgCurrent = bg;
            space = 0;
            cjk = 0;
            sb = new StringBuilder(width + 1);
            pending = new List<PendingSpan>(width + 1);
        }

        private void CompleteCurrentSpan()
        {
            string trimmed = sb.ToString();
            sb.Append(' ', space);
            string content = sb.ToString();
            if (content.Length != 0)
            {
                pending.Add(new PendingSpan(cjk, content, trimmed,
                    fgCurrent, bgCurrent));
            }
            space = 0;
            cjk = 0;
            sb.Clear();
            fgCurrent = fgDefault;
            bgCurrent = bgDefault;
        }

        private void AddCharacter(char ch, ConsoleColor fg, ConsoleColor bg)
        {
            if (fg != fgCurrent || bg != bgCurrent)
            {
                CompleteCurrentSpan();
                fgCurrent = fg;
                bgCurrent = bg;
            }
            if (ch == ' ' || ch == '\0')
            {
                if (ch == '\0') { sb.Append("?"); --space; }
                ++space;
                return;
            }
            sb.Append(' ', space).Append(ch);
            space = 0;
        }

        private void AddCJK() { ++cjk; }

        private void RemoveTrailingSpaceAll()
        {
            List<PendingSpan> pss = pending;
            for (int i = pss.Count - 1; i != -1; --i)
            {
                PendingSpan sp = pss[i];
                if ((sp.Content = sp.Trimmed).Length == 0)
                {
                    pss.RemoveAt(i);
                }
                else
                {
                    break;
                }
            }
        }

        private void RemoveTrailingSpaceDefaultColors(ConsoleColor bg)
        {
            List<PendingSpan> pss = pending;
            for (int i = pss.Count - 1; i != -1; --i)
            {
                PendingSpan sp = pss[i];
                if (sp.Background == bg && (sp.Content = sp.Trimmed).Length == 0)
                {
                    pss.RemoveAt(i);
                }
                else
                {
                    break;
                }
            }
        }

        private void RemoveTrailingSpace(ConsoleColor bg)
        {
            if (behavior == TrailingSpaceBehavior.IgnoreAll)
            {
                RemoveTrailingSpaceAll();
            }
            else if (behavior == TrailingSpaceBehavior.IgnoreDefaultColors)
            {
                RemoveTrailingSpaceDefaultColors(bg);
            }
        }

        /// <summary>
        /// Determines the coloring scheme of this line.
        /// </summary>
        /// <param name="fg">The default foreground for this line.</param>
        /// <param name="bg">The default background for this line.</param>
        private void ResolveLineColors(out ConsoleColor fg, out ConsoleColor bg)
        {
            /* Try the last cell for the line. */
            List<PendingSpan> pss = pending;
            int i = pss.Count - 1;
            PendingSpan last = pss[i];
            fg = fgDefault;
            bg = last.Background;
            /* If the last cell is space, this background is used. */
            if (last.Trimmed.Length < last.Content.Length)
            {
                /* Prefer the last content-ful foreground color on this background. */
                for (; i != -1; --i)
                {
                    last = pss[i];
                    if (last.Background == bg && last.Trimmed.Length != 0)
                    {
                        fg = last.Foreground;
                        return;
                    }
                }
                /* No other spans use the same background and
                ** default foreground does not matter. */
                fg = fgDefault;
                return;
            }
            /* The last cell is not a space. Use this background
            ** if it occupies at least 1/3 of this line. */
            int count = 0;
            for (; i != -1; --i)
            {
                last = pss[i];
                count += (last.Background == bg ? -last.Width : (last.Width >> 1));
            }
            /* This background should not be used since it occupies < 1/3. */
            if (count > 0)
            {
                bg = bgDefault;
                return;
            }
            /* Prefer the last content-ful foreground color. */
            for (i = pss.Count - 1; i != -1; --i)
            {
                last = pss[i];
                if (last.Background == bg && last.Trimmed.Length != 0)
                {
                    fg = last.Foreground;
                    return;
                }
            }
        }

        private static readonly IReadOnlyList<Span> EmptySpanList = (new List<Span>()).AsReadOnly();
        private static readonly IReadOnlyList<Line> EmptyLineList = (new List<Line>()).AsReadOnly();

        private static IEnumerable<object> StreamCaptureImpl(TrailingSpaceBehavior behavior,
            BufferCell[,] cells,
            ConsoleColor fg, ConsoleColor bg,
            int width, int y,
            bool populate)
        {
            List<Line> lines = populate ? new List<Line>(y) : null;
            Capturer automaton = new Capturer(behavior, width, fg, bg);
            List<PendingSpan> pending = automaton.pending;
            yield return new ConsoleLog(fg, bg, width,
                populate ? lines.AsReadOnly() : EmptyLineList);
            for (int line = 0; line != y; ++line)
            {
                for (int column = 0; column != width; ++column)
                {
                    BufferCell target = cells[line, column];
                    char ch = target.Character;
                    if (target.BufferCellType == BufferCellType.Complete || ch != '\0')
                    {
                        automaton.AddCharacter(ch,
                            target.ForegroundColor, target.BackgroundColor);
                    }
                    else
                    {
                        automaton.AddCJK();
                    }
                }
                automaton.CompleteCurrentSpan();
                Line ln;
                /* This should not happen, but just being safe. */
                if (pending.Count == 0)
                {
                    ln = new Line(fg, bg, EmptySpanList);
                    if (populate)
                    {
                        lines.Add(ln);
                    }
                    yield return ln;
                    yield return null;
                    continue;
                }
                ConsoleColor fgLine, bgLine;
                automaton.ResolveLineColors(out fgLine, out bgLine);
                automaton.RemoveTrailingSpace(bgLine);
                List<Span> spans = populate ? new List<Span>(pending.Count) : null;
                ln = new Line(fgLine, bgLine, populate ? spans.AsReadOnly() : EmptySpanList);
                if (populate)
                {
                    lines.Add(ln);
                }
                yield return ln;
                foreach (PendingSpan sp in pending)
                {
                    if (sp.Trimmed.Length == 0)
                    {
                        sp.Foreground = fgLine;
                    }
                    Span span = sp.ToSpan();
                    if (populate)
                    {
                        spans.Add(span);
                    }
                    yield return span;
                }
                yield return null;
                pending.Clear();
            }
        }

        /// <summary>
        /// Enumerates the objects in the captured console in a stream fashion.
        /// The enumeration order is as follows:
        /// 1. ConsoleLog object.
        /// 2. For each line:
        ///    a. Line object.
        ///    b. Each Span object.
        ///    c. A null.
        /// The null is used to indicate termination of a line.
        /// Note that when ConsoleLog/Line objects are first enumerated,
        /// their children Line/Span objects are not yet ready. Enumeration
        /// must proceed for the tree structure to be completed.
        /// When "populate" is set to $False, this method is GC-efficient in
        /// that if you discard an object after receiving it, the object
        /// immediately becomes eligible for garbage collection.
        /// The effect is that the tree structure is never populated.
        /// </summary>
        /// <param name="host">$Host from PowerShell.</param>
        /// <param name="includeCurrentLine">Whether the current line should be included.
        /// This can be set to $False if the command is used interactively.</param>
        /// <param name="behavior">Behavior of trailing space characters.</param>
        /// <param name="populate">Whether the tree structure is populated.</param>
        /// <returns>Enumerated objects.</returns>
        public static IEnumerable<object> StreamCapture(PSHost host,
            bool includeCurrentLine,
            TrailingSpaceBehavior behavior,
            bool populate)
        {
            if (host.Name != "ConsoleHost")
            {
                throw new NotSupportedException("This method only supports the console host.");
            }
            if ((int)behavior < 0 || (int)behavior > 2)
            {
                throw new ArgumentOutOfRangeException("behavior");
            }
            PSHostRawUserInterface ui = host.UI.RawUI;
            int width = ui.BufferSize.Width;
            int y = ui.CursorPosition.Y + (includeCurrentLine ? 1 : 0);
            if (width < 1)
            {
                throw new ArgumentOutOfRangeException("host.UI.RawUI.BufferSize.Width");
            }
            if (y < 1)
            {
                throw new ArgumentOutOfRangeException("host.UI.RawUI.CursorPosition.Y");
            }
            return StreamCaptureImpl(behavior,
                ui.GetBufferContents(new Rectangle(0, 0, width - 1, y - 1)),
                ui.ForegroundColor, ui.BackgroundColor, width, y, populate);
        }

        /// <summary>
        /// Captures the console as a ConsoleLog object.
        /// </summary>
        public static ConsoleLog Capture(PSHost host,
            bool includeCurrentLine,
            TrailingSpaceBehavior behavior)
        {
            ConsoleLog result = null;
            foreach (object obj in StreamCapture(host, includeCurrentLine, behavior, true))
            {
                if (obj is ConsoleLog)
                {
                    result = (ConsoleLog)obj;
                }
                /* Continue enumeration to populate the structure. */
            }
            return result;
        }
    }

    public static class TextCapturer
    {
        public static IEnumerable<string> Capture(PSHost host,
            bool includeCurrentLine,
            TrailingSpaceBehavior behavior)
        {
            StringBuilder sb = new StringBuilder();
            foreach (object obj in Capturer.StreamCapture(host, includeCurrentLine, behavior, false))
            {
                if (ReferenceEquals(obj, null))
                {
                    yield return sb.ToString();
                    sb.Clear();
                }
                Span span = obj as Span;
                if (!ReferenceEquals(span, null))
                {
                    sb.Append(span.Content);
                }
            }
        }
    }

    public static class HtmlCapturer
    {
        /// <summary>
        /// Enumerates the substrings of HTML-formatted ConsoleLog.
        /// </summary>
        /// <param name="host">$Host from PowerShell.</param>
        /// <param name="includeCurrentLine">Whether the current line should be included.
        /// This can be set to $False if the command is used interactively.</param>
        /// <param name="behavior">Behavior of trailing space characters.</param>
        public static IEnumerable<string> StreamCapture(PSHost host,
            bool includeCurrentLine,
            TrailingSpaceBehavior behavior)
        {
            ConsoleColor fgDefault = ConsoleColor.White, bgDefault = ConsoleColor.Black;
            ConsoleColor fgLine = ConsoleColor.White, bgLine = ConsoleColor.Black;
            ConsoleColor fg = ConsoleColor.White, bg = ConsoleColor.Black;
            bool emptyLine = true;
            /* The loop directly walks the tree, so we do not need
            ** the tree to be stored in the returned objects.
            ** Setting "populate" to $False make it GC-efficient. */
            foreach (object obj in Capturer.StreamCapture(host, includeCurrentLine, behavior, false))
            {
                ConsoleLog console = obj as ConsoleLog;
                if (!ReferenceEquals(console, null))
                {
                    yield return "<pre class=\"gl-console gl-console-fg-";
                    yield return Helper.ColorToName(fgDefault = console.Foreground);
                    yield return " gl-console-bg-";
                    yield return Helper.ColorToName(bgLine = bgDefault = console.Background);
                    yield return "\" data-width=\"";
                    yield return console.Width.ToString(CultureInfo.InvariantCulture);
                    yield return "\">\n";
                    continue;
                }
                Line line = obj as Line;
                if (!ReferenceEquals(line, null))
                {
                    yield return "<code class=\"gl-console-line";
                    if ((fgLine = line.Foreground) != fgDefault)
                    {
                        yield return " gl-console-fg-";
                        yield return Helper.ColorToName(fgLine);
                    }
                    yield return " gl-console-bg-";
                    ConsoleColor bgLine2 = line.Background;
                    if (bgLine != bgLine2)
                    {
                        yield return "change gl-console-bg-";
                    }
                    yield return ((bgLine = bgLine2) != bgDefault
                        ? Helper.ColorToName(bgLine2) : "none");
                    yield return "\">";
                    emptyLine = true;
                    continue;
                }
                Span span = obj as Span;
                if (!ReferenceEquals(span, null))
                {
                    emptyLine = false;
                    fg = span.Foreground;
                    bg = span.Background;
                    if (fg == fgLine && bg == bgLine)
                    {
                        yield return "<span>";
                        yield return Helper.HtmlEncode(span.Content);
                        yield return "</span>";
                    }
                    else if (fg == fgLine && bg != bgLine)
                    {
                        yield return "<span class=\"gl-console-bg-";
                        yield return Helper.ColorToName(bg);
                        yield return "\">";
                        yield return Helper.HtmlEncode(span.Content);
                        yield return "</span>";
                    }
                    else if (fg != fgLine && bg == bgLine)
                    {
                        yield return "<span class=\"gl-console-fg-";
                        yield return Helper.ColorToName(fg);
                        yield return "\">";
                        yield return Helper.HtmlEncode(span.Content);
                        yield return "</span>";
                    }
                    else
                    {
                        yield return "<span class=\"gl-console-fg-";
                        yield return Helper.ColorToName(fg);
                        yield return " gl-console-bg-";
                        yield return Helper.ColorToName(bg);
                        yield return "\">";
                        yield return Helper.HtmlEncode(span.Content);
                        yield return "</span>";
                    }
                    continue;
                }
                /* A line has ended. */
                yield return (emptyLine ? "<span> </span></code>\n" : "</code>\n");
            }
            yield return "</pre>";
        }

        /// <summary>
        /// Captures the console as a string.
        /// </summary>
        public static string Capture(PSHost host,
            bool includeCurrentLine,
            TrailingSpaceBehavior behavior)
        {
            return string.Concat(StreamCapture(host, includeCurrentLine, behavior));
        }
    }

    public static class Helper
    {
        public static string StylesPath { get; set; }
        public static string StylesContent { get; set; }
        public static string InteractiveStylesPath { get; set; }

        internal static string ColorToName(ConsoleColor color)
        {
            switch (color)
            {
                case ConsoleColor.Black: return "black";
                case ConsoleColor.DarkBlue: return "darkblue";
                case ConsoleColor.DarkGreen: return "darkgreen";
                case ConsoleColor.DarkCyan: return "darkcyan";
                case ConsoleColor.DarkRed: return "darkred";
                case ConsoleColor.DarkMagenta: return "darkmagenta";
                case ConsoleColor.DarkYellow: return "darkyellow";
                case ConsoleColor.Gray: return "gray";
                case ConsoleColor.DarkGray: return "darkgray";
                case ConsoleColor.Blue: return "blue";
                case ConsoleColor.Green: return "green";
                case ConsoleColor.Cyan: return "cyan";
                case ConsoleColor.Red: return "red";
                case ConsoleColor.Magenta: return "magenta";
                case ConsoleColor.Yellow: return "yellow";
                case ConsoleColor.White: return "white";
            }
            throw new ArgumentOutOfRangeException("color");
        }

        internal static string ColorToFriendlyName(ConsoleColor color)
        {
            switch (color)
            {
                case ConsoleColor.Black: return "black";
                case ConsoleColor.DarkBlue: return "dark blue";
                case ConsoleColor.DarkGreen: return "dark green";
                case ConsoleColor.DarkCyan: return "dark cyan";
                case ConsoleColor.DarkRed: return "dark red";
                case ConsoleColor.DarkMagenta: return "dark magenta";
                case ConsoleColor.DarkYellow: return "dark yellow";
                case ConsoleColor.Gray: return "gray";
                case ConsoleColor.DarkGray: return "dark gray";
                case ConsoleColor.Blue: return "blue";
                case ConsoleColor.Green: return "green";
                case ConsoleColor.Cyan: return "cyan";
                case ConsoleColor.Red: return "red";
                case ConsoleColor.Magenta: return "magenta";
                case ConsoleColor.Yellow: return "yellow";
                case ConsoleColor.White: return "white";
            }
            throw new ArgumentOutOfRangeException("color");
        }

        internal static string HtmlEncode(string content)
        {
            return content.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
                .Replace("\"", "&#34;").Replace("'", "&#39;");
        }

        private static IEnumerable<string> GetInteractiveHtmlImpl(IEnumerable<object> vs)
        {
            yield return "<!doctype html>\n<html><head>\n<meta charset=\"utf-8\" />\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n<title>Console Log Inspector (Show-ConsoleLog)</title>\n<link href=\"file:///";
            yield return HtmlEncode(InteractiveStylesPath.Replace("\\", "/"));
            yield return "\" rel=\"stylesheet\" />\n</head><body>\n";
            int ctr = 0;
            string[] spaces = null;
            bool emptyConsole = true;
            bool emptyLine = true;
            foreach (object obj in vs)
            {
                ConsoleLog consoleLog = obj as ConsoleLog;
                if (!ReferenceEquals(consoleLog, null))
                {
                    yield return "<div class=\"container console\" role=\"main\" aria-label=\"Console Log Inspector\"><input type=\"checkbox\" id=\"ctrl";
                    yield return ctr.ToString(CultureInfo.InvariantCulture);
                    yield return "\" checked=\"checked\" /><label for=\"ctrl";
                    yield return ctr.ToString(CultureInfo.InvariantCulture);
                    yield return "\" role=\"heading\" aria-level=\"1\" aria-label=\"ConsoleLog object, width ";
                    string width = consoleLog.Width.ToString(CultureInfo.InvariantCulture);
                    spaces = new string[width.Length];
                    for (int i = 0; i != width.Length; ++i)
                    {
                        spaces[i] = new string(' ', i);
                    }
                    yield return width;
                    yield return ", see checkbox before this heading for expansion collapsion state, press Space to toggle\"><span class=\"color fg-";
                    yield return ColorToName(consoleLog.Foreground);
                    yield return " bg-";
                    yield return ColorToName(consoleLog.Background);
                    yield return "\">ConsoleLog</span> object (width = ";
                    yield return width;
                    yield return ")</label><div class=\"content\">\n";
                    ++ctr;
                    continue;
                }
                Line line = obj as Line;
                if (!ReferenceEquals(line, null))
                {
                    yield return "<div class=\"container line\"><input type=\"checkbox\" id=\"ctrl";
                    yield return ctr.ToString(CultureInfo.InvariantCulture);
                    yield return "\" checked=\"checked\" /><label for=\"ctrl";
                    yield return ctr.ToString(CultureInfo.InvariantCulture);
                    yield return "\" role=\"heading\" aria-level=\"2\" aria-label=\"Line object, see checkbox before this heading for expansion collapsion state, press Space to toggle\"><span class=\"color fg-";
                    yield return ColorToName(line.Foreground);
                    yield return " bg-";
                    yield return ColorToName(line.Background);
                    yield return "\">Line</span> object</label><div class=\"content\">\n";
                    emptyConsole = false;
                    emptyLine = true;
                    ++ctr;
                    continue;
                }
                Span span = obj as Span;
                if (!ReferenceEquals(span, null))
                {
                    yield return "<div class=\"span\">Span (width = ";
                    string width = span.Width.ToString(CultureInfo.InvariantCulture);
                    if (width.Length < spaces.Length)
                    {
                        yield return spaces[spaces.Length - width.Length];
                    }
                    yield return width;
                    yield return "): <span class=\"color fg-";
                    yield return ColorToName(span.Foreground);
                    yield return " bg-";
                    yield return ColorToName(span.Background);
                    yield return "\" role=\"img\" aria-label=\"foreground color ";
                    yield return ColorToFriendlyName(span.Foreground);
                    yield return ", background color ";
                    yield return ColorToFriendlyName(span.Background);
                    yield return ", content: ";
                    string htmlContent = HtmlEncode(span.Content);
                    yield return htmlContent;
                    yield return "\">";
                    yield return htmlContent;
                    yield return "</span></div>\n";
                    emptyLine = false;
                    continue;
                }
                yield return (emptyLine ? "<div class=\"none\">(no Span subobject)</div></div></div>\n" : "</div></div>\n");
            }
            yield return (emptyConsole
                ? "<div class=\"none\">(no Line subobject)</div></div>\n</body></html>\n"
                : "</div></div>\n</body></html>\n");
        }

        public static string GetInteractiveHtml(PSHost host,
            bool includeCurrentLine, TrailingSpaceBehavior behavior)
        {
            return string.Concat(GetInteractiveHtmlImpl(
                Capturer.StreamCapture(host, includeCurrentLine, behavior, false)));
        }
    }
}
