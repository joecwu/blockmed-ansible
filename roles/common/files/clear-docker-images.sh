#!/bin/bash
for i in `docker images | grep platform | awk '{print $3}' | uniq`;do docker rmi -f $i;done
docker rmi $(docker images -f "dangling=true" -q)