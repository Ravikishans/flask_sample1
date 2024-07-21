#!/bin/bash
sudo apt-get update -y
sudo apt-get install python3 -y
sudo apt-get install python3-pip -y
sudo python3 -m pip install flask
sudo apt-get install nginx -y
sudo systemctl restart nginx 
sudo kill -9 `ps aux | grep hello.py | awk '{print $2}'`
nohup python hello.py > app.log 2>&1 &
echo "Done....."
