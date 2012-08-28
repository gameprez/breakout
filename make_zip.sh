#!/bin/bash
# This script creates an archive file ready to be uploaded to Gameprez.
coffee -c breakout/main.coffee
zip breakout.zip breakout/*
