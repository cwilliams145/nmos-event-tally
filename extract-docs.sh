#!/bin/bash

function extract {
    checkout=$1
    target_dir=$2
    echo "Extracting documentation from $checkout into $target_dir"
    mkdir "$target_dir"
    cd source-repo
        git checkout "$checkout"
        [ -d docs ] && cp -r docs "../$target_dir"
        if [ -d APIs ]; then
            cd APIs
                echo "NB: including workaround for how v6 of raml2html deals with \$ref and schemas/ dir"
                perl -pi.orig -e 's=("\$ref": ")(.*)(\.json)=$1schemas/$2$3=' schemas/*.json
                for i in *.raml; do
                    echo "Generating HTML from $i..."
                    raml2html "$i" > "${i%%.raml}.html"
                done
                for i in schemas/*.json.orig; do
                    mv "$i" "${i%%.orig}"
                done
                mkdir "../../$target_dir/html-APIs"
                mv *.html "../../$target_dir/html-APIs/"
                if [ -d schemas ]; then
                    echo "Linting schemas..."
                    jsonlint -v schemas/*.json
                    echo "Copying schemas..."
                    mkdir "../../$target_dir/html-APIs/schemas"
                    cp schemas/*.json "../../$target_dir/html-APIs/schemas"
                fi
                cd ..
        fi
        if [ -d examples ]; then
            echo "Linting examples..."
            jsonlint -v examples/*.json
            echo "Copying examples..."
            cp -r examples "../$target_dir"
        fi
    cd ..

}


mkdir branches
for branch in $(cd source-repo; git branch -r | sed 's:origin/::' | grep -v HEAD | grep -v gh-pages); do
    extract "$branch" "branches/$branch"
done

mkdir tags
for tag in $(cd source-repo; git tag); do
    extract "tags/$tag" "tags/$tag"
done
