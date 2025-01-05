#!/usr/bin/env nu

def "main get hyperscaler" [] {
    let hyperscaler = [aws azure google]
        | input list $"(ansi yellow_bold)Which Hyperscaler do you want to use?(ansi green_bold)"
    print $"(ansi reset)"

    $"export HYPERSCALER=($hyperscaler)\n" | save --append .env

    $hyperscaler
}
