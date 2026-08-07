package transforms

import (
	"testing"
)

func TestPlainText_HTML(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "simple paragraph",
			input:    "<p>Hello world</p>",
			expected: "Hello world",
		},
		{
			name:     "bold and italic",
			input:    "<b>Bold</b> and <i>italic</i>",
			expected: "Bold and italic",
		},
		{
			name:     "headings",
			input:    "<h1>Title</h1><p>Content here</p>",
			expected: "Title\nContent here",
		},
		{
			name:     "unordered list",
			input:    "<ul><li>First</li><li>Second</li><li>Third</li></ul>",
			expected: "• First\n• Second\n• Third",
		},
		{
			name:     "line breaks",
			input:    "Line one<br>Line two<br/>Line three",
			expected: "Line one\nLine two\nLine three",
		},
		{
			name:     "html entities",
			input:    "5 &gt; 3 &amp; 2 &lt; 4",
			expected: "5 > 3 & 2 < 4",
		},
		{
			name:     "nested tags",
			input:    "<div><p>Inside a <strong>nested</strong> structure</p></div>",
			expected: "Inside a nested structure",
		},
		{
			name:     "whitespace collapse",
			input:    "<p>  lots   of   spaces  </p>",
			expected: "lots of spaces",
		},
		{
			name:     "empty input",
			input:    "",
			expected: "",
		},
		{
			name:     "links stripped to text",
			input:    `<a href="https://example.com">Click here</a>`,
			expected: "Click here",
		},
		{
			name:     "code blocks",
			input:    "<pre><code>func main() {\n    fmt.Println(\"hello\")\n}</code></pre>",
			expected: "func main() {\nfmt.Println(\"hello\")\n}",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := PlainText(tt.input, "html")
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != tt.expected {
				t.Errorf("\ngot:      %q\nexpected: %q", got, tt.expected)
			}
		})
	}
}

func TestPlainText_RTF(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "basic RTF control words",
			input:    `{\rtf1\ansi\deff0 Hello world}`,
			expected: "Hello world",
		},
		{
			name:     "RTF with font info",
			input:    `{\rtf1\ansi{\fonttbl{\f0 Helvetica;}}Some styled text}`,
			expected: "Helvetica;Some styled text", // fonttbl content leaks; real RTF is pre-converted to HTML by Swift
		},
		{
			name:     "RTF with numbered control",
			input:    `{\rtf1\fs24\b Bold text\b0  normal}`,
			expected: "Bold text normal",
		},
		{
			name:     "empty RTF",
			input:    `{\rtf1}`,
			expected: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := PlainText(tt.input, "rtf")
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != tt.expected {
				t.Errorf("\ngot:      %q\nexpected: %q", got, tt.expected)
			}
		})
	}
}

func TestPlainText_PlainText(t *testing.T) {
	input := "  Hello   world  \n\n\n\n  Next line  "
	expected := "Hello world\n\nNext line"
	got, err := PlainText(input, "text")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != expected {
		t.Errorf("\ngot:      %q\nexpected: %q", got, expected)
	}
}
