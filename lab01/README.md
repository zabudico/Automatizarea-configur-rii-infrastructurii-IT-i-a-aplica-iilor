# Установка виртуальной машины с Ubuntu на Windows

**Выполнил:** [Zabudico Alexandr]  
**Дата:** [14.09.2025]



### Цель работы

Установить операционную систему Ubuntu на виртуальные машины на платформе:

- Windows (с использованием VirtualBox)


## 📋 Выполненные этапы

### 1. Установка Ubuntu на Windows через VirtualBox

#### 🔹 Установка VirtualBox

- Скачан установщик с [официального сайта](https://www.virtualbox.org/wiki/Downloads)


<img width="561" height="216" alt="image" src="https://github.com/user-attachments/assets/4773fe58-265f-4605-a4ba-f078290cac26" />


- Выполнена установка с настройками по умолчани


<img width="774" height="613" alt="image" src="https://github.com/user-attachments/assets/3ca2549b-bc41-4c00-a35c-6f8a3b507400" />


- VirtualBox успешно запущен


<img width="974" height="639" alt="image" src="https://github.com/user-attachments/assets/1f589c9a-9241-4dce-a12e-41712980343a" />


#### 🔹 Загрузка ISO-образа Ubuntu

- Загружен образ Ubuntu Desktop 22.04 LTS с [официального сайта](https://ubuntu.com/download/desktop)


<img width="566" height="300" alt="image" src="https://github.com/user-attachments/assets/e161c930-3874-45ec-a699-db1a3c229016" />


#### 🔹 Создание виртуальной машины

- Создана ВМ с именем «linux_ubuntu» (тип: Linux, версия: Ubuntu 64-bit)


<img width="974" height="470" alt="image" src="https://github.com/user-attachments/assets/88b7ed1f-218c-44ce-89cb-f965c64d4154" />


- Выделено 4 ГБ оперативной памяти


<img width="974" height="470" alt="image" src="https://github.com/user-attachments/assets/bb16e3c0-8a56-4861-8a68-81ea496e2648" />


- Создан динамический виртуальный диск размером 25 ГБ

#### 🔹 Настройка ВМ

- Назначено 2 ядра процессора


<img width="974" height="544" alt="image" src="https://github.com/user-attachments/assets/9da996ac-8ac6-4d00-881b-c404637f2f19" />


- Увеличена видеопамять до 128 МБ, включено 3D-ускорение


<img width="974" height="578" alt="image" src="https://github.com/user-attachments/assets/08c2e1ee-3f6d-4bc0-be74-1eda96552bbd" />


- В разделе «Носители» подключен загруженный ISO-образ Ubuntu

#### 🔹 Установка Ubuntu

- Запущена ВМ, выбран режим «Install Ubuntu»
- Выполнена настройка языка, часового пояса, пользователя и пароля


<img width="974" height="665" alt="image" src="https://github.com/user-attachments/assets/882f9836-2b7f-4554-b0c3-6fc17575943a" />


- Выбран тип установки «Erase disk and install Ubuntu»
- Установка завершена успешно, система перезагружена


<img width="974" height="665" alt="image" src="https://github.com/user-attachments/assets/1b595705-4f77-47ae-9df1-bee3196fb2e0" />


<img width="974" height="644" alt="image" src="https://github.com/user-attachments/assets/57572ec6-1d9a-4b93-b898-266988d27bb9" />


#### 🔹 Установка Guest Additions


<img width="974" height="490" alt="image" src="https://github.com/user-attachments/assets/54962603-7570-4420-862d-0efe1f040965" />


```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
cd /media/$USER/VBox_GAs_*
sudo ./VBoxLinuxAdditions.run
sudo reboot
```

#### Виртуальная машина готова к использованию.

Результаты

- На Windows успешно установлена виртуальная машина с Ubuntu

- Настроены основные параметры производительности и интеграции

- Система готова к использованию для дальнейших задач


#### 🛠️ Использованные технологии
VirtualBox - виртуализация на Windows

Ubuntu 22.04 LTS - гостевая операционная система


## 🎯 Вывод

В результате проделанной работы были успешно достигнуты все поставленные цели:

### ✅ Достигнутые результаты:
- **Освоены технологии виртуализации** на платформе: VirtualBox для Windows
- **Созданы изолированные среды** для работы с Ubuntu без влияния на основную операционную систему
- **Настроена полная функциональность** виртуальных машин, включая сетевые подключения, общие папки и аппаратное ускорение

### 🔧 Приобретённые навыки:
- Работа с гипервизором (VirtualBox)
- Установка и настройка Linux-систем в виртуальной среде
- Установка дополнительного ПО для улучшения интеграции (Guest Additions)

### 💡 Практическая ценность:
Созданные виртуальные среды позволяют:
- Безопасно тестировать программное обеспечение
- Осваивать работу с Linux-системами
- Разрабатывать кроссплатформенные приложения
- Создавать изолированные среды для экспериментов

Работа подтвердила возможность эффективного использования виртуальных машин для создания универсальных сред разработки независимо от базовой операционной системы.
