# BlockMed Ansible Configuration Manager

## Setup for control machine (e.g: localhost)

### Runtime Environment

1. install python
2. install ansible

on MacOS you might need to install `pip` via
```
sudo easy_install pip
```

make sure Ansible version is above of `2.5.0`

3. install bob & bob3. `pip install boto` `pip install boto3`

### Install Dependencies Roles from Ansible Galaxy

```
ansible-galaxy install -r requirements.yml
```

### All-In-One(including above env setup) with MacOS iTerm2 setup

1. create setup_aws_{env}.sh
```
#!/bin/sh
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_REGION="ap-northeast-1"
```

2. create ansible_{env}.cfg
```
[defaults]
inventory = ~/devops/ansible/{env}
host_key_checking = False
vault_password_file = ~/ansible/vault_{env}_pass
remote_user = centos
private_key_file = ~/.ssh/id_rsa
```

3. create new iTerm2 profile with `Send text at start` setup (2 lines)
```
source ~/.scripts/setup-aws-{env}.sh
export ANSIBLE_CONFIG=~/ansible/ansible_{env}.cfg
```

4. now you can open iTerm2 specific env profile and using `ansible` or `ansible-playbook` directly.

### Running Ansible on local machine via SSH proxy without VPN

[reference](https://blog.scottlowe.org/2015/12/24/running-ansible-through-ssh-bastion-host/)

`/Users/joecwu/ansible/ssh_staging.cfg`
```
Host 172.16.*.*
  ProxyCommand ssh -W %h:%p %r@demo-vpn.kiri.tech
  IdentityFile ~/.ssh/id_rsa
  User centos

Host demo-vpn.kiri.tech
  Hostname demo-vpn.kiri.tech
  User centos
  IdentityFile ~/.ssh/id_rsa
  ControlMaster auto
  ControlPath ~/.ssh/ansible-staging-%r@%h:%p
  ControlPersist 5m
```

`ansible_staging.cfg`
```
[default]
....(refer to above setting)....

[ssh_connection]
ssh_args = -F /Users/joecwu/ansible/ssh_staging.cfg -o ControlMaster=auto
scp_if_ssh = True
ControlPersist=30m
control_path = ~/.ssh/ansible-%%r@%%h:%%p
```

## Run Example

### Ping

test with `ansible all -m ping` and you should get the response below.
```
dev-e | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
dev-a | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
```


### Deploy `event-listener` on dev env in first time.

```
ansible-playbook -i joe setup-event-listener.yml -e "ansible_ssh_user=root"
```

### Deploy `event-listener` on prod env in first time.

```
ansible-playbook -i production setup-event-listener.yml
```


### Deploy `event-listener` on dev env with upgrade only.

```
ansible-playbook -i joe setup-event-listener.yml -e "ansible_ssh_user=root" --skip-tags "init"
```

### Deploy `event-listener` on prod env with upgrade only.

```
ansible-playbook -i production setup-event-listener.yml --skip-tags "init"
```

### Run specific part in playbook using `tags`

```
ansible-playbook -i dev setup.yml --tags "company-backend,brand-backend" -e "ansible_ssh_user=joecwu"
```
or with All-In-One env setup
```
ansible-playbook setup.yml --tags "company-backend,brand-backend"
```

#### Run with `vault` (which be used to encrypt credentials in staing & prod)

```
ansible-playbook -i staging setup-integration-backend.yml -e "ansible_ssh_user=centos" --ask-vault-pass
```

#### Run on specific machine only

```
ansible-playbook -i staging setup.yml -e "ansible_ssh_user=centos" --ask-vault-pass --limit ms-3
```
or with All-In-One env setup
```
ansible-playbook setup.yml --limit ms-3
```



## Appendix

### 坑

#### docker module issue on `Remote Machine`

```
fatal: [dev-apis]: FAILED! => {"changed": false, "failed": true, "msg": "Failed to import docker-py - No module named requests.exceptions. Try `pip install docker-py`"}
```

**this error indicate the remote client has no related python module, not local host.**

```
For people lazy to read every post here:
Since ansible 2.3, the dependency issue docker-py is fixed:

if you use the default python 2.7, the docker module needs docker-py

if you use python 3 (-e 'ansible_python_interpreter=/usr/bin/python3' ), it needs docker instead of docker-py
in all case, clean by pip uninstall docker docker-py docker-compose
reinstall
pip install docker-compose
```

**Solution:** setup dependencies in runner machine

```
yum install -y epel-release

yum install -y python-pip

pip install docker-py

```

#### AWS capacity with `boto` dependency on `Control Machine`

```
fatal: [localhost]: FAILED! => {"changed": false, "failed": true, "msg": "boto required for this module"}
```

**Solution:** setup boto on `Control Machine`

```
pip install boto
```

#### behaviour of `--limits`

ref:[stackoverflow](https://stackoverflow.com/questions/44541463/limit-ansible-playbook-by-hosts-of-plays)

### Utils

#### get prod disk info from instances

```
ansible all -m shell -a "df -h|grep /dev/xvd"
```
