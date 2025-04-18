#!/usr/bin/env nu

# Installs Kro (Kubernetes Resource Orchestrator) for orchestrating Kubernetes resources
def "main apply kro" [] {

    (
        helm upgrade --install kro oci://public.ecr.aws/kro/kro
            --namespace kro --create-namespace
    )

}