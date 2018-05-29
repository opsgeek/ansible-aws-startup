#!/bin/bash
#
# Author: Rohit Nagpal
# Purpose: Startup configuration for instance on AWS


# Get the tag value "Role" of the instance, private ip, public ip of instance and setup hostname and host.json file.

count_pip=`curl http://169.254.169.254/latest/meta-data/ | grep public-ipv4 | wc -l`

privateip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

if [[ $count_pip -eq 1 ]]; then
	publicip=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
else
	publicip=""
fi

tag=`aws ec2 describe-tags --filters "Name=resource-id,Values=$(ec2-metadata -i | cut -d ' '  -f2)" "Name=key,Values=Role" | grep Value | awk -F\"  '{print $4}'`

#Set the ansibletag, if the Role tag is not set then simply set the ansibletag to baseplay so as to just run the "common" play for all instances
#else set the ansibletag equivalent to the Role tag and optionally set the hostname of the instance as well.
daship=`echo $privateip | sed 's/\./-/g'`
if [[ -z "${tag}" ]]; then
	ansibletag="baseplay"
else
	name="${tag}-${daship}"
	ansibletag=${tag}
	hostnamectl set-hostname --static ${name}
fi

# Pulling and running the appropriate ansible play from the playbook (based on the tag of the instance) for initial configuration of the instance as per its role.
playbookname="myplaybook.yml"
repourl="git@github.com:opsgeek/ansible-aws.git"

ansible-pull -C master -d /opt/ansible -U ${repourl} --extra-vars "variable_host=localhost" --tags "${ansibletag}" ${playbookname} > /tmp/ansible-pull.log 2>&1
