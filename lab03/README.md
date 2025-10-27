# Отчёт о проделанной работе по настройке сервера с использованием Ansible

* Автор: Zabudico Alexandr (zabudico@DESKTOP-IIHR7IH)
* Дата: 20 октября 2025 года

## Цель: 

Автоматизированное развертывание статического сайта на Nginx и создание технического пользователя deploy с SSH-доступом по ключу и правами sudo без пароля на сервере Ubuntu 18.04.6 LTS. Работа выполнена с использованием Ansible playbook'ов, с учётом Extended Security Maintenance (ESM) для обновлений системы.

### 1. Введение

Данный отчёт документирует процесс настройки сервера, включая подготовку окружения, создание файлов, разработку и запуск двух Ansible playbook'ов, а также верификацию результатов. Все действия выполнены на локальной машине DESKTOP-IIHR7IH (Ubuntu 18.04.6 LTS), где Ansible работает в режиме localhost (локальное подключение).

Ключевые вызовы и решения:

Активация ESM для доступа к обновлениям (стандартная поддержка Ubuntu 18.04 закончилась в 2023 году).
Исправление ошибок YAML-структуры и путей к файлам в playbook'ах.
Решение проблем с правами доступа (403 Forbidden для сайта, SSH-авторизация).

* Общее время работы: ~45 минут (включая отладку).
* Версия Ansible: 2.5.1+dfsg-1ubuntu0.1+esm5.
* Python: 3.6.9.
* Nginx: 1.14.0-0ubuntu1.11+esm1.

### 2. Подготовка окружения

#### 2.1. Обновление системы и активация ESM

Система обновлена для обеспечения безопасности и совместимости. ESM активирован для доступа к обновлениям до 2028 года.
Выполненные команды:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install ubuntu-advantage-tools -y
sudo ua attach C12Dfz3mDQmBbtie6q286kJLWXuV16
sudo pro status --all
sudo ua enable esm-apps && sudo ua enable esm-infra
sudo apt update
```
Вывод:

ESM включён: esm-apps enabled, esm-infra enabled.
Обновлено 157 пакетов (включая tar, sudo, openssh-server).

<img width="1496" height="640" alt="image" src="https://github.com/user-attachments/assets/edaeb80c-8101-4111-b8da-07ba4508e05f" />

[Скриншот: Вывод sudo pro status --all — подтверждение активации ESM].

#### 2.2. Установка зависимостей
Установлены необходимые пакеты для Ansible и задач:

```bash
sudo apt install ansible -y
sudo apt install openssh-server -y
sudo systemctl enable ssh --now
sudo ufw allow 80/tcp
sudo ufw allow 22/tcp
sudo ufw reload
```

Вывод:

Ansible установлен (версия 2.5.1).
SSH-сервер запущен и доступен.

<img width="1485" height="705" alt="image" src="https://github.com/user-attachments/assets/2bb675a2-dc44-484a-83a0-d5d6b768cc9f" />

[Скриншот: Вывод ansible --version и sudo systemctl status ssh].

#### 2.3. Создание структуры проекта и файлов

Создан проект ansible-playbooks/ с директориями files/, playbooks/, inventory/.
Файлы в files/:

mysite.conf: Конфигурация vhost (скопирован из задания).
site.tar.gz: Архив с index.html и style.css (создан через tar -czf).
deploy.pub: Публичный SSH-ключ (сгенерирован ssh-keygen -t ed25519).

Команды создания:

```bash
mkdir -p {playbooks,files,inventory}
cat > files/mysite.conf << 'EOF'  # Код конфига из задания
EOF
mkdir temp_site
cat > temp_site/index.html << 'EOF'  # HTML-код сайта
EOF
cat > temp_site/style.css << 'EOF'  # CSS
EOF
tar -czf files/site.tar.gz -C temp_site .
rm -rf temp_site
ssh-keygen -t ed25519 -C "deploy@ansible" -f ~/.ssh/deploy_key -N ""
cp ~/.ssh/deploy_key.pub files/deploy.pub
chmod 600 ~/.ssh/deploy_key
```

Проверка:

```bash
ls -l files/  # Все файлы присутствуют
tar -tzf files/site.tar.gz  # index.html, style.css
cat files/deploy.pub  # SSH-ключ
```

<img width="890" height="299" alt="image" src="https://github.com/user-attachments/assets/2240d417-e579-4724-ac38-7870cf4ebddc" />

[Скриншот: Вывод ls -l files/ и tar -tzf files/site.tar.gz].

### 3. Разработка и запуск playbook'ов

#### 3.1. Inventory и конфигурация Ansible

hosts.ini:
ini[webservers]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3

[webservers:vars]
ansible_user=zabudico
ansible.cfg:
ini[defaults]
inventory = inventory/hosts.ini
host_key_checking = False
retry_files_enabled = False
deprecation_warnings = False


Проверка:
```bash
ansible all -m ping
```

Вывод: localhost | SUCCESS => {"changed": false, "ping": "pong"}.

<img width="801" height="195" alt="image" src="https://github.com/user-attachments/assets/73128d0e-8678-4dd6-af59-5021a696b59f" />

[Скриншот: Вывод ansible all -m ping].

#### 3.2. Playbook 1: 01_static_site.yml

Код playbook'а (после исправлений YAML и путей):
```yaml
---
- name: Deploy static site with Nginx and unarchive
  hosts: webservers
  become: yes

  handlers:
    - name: Restart nginx
      systemd:
        name: nginx
        state: restarted

  tasks:
    - name: 1. Install and start nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      notify: Restart nginx
      when: ansible_distribution == 'Ubuntu' and ansible_distribution_version == '18.04'

    - name: Ensure nginx is enabled and running
      systemd:
        name: nginx
        enabled: yes
        state: started

    - name: 2. Create site directory /var/www/mysite
      file:
        path: /var/www/mysite
        state: directory
        mode: '0755'
        owner: www-data
        group: www-data

    - name: 3. Unarchive site files to /var/www/mysite
      unarchive:
        src: ../files/site.tar.gz
        dest: /var/www/mysite
        remote_src: no
        mode: '0644'
        owner: www-data
        group: www-data
      notify: Restart nginx

    - name: 4. Copy nginx vhost config
      copy:
        src: ../files/mysite.conf
        dest: /etc/nginx/sites-available/mysite.conf
        mode: '0644'
      notify: Restart nginx

    - name: Activate vhost by creating symlink
      file:
        src: /etc/nginx/sites-available/mysite.conf
        dest: /etc/nginx/sites-enabled/mysite.conf
        state: link
      notify: Restart nginx

    - name: Remove default nginx config
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: Restart nginx
```

Запуск:

```bash
ansible-playbook playbooks/01_static_site.yml --check -vvv  # Dry-run
ansible-playbook playbooks/01_static_site.yml -vvv  # Полный запуск
```

Результаты:

Task                    Статус     Изменения
Install nginx           Changed    Установлен Nginx 1.14.0.
Ensure enabled          Changed    Служба запущена.
Create /var/www/mysite  Changed    Директория создана.
Unarchive site.tar.gz   Changed    Файлы распакованы.
Copy mysite.conf        Changed    Конфиг скопирован. 
Activate symlink        Changed    Symlink создан.
Remove default          Changed    Default удалён.
Restart nginx           Changed    Перезапуск.

Проблемы и исправления:

* Ошибка путей: Исправлено на ../files/.
* 403 Forbidden: Исправлено правами chown -R www-data:www-data /var/www/mysite.

Вывод ansible-playbook 01_static_site.yml -vvv (успешный запуск)

#### 3.3. Playbook 2: 02_deploy_user.yml

Код playbook'а (после исправлений):

```yaml
---
- name: Setup deploy user with SSH key and sudoers
  hosts: webservers
  become: yes

  tasks:
    - name: 1. Create deploy user and add to sudo group
      user:
        name: deploy
        groups: sudo
        append: yes
        state: present
        create_home: yes
        shell: /bin/bash

    - name: Create .ssh directory for deploy
      file:
        path: /home/deploy/.ssh
        state: directory
        mode: '0700'
        owner: deploy
        group: deploy

    - name: 2. Add SSH public key to authorized_keys
      authorized_key:
        user: deploy
        state: present
        key: "{{ lookup('file', '../files/deploy.pub') }}"

    - name: 3. Create sudoers drop-in file
      copy:
        dest: /etc/sudoers.d/deploy
        content: |
          deploy ALL=(ALL) NOPASSWD:ALL
        mode: '0440'
        validate: /usr/sbin/visudo -cf %s

    - name: 4. Check sudoers syntax
      command: /usr/sbin/visudo -cf /etc/sudoers.d/deploy
      register: visudo_result
      changed_when: false
      ignore_errors: yes

    - name: Remove sudoers file if syntax check failed
      file:
        path: /etc/sudoers.d/deploy
        state: absent
      when: visudo_result.rc != 0
```

Запуск:

```bash
ansible-playbook playbooks/02_deploy_user.yml --check -vvv  # Dry-run
ansible-playbook playbooks/02_deploy_user.yml -vvv  # Полный запуск
```

Результаты:

Task                          Статус               Изменения 
Create user deploy            OK                   Пользователь создан (UID 1006).
Create .ssh dir               OK                   Директория создана.
Add key to authorized_keys    Changed              Ключ добавлен. 
Create sudoers                Changed              Файл создан, проверен.
Check syntax                  OK                   parsed OK.
Remove if failed              Skipped              Не нужно.

Проблемы и исправления:

* Ошибка lookup: Исправлено на ../files/deploy.pub.
* Ошибка conditional: Убрано из-за skip в check mode.

Вывод ansible-playbook 02_deploy_user.yml -vvv (успешный запуск)

### 4. Верификация результатов
#### 4.1. Проверка сайта

* Доступ: curl http://localhost — возвращает HTML с "Привет от Ansible!".
* Лог: sudo tail /var/log/nginx/mysite_access.log — фиксирует запросы.
* Статус Nginx: sudo systemctl status nginx — active (running).

<img width="1058" height="372" alt="image" src="https://github.com/user-attachments/assets/cda7eccb-5bb6-4712-9a54-44b9651c9077" />

[Скриншот: Вывод curl http://localhost и sudo tail /var/log/nginx/mysite_access.log].

#### 4.2. Проверка пользователя deploy

```bash
SSH: ssh -i ~/.ssh/deploy_key deploy@localhost — успешное подключение.
Sudo: sudo -u deploy sudo whoami — root без пароля.
Sudoers: sudo cat /etc/sudoers.d/deploy — правило применено.
Authorized keys: sudo cat /home/deploy/.ssh/authorized_keys — ключ присутствует.
```

<img width="1056" height="855" alt="image" src="https://github.com/user-attachments/assets/5e0a6023-7456-43f0-a4a7-6635a32ab806" />

<img width="655" height="82" alt="image" src="https://github.com/user-attachments/assets/61a1bfac-181c-46d5-b725-39e1850480e3" />

[Скриншот: Вывод SSH-подключения и sudo whoami].

#### 4.3. Общая проверка системы

* Ping Ansible: ansible all -m ping — pong.
* UFW: Порты 80/22 открыты.
* Обновления: Система актуальна (ESM включён).

<img width="1281" height="541" alt="image" src="https://github.com/user-attachments/assets/3c71825f-fb7e-4ad9-9d45-68c191c7d147" />

[Скриншот: Вывод sudo pro status --all].

### 5. Выводы

Успех: Оба playbook'а работают идемпотентно (повторный запуск не меняет состояние). Сайт обслуживается, пользователь готов к деплою.

Время: ~45 минут (включая отладку YAML и прав).

#### Улучшения:

* Добавить переменные в group_vars/ для кастомизации (e.g., имя пользователя).
* Интегрировать с Git для версионирования.
* Тестировать на удалённом сервере (изменить hosts.ini на IP).

#### Рекомендации по безопасности:

Удалить NOPASSWD:ALL после тестирования (заменить на конкретные команды).
Включить UFW: sudo ufw --force enable.
Мониторинг: sudo tail -f /var/log/nginx/mysite_error.log.

                                                                                                                                                                          Подпись: Zabudico A
                                                                                                                                                                                
                                                                                                                                                                          Дата: 20 октября 2025 года



