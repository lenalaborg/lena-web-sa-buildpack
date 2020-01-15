#!/bin/bash

while true
    do
        tail -f /dev/null & wait ${!}
    done