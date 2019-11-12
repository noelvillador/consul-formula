#### from github https://github.com/hashicorp/consul/issues/758 ####
{%- from slspath+"/map.jinja" import consul with context -%}

{% if grains['os'] != 'Windows' %}
consul-init-file:
  file.managed:
    {%- if salt['test.provider']('service') == 'systemd' %}
    - source: salt://{{ slspath }}/files/consul.service
    - name: /etc/systemd/system/consul.service
    - mode: 0644
    {%- elif salt['test.provider']('service') == 'upstart' %}
    - source: salt://{{ slspath }}/files/consul.upstart
    - name: /etc/init/consul.conf
    - mode: 0644
    {%- else %}
    - source: salt://{{ slspath }}/files/consul.sysvinit
    - name: /etc/init.d/consul
    - mode: 0755
    {%- endif %}

{% else %}
  {% if grains['num_cpus'] == 1 %}
    {% set GOMAXPROCS = 2 %}
  {% else %}
    {% set GOMAXPROCS = grains['num_cpus'] %}
  {% endif %}

Ensure Consul service is registered:
  cmd.run:
    - name: |
        {{ consul.bin_dir }}\nssm-{{ consul.nssm_version }}\win64\nssm.exe install consul {{ consul.bin_dir }}\consul.exe agent -config-dir {{ consul.config_dir }}
    - unless: sc query consul

Ensure GOMAXPROCS is set to the number of CPUs:
  cmd.run:
    - shell: powershell
    - name: |
        {{ consul.bin_dir }}\nssm-{{ consul.nssm_version }}\win64\nssm.exe set consul AppEnvironmentExtra GOMAXPROCS={{ GOMAXPROCS }}
    - unless: |
        if ($({{ consul.bin_dir }}\nssm-{{ consul.nssm_version }}\win64\nssm.exe get consul AppEnvironmentExtra).Contains(GOMAXPROCS={{ GOMAXPROCS }})) {exit 0}; exit 1

#Ensure negative DNS resolutions are not cached:
#  cmd.run:
#    - name: |
#        C:\Windows\System32\reg.exe add HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters /v MaxNegativeCacheTtl /t REG_DWORD /d
#    - unless: |
#        C:\Windows\System32\reg.exe query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DNSCache\Parameters /v MaxNegativeCacheTtl

#Ensure DNS Client is restarted:
#  module.wait:
#    - name: service.restart
#    - m_name: Dnscache
#    - onchanges:
#      - cmd: Ensure negative DNS resolutions are not cached

Ensure Consul firewall TCP port is open:
  win_firewall.add_rule:
    - name: Consul Serf LAN
    - localport: 8301

Ensure Consul firewall UDP port is open:
  win_firewall.add_rule:
    - name: Consul Serf LAN UDP
    - localport: 8301
    - protocol: udp

{% endif %}

{%- if consul.service %}
consul-chkconfig:
  cmd.run:
    - name: "chkconfig --add consul"

consul-service:
  service.running:
    - name: consul
    - enable: True
{% if grains['os'] != 'Windows' %}
    - watch:
      - file: consul-init-file
{% else %}
    - watch:
      - cmd: Ensure Consul service is registered
{% endif %}

{%- endif %}
