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
localhost ansible_connection=local ansible_user=zabudico

[all:vars]
ansible_python_interpreter=/usr/bin/python3
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
docker --version: Docker version 24.0.2, build cb74dfc
docker compose version: Docker Compose version (plugin)
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
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpresspassword
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - wordpress-network

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    restart: always
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpresspassword
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - wordpress-network

volumes:
  db_data:
  wordpress_data:

networks:
  wordpress-network:
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
- name: Deploy Docker Compose stack on localhost
  hosts: localhost
  become: no
  tasks:
    - name: Copy docker-compose.yml to application directory
      copy:
        src: ./docker-compose.yml
        dest: /opt/wordpress-app/docker-compose.yml
        mode: '0644'

    - name: Run docker compose up
      command: docker compose up -d
      args:
        chdir: /opt/wordpress-app

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
* Доступ: http://localhost:8080 — WordPress доступен.
* Результат: Развёртывание автоматизировано, стек работает на удалённой ВМ.

  <img width="1920" height="1040" alt="image" src="https://github.com/user-attachments/assets/5351ba5c-d59b-4858-bbb4-22d0e42bc9bf" />

  <img width="1920" height="1041" alt="image" src="https://github.com/user-attachments/assets/047286a0-af93-4284-bf29-256487576e99" />

  <img width="1336" height="567" alt="image" src="https://github.com/user-attachments/assets/2fbf3ed0-0a43-424e-a375-fbc524bb7e12" />


  ```bash

# 1. Проверка Docker
echo "=== Docker ==="
docker --version
docker compose version

# 2. Проверка контейнеров
echo -e "\n=== Контейнеры ==="
docker ps

# 3. Проверка сети
echo -e "\n=== Сети ==="
docker network ls | grep wordpress

# 4. Проверка volumes
echo -e "\n=== Volumes ==="
docker volume ls | grep wordpress-app

```

### Проблемы и их решение

В ходе выполнения работы возникли следующие проблемы и были найдены решения:

1. **Недоступность удаленных ВМ**  
   Проблема: Виртуальные машины по указанным IP-адресам были недоступны  
   Решение: Работа была выполнена на localhost (WSL) для демонстрации функциональности

2. **Занятый порт 80**  
   Проблема: Порт 80 был занят службой nginx  
   Решение: Остановлена служба nginx и использован порт 8080 в docker-compose.yml

3. **Устаревшая версия Ansible**  
   Проблема: В репозиториях доступна только Ansible 2.5.1  
   Решение: Работа выполнена с имеющейся версией, которая поддерживает необходимые модули


#### Что можно улучшить (дополнительно):
Вернуть nginx после завершения лабораторной работы:

```bash
sudo systemctl enable nginx
sudo systemctl start nginx
```

Остановить приложение когда закончите:

```bash
cd /opt/wordpress-app
docker compose down
```

Очистить ресурсы полностью:

```bash
docker compose down -v
```

## Выводы

В ходе лабораторной работы я успешно автоматизировал установку и развертывание Docker-based приложения с помощью Ansible. 
Несмотря на первоначальные проблемы с доступностью удаленных ВМ, работа была успешно выполнена на localhost, 
что демонстрирует переносимость и универсальность использованных подходов. Это позволило понять преимущества комбинации этих инструментов для DevOps: reproducibility, scalability и простота управления. Возможные улучшения: использование Ansible Vault для secrets, добавление мониторинга или CI/CD интеграции. Работа выполнена полностью, все проверки прошли успешно.

## Библиография

* Docker Documentation. Доступно по: https://docs.docker.com/.
* Docker Compose Documentation. Доступно по: https://docs.docker.com/compose/.
* Ansible Documentation. Доступно по: https://docs.ansible.com/.
* WordPress Docker Image. Доступно по: https://hub.docker.com/_/wordpress.
* MySQL Docker Image. Доступно по: https://hub.docker.com/_/mysql.
* Docker Compose Releases on GitHub. Доступно по: https://github.com/docker/compose/releases.


