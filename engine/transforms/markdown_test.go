package transforms

import (
	"flag"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// update regenerates the golden .md fixture files from the current output of
// the HTML-to-Markdown converter. Run with:
//
//	go test ./transforms/... -run TestMarkdown_Fixtures -update
var update = flag.Bool("update", false, "update golden fixture files (testdata/fixtures/*.md) with current converter output")

// normalizeBlankLines strips trailing whitespace from each line.
// This avoids false negatives when linters strip trailing spaces
// from fixture files but the converter preserves indentation on blank lines.
var trailingWS = regexp.MustCompile(`(?m)[ \t]+$`)

func normalizeTrailingWS(s string) string {
	return trailingWS.ReplaceAllString(strings.TrimSpace(s), "")
}

func TestMarkdown_BasicHTML(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "heading and paragraph",
			input:    "<h1>Title</h1><p>Some text here.</p>",
			expected: "# Title\n\nSome text here.",
		},
		{
			name:     "bold and italic",
			input:    "<p><strong>Bold</strong> and <em>italic</em></p>",
			expected: "**Bold** and *italic*",
		},
		{
			name:     "unordered list",
			input:    "<ul><li>First</li><li>Second</li><li>Third</li></ul>",
			expected: "- First\n- Second\n- Third",
		},
		{
			name:     "ordered list",
			input:    "<ol><li>First</li><li>Second</li><li>Third</li></ol>",
			expected: "1. First\n2. Second\n3. Third",
		},
		{
			name:     "link",
			input:    `<p>Visit <a href="https://example.com">Example</a></p>`,
			expected: "Visit [Example](https://example.com)",
		},
		{
			name:     "code inline",
			input:    "<p>Use <code>fmt.Println</code> to print</p>",
			expected: "Use `fmt.Println` to print",
		},
		{
			name:     "code block",
			input:    "<pre><code>func main() {\n    fmt.Println(\"hello\")\n}</code></pre>",
			expected: "```\nfunc main() {\n    fmt.Println(\"hello\")\n}\n```",
		},
		{
			name:     "blockquote",
			input:    "<blockquote><p>A wise quote</p></blockquote>",
			expected: "> A wise quote",
		},
		{
			name:     "plain text passthrough",
			input:    "Just plain text, no HTML.",
			expected: "Just plain text, no HTML.",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := Markdown(tt.input, "html")
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != tt.expected {
				t.Errorf("\ngot:      %q\nexpected: %q", got, tt.expected)
			}
		})
	}
}

func TestMarkdown_RTFFallback(t *testing.T) {
	// RTF input falls back to PlainText stripping
	input := `{\rtf1\ansi\deff0 Hello world}`
	got, err := Markdown(input, "rtf")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	expected := "Hello world"
	if got != expected {
		t.Errorf("\ngot:      %q\nexpected: %q", got, expected)
	}
}

// TestMarkdown_Fixtures runs against real-world HTML samples in testdata/fixtures/.
// Each fixture has a .html input and .md expected output.
func TestMarkdown_Fixtures(t *testing.T) {
	fixturesDir := filepath.Join("..", "testdata", "fixtures")

	htmlFiles, err := filepath.Glob(filepath.Join(fixturesDir, "*.html"))
	if err != nil {
		t.Fatalf("failed to glob fixtures: %v", err)
	}

	if len(htmlFiles) == 0 {
		t.Skip("no fixture files found in testdata/fixtures/")
	}

	for _, htmlFile := range htmlFiles {
		name := strings.TrimSuffix(filepath.Base(htmlFile), ".html")
		mdFile := filepath.Join(fixturesDir, name+".md")

		t.Run(name, func(t *testing.T) {
			htmlBytes, err := os.ReadFile(filepath.Clean(htmlFile))
			if err != nil {
				t.Fatalf("failed to read %s: %v", htmlFile, err)
			}

			got, err := Markdown(string(htmlBytes), "html")
			if err != nil {
				t.Fatalf("transform error: %v", err)
			}
			gotNorm := normalizeTrailingWS(got)

			if *update {
				// Use OpenFile+Write rather than os.WriteFile: gosec's G703
				// taint analysis flags a variable path passed straight to
				// os.WriteFile even after filepath.Clean(); the equivalent
				// OpenFile call with an explicit O_CREATE|O_TRUNC is the
				// established fix for this rule elsewhere in fairbearlab Go
				// repos (see rolodex's copyFile helper).
				f, err := os.OpenFile(filepath.Clean(mdFile), os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0o600)
				if err != nil {
					t.Fatalf("failed to open %s for update: %v", mdFile, err)
				}
				if _, err := f.WriteString(gotNorm + "\n"); err != nil {
					_ = f.Close()
					t.Fatalf("failed to write %s: %v", mdFile, err)
				}
				if err := f.Close(); err != nil {
					t.Fatalf("failed to close %s: %v", mdFile, err)
				}
				return
			}

			expectedBytes, err := os.ReadFile(filepath.Clean(mdFile))
			if err != nil {
				t.Fatalf("failed to read %s: %v (run with -update to create it)", mdFile, err)
			}

			expected := normalizeTrailingWS(string(expectedBytes))
			if gotNorm != expected {
				t.Errorf("fixture %s mismatch:\n--- got ---\n%s\n--- expected ---\n%s", name, gotNorm, expected)
			}
		})
	}
}
