#!/usr/bin/env nu

# Installs KAgent with Anthropic provider support
#
# Examples:
# > main apply kagent
# > main apply kagent --model claude-sonnet-4-5-20250929
# > main apply kagent --anthropic-api-key "your-key-here"
# > main apply kagent --host kagent.example.com --ingress-class-name traefik
def "main apply kagent" [
    --anthropic-api-key = "",
    --model = "claude-haiku-4-5-20251001",
    --host = "kagent.127.0.0.1.nip.io",
    --ingress-class-name = "nginx",
    --crds-version = "latest",
    --version = "latest"
] {

    {
        apiVersion: "v1"
        kind: "Namespace"
        metadata: {
            name: "kagent"
        }
    } | to yaml | kubectl apply --filename -

    let anthropic_key = if ($anthropic_api_key | is-empty) {
        $env.ANTHROPIC_API_KEY? | default ""
    } else {
        $anthropic_api_key
    }

    {
        apiVersion: "v1"
        kind: "Secret"
        metadata: {
            name: "kagent-anthropic"
            namespace: "kagent"
        }
        type: "Opaque"
        stringData: {
            ANTHROPIC_API_KEY: $anthropic_key
        }
    } | to yaml | kubectl apply --filename -

    if $crds_version == "latest" {
        (
            helm upgrade --install kagent-crds
                oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds
                --namespace kagent --create-namespace
                --wait
        )
    } else {
        (
            helm upgrade --install kagent-crds
                oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds
                --namespace kagent --create-namespace
                --version $crds_version
                --wait
        )
    }

    if $version == "latest" {
        (
            helm upgrade --install kagent
                oci://ghcr.io/kagent-dev/kagent/helm/kagent
                --namespace kagent --create-namespace
                --set providers.default=anthropic
                --set providers.anthropic.apiKeySecretKey=ANTHROPIC_API_KEY
                --set providers.anthropic.apiKeySecretRef=kagent-anthropic
                --set $"providers.anthropic.model=($model)"
                --wait
        )
    } else {
        (
            helm upgrade --install kagent
                oci://ghcr.io/kagent-dev/kagent/helm/kagent
                --namespace kagent --create-namespace
                --set providers.default=anthropic
                --set providers.anthropic.apiKeySecretKey=ANTHROPIC_API_KEY
                --set providers.anthropic.apiKeySecretRef=kagent-anthropic
                --set $"providers.anthropic.model=($model)"
                --version $version
                --wait
        )
    }

    {
        apiVersion: "networking.k8s.io/v1"
        kind: "Ingress"
        metadata: {
            name: "kagent"
            namespace: "kagent"
        }
        spec: {
            ingressClassName: $ingress_class_name
            rules: [{
                host: $host
                http: {
                    paths: [{
                        path: "/"
                        pathType: "Prefix"
                        backend: {
                            service: {
                                name: "kagent-ui"
                                port: {
                                    number: 8080
                                }
                            }
                        }
                    }]
                }
            }]
        }
    } | to yaml | kubectl --namespace kagent apply --filename -

    print $"KAgent installed successfully with (ansi yellow_bold)anthropic(ansi reset) provider"
    print $"KAgent UI is available at (ansi yellow_bold)http://($host)(ansi reset)"

}
