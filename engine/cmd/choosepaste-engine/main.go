package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"

	"github.com/fairbearlab/choosepaste/engine/transforms"
)

type Request struct {
	Transform   string `json:"transform"`
	Content     string `json:"content"`
	ContentType string `json:"content_type"`
}

type Response struct {
	Result  string `json:"result"`
	Success bool   `json:"success"`
	Error   string `json:"error,omitempty"`
}

func main() {
	if len(os.Args) > 1 && os.Args[1] == "--list" {
		fmt.Println("plaintext, markdown")
		os.Exit(0)
	}

	input, err := io.ReadAll(os.Stdin)
	if err != nil {
		writeError("failed to read stdin: " + err.Error())
		os.Exit(1)
	}

	var req Request
	if err := json.Unmarshal(input, &req); err != nil {
		writeError("invalid JSON input: " + err.Error())
		os.Exit(1)
	}

	var result string

	switch req.Transform {
	case "plaintext":
		result, err = transforms.PlainText(req.Content, req.ContentType)
	case "markdown":
		result, err = transforms.Markdown(req.Content, req.ContentType)
	default:
		writeError("unknown transform: " + req.Transform)
		os.Exit(1)
	}

	if err != nil {
		writeError(err.Error())
		os.Exit(1)
	}

	writeSuccess(result)
}

func writeSuccess(result string) {
	resp := Response{Result: result, Success: true}
	data, _ := json.Marshal(resp)
	fmt.Println(string(data))
}

func writeError(msg string) {
	resp := Response{Success: false, Error: msg}
	data, _ := json.Marshal(resp)
	fmt.Println(string(data))
}
