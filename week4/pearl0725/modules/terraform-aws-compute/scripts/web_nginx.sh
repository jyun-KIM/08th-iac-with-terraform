#!/bin/bash

yum -y update
yum -y install nginx
systemctl enable nginx
systemctl start nginx