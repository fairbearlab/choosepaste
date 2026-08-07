package transforms

import (
	"html"
	"regexp"
	"strings"
)

var (
	tagRegexp        = regexp.MustCompile(`<[^>]*>`)
	whitespaceRegexp = regexp.MustCompile(`[ \t]+`)
	blankLineRegexp  = regexp.MustCompile(`\n{3,}`)
	brRegexp         = regexp.MustCompile(`<br\s*/?\s*>`)
	liRegexp         = regexp.MustCompile(`<li[^>]*>`)
)

// PlainText strips HTML/RTF markup and returns clean plain text.
// It decodes HTML entities, collapses whitespace, and normalizes line breaks.
func PlainText(input string, contentType string) (string, error) {
	text := input

	switch contentType {
	case "html":
		text = htmlToPlainText(text)
	case "rtf":
		// RTF should be pre-converted to HTML by the Swift side.
		// If we get raw RTF, strip control words as a fallback.
		text = stripRTF(text)
	default:
		// Plain text: just normalize whitespace
	}

	text = normalizeWhitespace(text)
	return text, nil
}

func htmlToPlainText(input string) string {
	// Replace block elements with newlines before stripping tags
	blockElements := []string{"</p>", "</div>", "</h1>", "</h2>", "</h3>",
		"</h4>", "</h5>", "</h6>", "</li>", "</tr>", "</blockquote>"}
	text := input
	for _, tag := range blockElements {
		text = strings.ReplaceAll(text, tag, "\n")
	}

	// <br> and <br/> to newline
	text = brRegexp.ReplaceAllString(text, "\n")

	// <li> gets a bullet
	text = liRegexp.ReplaceAllString(text, "• ")

	// Strip remaining tags
	text = tagRegexp.ReplaceAllString(text, "")

	// Decode HTML entities
	text = html.UnescapeString(text)

	return text
}

func stripRTF(input string) string {
	// Basic RTF stripping: remove control words and braces
	rtfControl := regexp.MustCompile(`\\[a-z]+\d*\s?`)
	text := rtfControl.ReplaceAllString(input, "")
	text = strings.ReplaceAll(text, "{", "")
	text = strings.ReplaceAll(text, "}", "")
	return text
}

func normalizeWhitespace(input string) string {
	// Collapse horizontal whitespace (spaces/tabs) within lines
	text := whitespaceRegexp.ReplaceAllString(input, " ")

	// Normalize line endings
	text = strings.ReplaceAll(text, "\r\n", "\n")
	text = strings.ReplaceAll(text, "\r", "\n")

	// Collapse 3+ consecutive newlines to 2
	text = blankLineRegexp.ReplaceAllString(text, "\n\n")

	// Trim leading/trailing whitespace from each line
	lines := strings.Split(text, "\n")
	for i, line := range lines {
		lines[i] = strings.TrimSpace(line)
	}
	text = strings.Join(lines, "\n")

	// Trim overall
	text = strings.TrimSpace(text)

	return text
}
