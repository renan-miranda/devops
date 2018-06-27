# devops

Few steps to run properly:

Terraform:

  $ ./Terraform/terraform plan  
  or  
  $./Terraform/terraform -var 'access_key=XXX' -var 'access_secret_key=YYY' -var 'key_name=ZZZ' -var 'public_key_path=/path/to/ZZZ.pub'  -var 'region=AAAA'

  where:

  - access_key: AWS user key
  - access_secret_key: AWS secret key for AWS user
  - key_name: The name of id_rsa key that will be created to access AWS servers
  - public_key_path: The path where public key will be stored
  - regios: AWS region where the VPC will be stored.

  Terraform will create two files:

  - aws_hosts.env: File with informations about your EC2 instances, like public and private IP and DNS (They will be stored in Jenkins server by Ansible).
  - inventory: File with two group to be used in Ansible

Ansible:

  Before you start:
   - Fill the file "docker.user" with your dockerhub user

  Execute in this order:

  $ ansible-playbook -i inventory 01_play_java.yml  
  $ ansible-playbook -i inventory 02_play_maven.yml  
  $ ansible-playbook -i inventory 03_play_docker.yml  
  $ ansible-playbook -i inventory 04_play_jenkins.yml  
  $ ansible-playbook -i inventory 05_play_ssh_keys.yml  
