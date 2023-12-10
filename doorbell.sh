#!/bin/bash

broker_url="ip"
topic="home/doorbell"
user="user"
password="password"
sound_file="/home/skynet/wavs/asshole.wav"

mosquitto_sub -h $broker_url -u $user -P $password -t $topic | while read -r message
do
  echo "Received message: $message"

  aplay $sound_file
done
