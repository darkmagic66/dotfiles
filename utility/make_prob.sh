#!/usr/bin/env bash

TEMPLATE_DIR="$HOME/coding/prac/cp-template"

if [ -z "$1" ]; then
    echo "Usage: cp-init <prob1> [prob2] [prob3] ..."
    exit 1
fi

for PROBLEM_NAME in "$@"; do
    if [ -d "$PROBLEM_NAME" ]; then
        echo "Error: Directory '$PROBLEM_NAME' already exists. Skipping."
        continue 
    fi

    mkdir -p "$PROBLEM_NAME"

    cp "$TEMPLATE_DIR/Makefile" "$PROBLEM_NAME/"
    cp "$TEMPLATE_DIR/template.cpp" "$PROBLEM_NAME/$PROBLEM_NAME.cpp"

    # Changed to your preferred naming convention
    touch "$PROBLEM_NAME/in1"

    echo "Successfully created setup for '$PROBLEM_NAME'."
done


