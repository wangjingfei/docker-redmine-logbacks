#!/bin/bash

#docker run -i -t --name redmine-backlogs lina/redmine-backlogs /bin/bash
docker run -d -p 8080:80 --name redmine-backlogs lina/redmine-backlogs
