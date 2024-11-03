#!/usr/bin/env nu

def create_storage [provider: string] {

    mut bucket = ""

    if $provider == "aws" {

        $bucket = $"dot-(date now | format date "%Y%m%d%H%M%S")"
        $"export STORAGE_NAME=($bucket)\n" | save --append .env

        (
            aws s3api create-bucket --bucket $bucket
                --region us-east-1
        )
        
        aws iam create-user --user-name velero
        
        (
            aws iam put-user-policy --user-name velero
                --policy-name velero
                --policy-document file://aws-storage-policy.json
        )
        
        let access_key_id = (
            aws iam create-access-key --user-name velero
                | from json
                | get AccessKey.AccessKeyId
        )
        $"export STORAGE_ACCESS_KEY_ID=($access_key_id)\n"
            | save --append .env

    } else {

        print $"(ansi red_bold)($provider)(ansi reset) is not a supported."
        exit 1

    }

    {name: $bucket}

}

def destroy_storage [provider: string, storage_name: string] {

    if $provider == "aws" {

        (
            aws iam delete-access-key --user-name velero
                --access-key-id $env.STORAGE_ACCESS_KEY_ID
        )

        (
            aws iam delete-user-policy --user-name velero
                --policy-name velero
        )

        aws iam delete-user --user-name velero

        (        
            aws s3 rm $"s3://($storage_name)" --recursive
                --include "*"
        )

        (
            aws s3api delete-bucket --bucket $storage_name
                --region us-east-1
        )

    } else {

        print $"(ansi red_bold)($provider)(ansi reset) is not a supported."
        exit 1

    }

}
