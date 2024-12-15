#!/usr/bin/env nu

def --env "main get github" [] {

    mut github_token = ""
    if "GITHUB_TOKEN" in $env {
        $github_token = $env.GITHUB_TOKEN
    } else if "REGISTRY_PASSWORD" in $env {
        $github_token = $env.REGISTRY_PASSWORD
    } else {
        $github_token = input $"(ansi green_bold)Enter GitHub token:(ansi reset)"
    }
    $"export GITHUB_TOKEN=($github_token)\n" | save --append .env

    mut github_user = ""
    if "GITHUB_USER" in $env {
        $github_user = $env.GITHUB_USER
    } else if "REGISTRY_USER" in $env {
            $github_user = $env.GITHUB_USER
    } else {
        $github_user = input $"(ansi green_bold)Enter GitHub user or organization where you forked the repo:(ansi reset)"
    }
    $"export GITHUB_USER=($github_user)\n" | save --append .env

    {user: $github_user, token: $github_token}

}
