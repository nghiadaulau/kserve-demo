#!/usr/bin/env bash
set -euo pipefail

# ==========================
# Usage:
# ./test_llm.sh <URL> <MODEL_NAME> "<PROMPT>"
#
# Example:
# ./test_llm.sh \
#   http://ab5f3bf10e2124a268d9619e4eea7524-486888111.ap-southeast-1.elb.amazonaws.com/llm-demo/model-phi-mini-4k-instruct-single-workload/v1/completions \
#   microsoft/Phi-3-mini-4k-instruct \
#   "Who you are?"
# ==========================

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <URL> <MODEL_NAME> \"<PROMPT>\""
  exit 1
fi

URL="$1/v1/completions"
MODEL="$2"
PROMPT="$3"

MAX_TOKENS="${MAX_TOKENS:-64}"
TEMPERATURE="${TEMPERATURE:-0.7}"

echo "=== Sending request ==="
echo "URL        : $URL"
echo "Model      : $MODEL"
echo "Prompt     : $PROMPT"
echo "Max tokens : $MAX_TOKENS"
echo "Temperature: $TEMPERATURE"
echo "======================="

RESP=$(curl --location "$URL" \
  --header 'Accept: text/event-stream' \
  --header 'Accept-Language: en-US,en;q=0.9' \
  --header 'Cache-Control: no-cache' \
  --header 'Connection: keep-alive' \
  --header 'Content-Type: application/json' \
  --header 'Pragma: no-cache' \
  --header 'User-Agent: llm-test-script/1.0' \
  --data "$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    --argjson max_tokens "$MAX_TOKENS" \
    --argjson temperature "$TEMPERATURE" \
    '{
      model: $model,
      prompt: $prompt,
      max_tokens: $max_tokens,
      temperature: $temperature
    }'
  )")

echo "$RESP" | jq .
echo "Chat Response"
echo "$RESP" | jq -r '.choices[0].text'