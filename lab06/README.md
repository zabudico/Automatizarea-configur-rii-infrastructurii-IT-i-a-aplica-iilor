# Лабораторная работа: Простое развертывание EC2 и S3 на AWS с Terraform

## Цель работы
Научиться создавать базовую инфраструктуру на AWS с помощью Terraform, включая виртуальную машину (EC2) и S3-бакет, используя переменные и выходные данные, а также безопасно хранить состояние в S3.

## Выполненные задачи

### 1. Инфраструктура Terraform
- Создана VPC с публичными и приватными подсетами
- Настроены Security Groups
- Развернут EC2 instance с веб-сервером

### 2. Amazon RDS MySQL
- Создан master instance `project-rds-mysql-prod`
- Создана read replica `project-rds-mysql-read-replica`
- Настроена репликация между instances

### 3. База данных
- Созданы таблицы `categories` и `todos` (связь 1 ко многим)
- Добавлены тестовые данные
- Проверена работа JOIN запросов

### 4. Read Replica
- ✅ Проверено чтение данных с replica
- ✅ Проверена ошибка записи на replica (read-only)
- ✅ Проверена синхронизация данных после записи в master

### 5. Веб-приложение
- Реализовано разделение: чтение с replica, запись в master
- Интерфейс для управления задачами
- Автоматическое обновление данных

### 6. Amazon DynamoDB
- Создана таблица `Lab5Todos` с on-demand capacity
- Реализована интеграция через AWS SDK для PHP
- Настроен доступ через IAM роль EC2

## Контрольные вопросы

### 1. Зачем нужны Read Replicas?
Read Replicas позволяют масштабировать чтение, распределять нагрузку и повышать доступность.

### 2. Преимущества DynamoDB vs RDS
**DynamoDB:**
- Горизонтальное масштабирование
- Предсказуемая производительность
- NoSQL - гибкая схема данных

**RDS:**
- SQL и сложные запросы
- Транзакции и ACID
- Связи между таблицами

### 3. Сценарий совместного использования
- **RDS:** пользователи, заказы, транзакционная data
- **DynamoDB:** сессии, кэш, журналирование, метрики

## Скриншоты

<img width="1817" height="811" alt="image" src="https://github.com/user-attachments/assets/f67f20aa-bf73-48ff-b15d-5c034202d8e2" />

<img width="892" height="564" alt="image" src="https://github.com/user-attachments/assets/69214609-7d0e-4b24-8ba5-dc101e8f8ca3" />

<img width="806" height="615" alt="image" src="https://github.com/user-attachments/assets/c2d81ad8-0977-4a55-a4b8-76048d13cd18" />

<img width="895" height="843" alt="image" src="https://github.com/user-attachments/assets/2ae5f26e-a85b-49d1-a0e8-35e41dc85de8" />

<img width="904" height="423" alt="image" src="https://github.com/user-attachments/assets/65ad86cf-02d2-497b-a9a2-8c811fa8be9d" />

<img width="1826" height="1060" alt="image" src="https://github.com/user-attachments/assets/60b2dabd-1b2f-4643-9bbe-bc045c131b06" />

## Вывод
Лабораторная работа успешно выполнена. Освоены ключевые сервисы AWS для работы с базами данных.

