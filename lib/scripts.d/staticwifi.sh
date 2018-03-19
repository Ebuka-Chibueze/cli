#!/bin/bash
ifconfig wlan0 up || true
ifconfig wlan0 down || true
sleep 1
ifconfig wlan0 up || true
