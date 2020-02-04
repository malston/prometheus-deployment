#!/bin/bash

CLUSTER_NAME="$(kubectl config current-context)"
CLUSTER_NUM="$(echo "${CLUSTER_NAME}" | cut -c8-9)"
ALERTMANAGER_URL="https://alertmanager-${CLUSTER_NUM}.haas-440.pez.pivotal.io"

firing_alerts='[
  {
    "status": "firing",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example1"
     },
     "annotations": {
        "info": "The disk sda1 is running full",
        "summary": "please check the instance example1"
      }
  },
  {
    "status": "firing",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda2",
       "instance": "example1"
     },
     "annotations": {
        "info": "The disk sda2 is running full",
        "summary": "please check the instance example1",
        "runbook": "the following link http://test-url should be clickable"
      }
  },
  {
    "status": "firing",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example2"
     },
     "annotations": {
        "info": "The disk sda1 is running full",
        "summary": "please check the instance example2"
      }
  },
  {
    "status": "firing",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sdb2",
       "instance": "example2"
     },
     "annotations": {
        "info": "The disk sdb2 is running full",
        "summary": "please check the instance example2"
      }
  },
  {
    "status": "firing",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example3",
       "severity": "critical"
     }
  },
  {
    "status": "firing",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example3",
       "severity": "warning"
     }
  }
]'
echo ""
curl -XPOST -d"$firing_alerts" -k "$ALERTMANAGER_URL/api/v1/alerts"
echo ""

resolved_alerts='[
  {
    "status": "resolved",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example1"
     },
     "annotations": {
        "info": "The disk sda1 is running full",
        "summary": "please check the instance example1"
      }
  },
  {
    "status": "resolved",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda2",
       "instance": "example1"
     },
     "annotations": {
        "info": "The disk sda2 is running full",
        "summary": "please check the instance example1",
        "runbook": "the following link http://test-url should be clickable"
      }
  },
  {
    "status": "resolved",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example2"
     },
     "annotations": {
        "info": "The disk sda1 is running full",
        "summary": "please check the instance example2"
      }
  },
  {
    "status": "resolved",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sdb2",
       "instance": "example2"
     },
     "annotations": {
        "info": "The disk sdb2 is running full",
        "summary": "please check the instance example2"
      }
  },
  {
    "status": "resolved",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example3",
       "severity": "critical"
     }
  },
  {
    "status": "resolved",
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example3",
       "severity": "warning"
     }
  }
]'
echo -n "Press enter to resolve 'TestAlert'"
read -r
curl -XPOST -d"$resolved_alerts" -k "$ALERTMANAGER_URL/api/v1/alerts"
echo ""