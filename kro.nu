#!/usr/bin/env nu


def "main apply kro" [] {

    (
        helm upgrade --install kro oci://public.ecr.aws/kro/kro
            --namespace kro --create-namespace
    )

}