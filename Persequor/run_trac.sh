#!/bin/sh
tracenv=/Users/sas/Projects/MacRuby/Persequor/Persequor/tracenv

tracd -s --port 8080 --basic-auth="tracenv,$tracenv/htpasswd,abstracture.de" $tracenv
