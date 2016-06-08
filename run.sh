#!/bin/bash

#docker run -i -t --name redmine-backlogs lina/redmine-backlogs /bin/bash
docker run -d -p 8080:80 --name redmine-backlogs -e DB_USER=backlogs -e DB_PASS=backlogs -e DB_NAME=backlogs -e DB_HOST=192.168.1.2 lina/redmine-backlogs
