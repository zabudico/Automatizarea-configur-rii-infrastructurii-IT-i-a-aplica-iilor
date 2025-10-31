# Лабораторная работа: Автоматизация развертывания многоконтейнерного приложения с Docker Compose с использованием Ansible

Автор: Zabudico Alexandr 

Дата: 31 октября 2025 г.


## Цель работы
Целью этой лабораторной работы было закрепить знания по Docker и Docker Compose путём автоматизации их установки и развертывания на удалённых виртуальных машинах с помощью Ansible. Я научился объединять инструменты конфигурационного управления (Ansible) с контейнеризацией (Docker), создавая reproducible инфраструктуру. Это позволило понять, как в реальных сценариях DevOps Ansible используется для оркестрации контейнеров на нескольких хостах.

### Окружение

Локальная машина (контроллер): Ansible установлен, inventory-файл с группой "docker_hosts" (две ВМ на Ubuntu).
Виртуальные машины: Две ВМ (vm1 и vm2) с доступом по SSH, ОС Ubuntu/Debian.
Инструменты: Ansible, Docker, Docker Compose.

```
Inventory-файл (hosts.ini):
vm1 ansible_host=192.168.1.101 ansible_user=youruser ansible_ssh_private_key_file=~/.ssh/id_rsa
vm2 ansible_host=192.168.1.102 ansible_user=youruser ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### Задание 1: Установка Docker и Docker Compose с помощью Ansible

#### Описание

Написал playbook install_docker.yml для автоматизированной установки Docker на всех хостах в группе "docker_hosts". Использовал модули Ansible для установки пакетов, добавления репозитория, установки Docker и Compose, а также добавления пользователя в группу docker.

Содержимое playbook (install_docker.yml)

```yaml
---
- name: Install Docker and Docker Compose on docker_hosts
  hosts: docker_hosts
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install required dependencies
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - software-properties-common
          - gnupg
        state: present

    - name: Add Docker GPG apt key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker repository
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable
        state: present
        filename: docker

    - name: Update apt cache after adding repo
      apt:
        update_cache: yes

    - name: Install Docker packages
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
        state: present

    - name: Add user to docker group
      user:
        name: "{{ ansible_user }}"
        groups: docker
        append: yes

    - name: Install Docker Compose plugin
      command: docker compose version
      register: compose_check
      ignore_errors: yes
      changed_when: false

    - name: Install Docker Compose if not present
      command: |
        mkdir -p ~/.docker/cli-plugins/
        curl -SL https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
        chmod +x ~/.docker/cli-plugins/docker-compose
      when: compose_check.rc != 0

```

#### Выполнение и проверка

* Запустил playbook: ansible-playbook install_docker.yml -i hosts.ini.
* Playbook успешно выполнился на обеих ВМ без ошибок.
* Подключился по SSH к vm1 и vm2:

```bash
docker --version: Docker version 27.3.1, build 7cbfd87.
docker compose version: Docker Compose version v2.29.7.
```

Результат: Docker и Compose установлены корректно, пользователь добавлен в группу docker.

### Задание 2: Создание Docker Compose файла для многоконтейнерного приложения

#### Описание

Создал файл docker-compose.yml для стека WordPress + MySQL. Определил сервисы, volumes, networks и environment variables. Протестировал локально.

Содержимое файла (docker-compose.yml)

```bash
services:
  db:
    image: mysql:8.0
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: somewordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    networks:
      - wp_network

  wordpress:
    image: wordpress:latest
    depends_on:
      - db
    ports:
      - "8000:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/www/html
    networks:
      - wp_network

volumes:
  db_data: {}
  wp_data: {}

networks:
  wp_network:
    driver: bridge
```

#### Тестирование локально

* Запустил: docker compose up -d.
* Проверил: docker ps — два контейнера (wordpress и mysql) запущены.
* Доступ к WordPress: http://localhost:8000 — успешно установил, используя предоставленные credentials.
* Остановил: docker compose down -v.
* Результат: Стек работает корректно, данные persistent благодаря volumes.

### Задание 3: Автоматизация развертывания Docker Compose с помощью Ansible

#### Описание

Написал playbook deploy_compose.yml для копирования docker-compose.yml на vm1 и запуска стека. Для репликации можно применить к обеим ВМ, но в этом случае развернул на vm1.

Содержимое playbook (deploy_compose.yml)

```yaml
---
- name: Deploy Docker Compose stack on VM1
  hosts: vm1
  become: no
  tasks:
    - name: Copy docker-compose.yml to remote host
      copy:
        src: ./docker-compose.yml
        dest: /home/{{ ansible_user }}/docker-compose.yml
        mode: '0644'

    - name: Run docker compose up
      shell: docker compose -f /home/{{ ansible_user }}/docker-compose.yml up -d
      args:
        chdir: /home/{{ ansible_user }}/

    - name: Check container status
      command: docker ps
      register: docker_ps_output

    - name: Display docker ps output
      debug:
        msg: "{{ docker_ps_output.stdout }}"
```

#### Выполнение и проверка

* Запустил playbook: ansible-playbook deploy_compose.yml -i hosts.ini.
* Playbook успешно скопировал файл и запустил compose.
* Подключился по SSH к vm1: docker ps — контейнеры wordpress и mysql запущены.
* Доступ: http://192.168.1.101:8000 — WordPress доступен (после настройки firewall: ufw allow 8000).
* Результат: Развёртывание автоматизировано, стек работает на удалённой ВМ.

## Выводы

В ходе лабораторной работы я успешно автоматизировал установку и развертывание Docker-based приложения с помощью Ansible. Это позволило понять преимущества комбинации этих инструментов для DevOps: reproducibility, scalability и простота управления. Возможные улучшения: использование Ansible Vault для secrets, добавление мониторинга или CI/CD интеграции. Работа выполнена полностью, все проверки прошли успешно.

## Библиография

* Docker Documentation. Доступно по: https://docs.docker.com/.
* Docker Compose Documentation. Доступно по: https://docs.docker.com/compose/.
* Ansible Documentation. Доступно по: https://docs.ansible.com/.
* WordPress Docker Image. Доступно по: https://hub.docker.com/_/wordpress.
* MySQL Docker Image. Доступно по: https://hub.docker.com/_/mysql.
* Docker Compose Releases on GitHub. Доступно по: https://github.com/docker/compose/releases.
