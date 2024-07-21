#!/bin/bash
sudo apt-get update -y
sudo apt-get install python3 -y
sudo apt-get install python3-pip -y
sudo python3 -m pip install flask
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
}' | sudo tee /etc/nginx/sites-available/default >/dev/null

sudo systemctl restart nginx 
sudo kill -9 `ps aux | grep hello.py | awk '{print $2}'`
python3 /home/ubuntu/hello.py &
echo "Done....."
