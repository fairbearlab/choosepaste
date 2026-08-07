package transforms

import (
	"strings"

	"github.com/JohannesKaufmann/html-to-markdown/v2/converter"
	"github.com/JohannesKaufmann/html-to-markdown/v2/plugin/base"
	"github.com/JohannesKaufmann/html-to-markdown/v2/plugin/commonmark"
	"github.com/JohannesKaufmann/html-to-markdown/v2/plugin/table"
)

// Markdown converts HTML content to clean Markdown.
func Markdown(input string, contentType string) (string, error) {
	switch contentType {
	case "html":
		return htmlToMarkdown(input)
	case "rtf":
		// RTF should be pre-converted to HTML by the Swift side.
		// If raw RTF arrives, strip to plain text as fallback.
		text, err := PlainText(input, "rtf")
		if err != nil {
			return "", err
		}
		return text, nil
	default:
		// Plain text input: return as-is (already valid Markdown)
		return strings.TrimSpace(input), nil
	}
}

func htmlToMarkdown(input string) (string, error) {
	conv := converter.NewConverter(
		converter.WithPlugins(
			base.NewBasePlugin(),
			commonmark.NewCommonmarkPlugin(),
			table.NewTablePlugin(),
		),
	)

	md, err := conv.ConvertString(input)
	if err != nil {
		return "", err
	}

	md = strings.TrimSpace(md)
	return md, nil
}
