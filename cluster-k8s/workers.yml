- name: Join Worker Nodes
  gather_facts: true
  hosts: workers
  become: true
  vars:
    node_conn_string: "{{ lookup('ansible.builtin.file', 'Remote_Files/worker_conn_string') }}"

  tasks:
    - name: 1. Add Worker Nodes To The Controller
      ansible.builtin.command: '{{ node_conn_string }}'
      changed_when: false
      throttle: 1