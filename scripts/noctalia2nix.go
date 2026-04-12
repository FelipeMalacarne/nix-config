package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"sort"
	"strconv"
	"strings"
)

func indent(level int) string {
	return strings.Repeat("  ", level)
}

func formatNumber(n json.Number) string {
	if i, err := n.Int64(); err == nil {
		return strconv.FormatInt(i, 10)
	}
	if f, err := n.Float64(); err == nil {
		return strconv.FormatFloat(f, 'f', -1, 64)
	}
	return n.String()
}

func toNix(v any, level int) string {
	switch x := v.(type) {
	case nil:
		return "null"
	case bool:
		if x {
			return "true"
		}
		return "false"
	case json.Number:
		return formatNumber(x)
	case float64:
		if x == float64(int64(x)) {
			return strconv.FormatInt(int64(x), 10)
		}
		return strconv.FormatFloat(x, 'f', -1, 64)
	case string:
		return strconv.Quote(x)
	case []any:
		if len(x) == 0 {
			return "[ ]"
		}

		var b strings.Builder
		b.WriteString("[\n")
		for _, item := range x {
			b.WriteString(indent(level + 1))
			b.WriteString(toNix(item, level+1))
			b.WriteString("\n")
		}
		b.WriteString(indent(level))
		b.WriteString("]")
		return b.String()
	case map[string]any:
		if len(x) == 0 {
			return "{ }"
		}

		keys := make([]string, 0, len(x))
		for key := range x {
			keys = append(keys, key)
		}
		sort.Strings(keys)

		var b strings.Builder
		b.WriteString("{\n")
		for _, key := range keys {
			b.WriteString(indent(level + 1))
			b.WriteString(strconv.Quote(key))
			b.WriteString(" = ")
			b.WriteString(toNix(x[key], level+1))
			b.WriteString(";\n")
		}
		b.WriteString(indent(level))
		b.WriteString("}")
		return b.String()
	default:
		panic(fmt.Sprintf("unsupported JSON type: %T", v))
	}
}

func readJSONFile(path string) ([]byte, error) {
	return os.ReadFile(path)
}

func runShellOutput(cmd string) ([]byte, error) {
	out, err := exec.Command("sh", "-c", cmd).Output()
	if err != nil {
		return nil, fmt.Errorf("command failed (%s): %w", cmd, err)
	}
	return out, nil
}

func main() {
	inputPath := flag.String("input", "", "path to noctalia JSON file")
	fromIPC := flag.Bool("ipc", false, "read settings from running Noctalia instance via IPC")
	ipcCmd := flag.String("ipc-cmd", "noctalia-shell ipc call state all", "IPC command that prints JSON")
	flag.Parse()

	modeCount := 0
	if *inputPath != "" {
		modeCount++
	}
	if *fromIPC {
		modeCount++
	}

	if modeCount != 1 {
		fmt.Fprintln(os.Stderr, "usage:")
		fmt.Fprintln(os.Stderr, "  go run ./scripts/noctalia2nix.go -input ./noctalia.json")
		fmt.Fprintln(os.Stderr, "  go run ./scripts/noctalia2nix.go -ipc")
		fmt.Fprintln(os.Stderr, "  go run ./scripts/noctalia2nix.go -ipc -ipc-cmd 'noctalia-shell ipc call state all'")
		os.Exit(2)
	}

	var (
		raw []byte
		err error
	)

	if *fromIPC {
		raw, err = runShellOutput(*ipcCmd)
		if err != nil {
			fmt.Fprintf(os.Stderr, "read ipc: %v\n", err)
			os.Exit(1)
		}
	} else {
		raw, err = readJSONFile(*inputPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "read input: %v\n", err)
			os.Exit(1)
		}
	}

	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.UseNumber()

	var value any
	if err := dec.Decode(&value); err != nil {
		fmt.Fprintf(os.Stderr, "decode json: %v\n", err)
		os.Exit(1)
	}

	if *fromIPC {
		if root, ok := value.(map[string]any); ok {
			if settings, hasSettings := root["settings"]; hasSettings {
				value = settings
			}
		}
	}

	fmt.Printf("settings = %s;\n", toNix(value, 0))
}
