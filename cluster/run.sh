#!/bin/bash
eksctl create cluster -f cluster.yaml
eksctl create nodegroup -f node_groups.yaml
