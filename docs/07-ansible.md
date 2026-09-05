# Ansible wrapper

Optional fleet entry under `ansible/`. Playbooks call this repo’s CLI — they do **not** re-implement modules as Ansible roles.

```bash
cd ansible
# Point inventory at hosts, then:
ansible-playbook -i inventories/hosts.example.yml playbooks/site.yml
```

See [`../ansible/README.md`](../ansible/README.md).

Next: [Testing](./08-testing.md)
