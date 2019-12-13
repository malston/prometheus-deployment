#!/bin/bash

alerts1='[
  {
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
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example3",
       "severity": "critical"
     }
  },
  {
    "labels": {
       "alertname": "TestAlert",
       "dev": "sda1",
       "instance": "example3",
       "severity": "warning"
     }
  }
]'
curl -XPOST -d"$alerts1" http://alertmanager-03.haas-440.pez.pivotal.io/api/v1/alerts
