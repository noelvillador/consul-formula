{% from slspath+"/map.jinja" import consul with context %}

consul-bin-dir:
  file.directory:
    - name: {{ consul.bin_dir }}
    - makedirs: True

{% if grains['os'] != 'Windows' %}
# Create consul user
consul-user:
  group.present:
    - name: consul
  user.present:
    - name: consul
    - createhome: false
    - system: true
    - groups:
      - consul
    - require:
      - group: consul
{% endif %}

# Create directories
consul-config-dir:
  file.directory:
    - name: {{ consul.config_dir }}
{% if grains['os'] != 'Windows' %}
    - user: consul
    - group: consul
{% endif %}

consul-data-dir:
  file.directory:
    - name: {{ consul.config.data_dir }}
{% if grains['os'] != 'Windows' %}
    - user: consul
    - group: consul
{% endif %}
    - makedirs: True

# Install agent
consul-download:
  file.managed:
    - name: {{ consul.temp_dir }}/consul_{{ consul.version }}_{{ consul.os }}_{{ consul.arch }}.zip
    - source: https://{{ consul.download_host }}/consul/{{ consul.version }}/consul_{{ consul.version }}_{{ consul.os }}_{{ consul.arch }}.zip
    - source_hash: https://releases.hashicorp.com/consul/{{ consul.version }}/consul_{{ consul.version }}_SHA256SUMS
{% if grains['os'] != 'Windows' %}
    - unless: test -f {{ consul.bin_dir }}/consul-{{ consul.version }}
{% else %}
    - unless: powershell -command "& { if(Test-Path {{ consul.bin_dir }}/consul-{{ consul.version }}.exe ){ exit 0 } else { exit 1 } }"
{% endif %}

consul-extract:
  archive.extracted:
    - name: {{ consul.temp_dir }}
    - source: {{ consul.temp_dir }}/consul_{{ consul.version }}_{{ consul.os }}_{{ consul.arch }}.zip
    - enforce_toplevel: false
{% if grains['os'] != 'Windows' %}
    - unless: test -f {{ consul.bin_dir }}/consul-{{ consul.version }}
{% else %}
    - unless: powershell -command "& { if(Test-Path {{ consul.bin_dir }}/consul-{{ consul.version }}.exe ){ exit 0 } else { exit 1 } }"
{% endif %}

consul-install:
  file.rename:
    - name: {{ consul.bin_dir }}/consul-{{ consul.version }}{%- if consul.file_ext is defined -%}{{ consul.file_ext }}{%- endif %}
    - source: {{ consul.temp_dir }}/consul{%- if consul.file_ext is defined -%}{{ consul.file_ext }}{%- endif %}
    - require:
      - file: {{ consul.bin_dir }}
    - watch:
      - archive: consul-extract

{% if grains['os'] != 'Windows' %}
consul-allow-permission:
    cmd.run:
      - name: setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/consul-{{ consul.version }}
{% endif %}


consul-clean:
  file.absent:
    - name: {{ consul.temp_dir }}/consul_{{ consul.version }}_{{ consul.os }}_{{ consul.arch }}.zip
    - watch:
      - file: consul-install

consul-link:
  file.symlink:
    - target: {{ consul.bin_dir}}/consul-{{ consul.version }}{%- if consul.file_ext is defined -%}{{ consul.file_ext }}{%- endif %}
    - name: {{ consul.bin_dir }}/consul{%- if consul.file_ext is defined -%}{{ consul.file_ext }}{%- endif %}
    - watch:
      - file: consul-install

# Install nssm for windows service
{% if grains['os'] == 'Windows' %}
nssm-download:
  file.managed:
     - name: {{ consul.temp_dir }}/nssm_{{ consul.nssm_version }}.zip
     - source: http://nssm.cc/release/nssm-{{ consul.nssm_version }}.zip
     - source_hash: {{ consul.nssm_hash }}
     
nssm-extract:
  archive.extracted:
    - name: {{ consul.bin_dir}}
    - source: {{ consul.temp_dir }}/nssm_{{ consul.nssm_version }}.zip
    - enforce_toplevel: false
{% endif %}
