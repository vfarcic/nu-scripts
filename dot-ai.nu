#!/usr/bin/env nu

# Installs DevOps AI Toolkit with MCP server support
#
# Examples:
# > main apply dot-ai --host dot-ai.127.0.0.1.nip.io
# > main apply dot-ai --provider openai --model gpt-4o
def "main apply dot-ai" [
    --anthropic-api-key = "",
    --openai-api-key = "",
    --provider = "anthropic",
    --model = "claude-haiku-4-5-20251001",
    --ingress-enabled = true,
    --host = "dot-ai.127.0.0.1.nip.io",
    --version = "0.127.0"
] {

    let anthropic_key = if ($anthropic_api_key | is-empty) {
        $env.ANTHROPIC_API_KEY? | default ""
    } else {
        $anthropic_api_key
    }

    let openai_key = if ($openai_api_key | is-empty) {
        $env.OPENAI_API_KEY? | default ""
    } else {
        $openai_api_key
    }

    (
        helm upgrade --install dot-ai-mcp
            $"oci://ghcr.io/vfarcic/dot-ai/charts/dot-ai:($version)"
            --set $"secrets.anthropic.apiKey=($anthropic_key)"
            --set $"secrets.openai.apiKey=($openai_key)"
            --set $"ai.provider=($provider)"
            --set $"ai.model=($model)"
            --set $"ingress.enabled=($ingress_enabled)"
            --set $"ingress.host=($host)"
            --namespace dot-ai --create-namespace
            --wait
    )

    print $"DevOps AI Toolkit is available at (ansi yellow_bold)http://($host)(ansi reset)"

}
