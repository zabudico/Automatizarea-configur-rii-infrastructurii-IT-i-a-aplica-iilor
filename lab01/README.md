# Отчёт о проделанной работе

## Установка виртуальной машины и Ubuntu на Mac и Windows

**Выполнил:** [Zabudico Alexandr]  
**Дата:** [14.09.2025]

---

### Цель работы

Установить операционную систему Ubuntu на виртуальные машины на платформе:

- Windows (с использованием VirtualBox)

---

## 📋 Выполненные этапы

### 1. Установка Ubuntu на Windows через VirtualBox

#### 🔹 Установка VirtualBox

- Скачан установщик с [официального сайта](https://www.virtualbox.org/wiki/Downloads)
- Выполнена установка с настройками по умолчанию
- VirtualBox успешно запущен

#### 🔹 Загрузка ISO-образа Ubuntu

- Загружен образ Ubuntu Desktop 22.04 LTS с [официального сайта](https://ubuntu.com/download/desktop)

#### 🔹 Создание виртуальной машины

- Создана ВМ с именем «Ubuntu» (тип: Linux, версия: Ubuntu 64-bit)
- Выделено 4 ГБ оперативной памяти
- Создан динамический виртуальный диск размером 30 ГБ

#### 🔹 Настройка ВМ

- Назначено 2 ядра процессора
- Увеличена видеопамять до 128 МБ, включено 3D-ускорение
- В разделе «Носители» подключен загруженный ISO-образ Ubuntu

#### 🔹 Установка Ubuntu

- Запущена ВМ, выбран режим «Install Ubuntu»
- Выполнена настройка языка, часового пояса, пользователя и пароля
- Выбран тип установки «Erase disk and install Ubuntu»
- Установка завершена успешно, система перезагружена

#### 🔹 Установка Guest Additions

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
cd /media/$USER/VBox_GAs_*
sudo ./VBoxLinuxAdditions.run
sudo reboot
```
