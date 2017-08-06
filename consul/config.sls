{% from slspath+"/map.jinja" import consul with context %}

consul-config:
  file.managed:
    - name: {{ consul.config_dir }}/config.json
    {% if consul.service != False %}
    - watch_in:
       - service: consul
    {% endif %}
{% if grains['os'] != 'Windows' %}
    - user: consul
    - group: consul
    - require:
      - user: consul
{% endif %}
    - contents: |
        {{ consul.config | json }}

{% for script in consul.scripts %}
consul-script-install-{{ loop.index }}:
  file.managed:
    - source: {{ script.source }}
    - name: {{ script.name }}
    - template: jinja
{% if grains['os'] != 'Windows' %}
    - user: consul
    - group: consul
{% endif %}
    - mode: 0755
{% endfor %}

consul-script-config:
  file.managed:
    - source: salt://{{ slspath }}/files/services.json
    - name: {{ consul.config_dir }}/services.json
    - template: jinja
    {% if consul.service != False %}
    - watch_in:
       - service: consul
    {% endif %}
{% if grains['os'] != 'Windows' %}
    - user: consul
    - group: consul
    - require:
      - user: consul
{% endif %}
    - context:
        register: |
          {{ consul.register | json }}
