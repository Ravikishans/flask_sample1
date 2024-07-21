#!/bin/bash
sudo apt-get update -y
sudo apt-get install python3 -y
sudo apt-get install python3-pip -y
sudo apt-get install python3-flask -y
sudo apt-get install nginx -y
echo 'server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}' | sudo tee /etc/nginx/sites-enabled/default >/dev/null

sudo systemctl restart nginx 
sudo apt-get install screen -y
sudo kill -9 `ps aux | grep hello.py | awk '{print $2}'`
SESSION_NAME="flask_app"
FLASK_COMMAND="python3 /home/ubuntu/hello.py"

if ! command -v tmux &> /dev/null
then
    echo "tmux could not be found, installing it..."
    sudo apt-get update
    sudo apt-get install tmux
fi
tmux new -d -s $SESSION_NAME $FLASK_COMMAND

if tmux ls | grep -q "$SESSION_NAME"; then
  echo "Flask app is running in a tmux session named $SESSION_NAME."
else
  echo "Failed to start Flask app in a tmux session."
fi
