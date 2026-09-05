# Ansible wrapper (optional)

Ansible is **not** a second installer. Bash modules remain the source of truth.

## Layout

```text
ansible/
  ansible.cfg
  inventories/
    hosts.example.yml    # copy → hosts.yml
  playbooks/
    site.yml             # entry playbook
  roles/
    server_installer/    # invokes bin/server-installer apply
```

## Prerequisites

1. Control node: `sudo ./bin/server-installer apply --modules ansible`
2. Target: server-installer tree at `si_root` (default playbook uses repo-relative path for localhost)
3. Inventory: `cp inventories/hosts.example.yml inventories/hosts.yml`

## Localhost smoke

```bash
cd ansible
cp inventories/hosts.example.yml inventories/hosts.yml
ansible-playbook playbooks/site.yml -l localhost
```

Override modules:

```bash
ansible-playbook playbooks/site.yml -l localhost -e si_modules=packages,timesync
```

## Remote host

```yaml
# inventories/hosts.yml
all:
  children:
    jooservices:
      hosts:
        app1.example.com:
          ansible_user: deploy
      vars:
        si_root: /opt/server-installer
        si_modules: packages,docker,docker_group
        si_env:
          SI_DOCKER_USER: deploy
```

Sync the repo to `si_root` on the target first (git clone, rsync, or a future sync task).
