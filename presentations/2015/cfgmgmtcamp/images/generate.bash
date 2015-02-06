#!/bin/bash
set -e
set -x

rm *.svg
java -jar ./../../../plantuml.jar -- -duration -tsvg ./*.puml

