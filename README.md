# Управление выделенными серверами Selectel с помощью Terraform

Этот репозиторий содержит конфигурации Terraform для автоматизированного развертывания выделенных серверов (bare metal) в облаке Selectel. Он включает в себя переиспользуемый модуль для создания серверов, скрипт для получения актуальной информации о доступных конфигурациях и локациях, а также примеры использования.

## Структура репозитория

```
.
├── base_modules/                 # Базовые модули Terraform
│   └── baremetal-servers/        # Модуль для создания выделенного сервера
│       ├── main.tf               # Основная логика модуля
│       ├── outputs.tf            # Выводы модуля (ID, имя сервера)
│       ├── vars.tf               # Входные переменные модуля
│       └── versions.tf           # Требуемая версия провайдера
├── fetch-servers.py              # Python-скрипт для получения данных о серверах и локациях из публичного API Selectel
├── my-server1.tf                 # Пример конфигурации Terraform для сервера 1
├── my-server2.tf                 # Пример конфигурации Terraform для сервера 2
├── provider.tf                   # Конфигурация провайдера Selectel
├── terraform.tfvars              # Файл с переменными (рекомендуется использовать .tfvars)
├── user-data/                    # Директория с файлами user-data
│   ├── my-script.sh              # Пример bash-скрипта для user-data
│   └── my-user-data.yml          # Пример cloud-config для user-data
├── variables.tf                  # Объявление переменных для основного состояния
└── versions.tf                   # Требуемая версия Terraform и провайдеров
```

## Требования

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Python](https://www.python.org/downloads/) >= 3.6 (для `fetch-servers.py`)

## Установка и настройка

1.  **Клонируйте репозиторий:**
    ```bash
    git clone https://github.com/selectel/dedicated-terraform-module.git
    cd dedicated-terraform-module
    ```

2.  **Установите провайдер Selectel:**
    Запустите `terraform init` в корне репозитория. Terraform автоматически скачает и инициализирует требуемую версию провайдера `selectel/selectel` (v7.1.0), как указано в `versions.tf`.

3.  **Настройте аутентификацию Selectel:**
    Создайте файл `terraform.tfvars` (или используйте любой другой `.tfvars` файл) в корне репозитория и укажите свои учетные данные и информацию о проекте:

    ```hcl
    project_id  = "ВАШ_PROJECT_ID" # ID проекта в котором плнируете сделать заказ сервера
    domain_name = "ВАШ_DOMAIN_NAME" # ID аккаунта
    username    = "ВАШЕ_ИМЯ_ПОЛЬЗОВАТЕЛЯ" # Имя пользователя с доступом к проекту (my.selectel.ru > Account > Project > Users (Role - Member))
    password    = "ВАШ_ПАРОЛЬ" # Пароль пользователя
    auth_region = "ru-9" # или другой регион, если отличается
    auth_url    = "https://cloud.api.selcloud.ru/identity/v3/"
    ```

4.  **(Опционально) Обновите список доступных серверов и локаций:**
    Запустите Python-скрипт:
    ```bash
    python3 fetch-servers.py
    ```
    Это создаст файлы `locations.json` и `servers.json` с актуальной информацией о доступных локациях и конфигурациях серверов из публичного API Selectel.

## Использование

1.  **Настройте конфигурацию сервера:**
    Изучите примеры `my-server1.tf` и `my-server2.tf`. Создайте новый `.tf` файл (например, `my-new-server.tf`) и вызовите модуль `./base_modules/baremetal-servers`, передав ему необходимые параметры сервера в переменной `server`. Подробности о доступных параметрах смотрите в `./base_modules/baremetal-servers/vars.tf`.

    Пример минимальной конфигурации:
    ```hcl
    module "my_new_server" {
      source = "./base_modules/baremetal-servers"

      server = {
        project_id = var.project_id

        location_name        = "SPB-2"
        configuration_name   = "BL22-NVMe"
        os_name              = "Ubuntu"
        os_version_name      = "24.04 LTS"
        price_plan_name      = "1 day"
        os_host_name         = "my-new-server"
        ssh_key_name         = "my-ssh-key-name" # Или ssh_key = "ssh-rsa AAAA... user@example.com"
        # user_data          = "./user-data/my-init.yml" # Путь к файлу user-data
        # partitions_config  = { ... } # Конфигурация разметки диска (см. примеры)
      }
    }
    ```

2.  **Проверьте план:**
    ```bash
    terraform plan
    ```
    Terraform проанализирует вашу конфигурацию и покажет, какие ресурсы будут созданы, изменены или удалены.

3.  **Примените конфигурацию:**
    ```bash
    terraform apply
    ```
    Подтвердите выполнение, если план вас устраивает. Terraform создаст указанные ресурсы в Selectel.

4.  **Управление ресурсами:**
    - Для обновления конфигурации отредактируйте `.tf` файлы и снова выполните `terraform plan` и `terraform apply`.
    - Для удаления ресурса (например, `my_new_server`) выполните:
      ```bash
      terraform destroy -target=module.my_new_server
      ```
      Или удалите вызов модуля из `.tf` файла и выполните `terraform plan` и `terraform apply`, чтобы удалить все ресурсы в состоянии.

## Модуль `baremetal-servers`

Модуль `./base_modules/baremetal-servers` предоставляет гибкий способ создания выделенного сервера Selectel. Он позволяет:

- Выбирать локацию, конфигурацию и ОС по **имени** или **ID**.
- Указывать имя хоста, тарифный план, SSH-ключи, `user_data`.
- Настраивать разметку диска с использованием `soft_raid_config` и `disk_partitions`.
- Управлять `timeouts` и `lifecycle` поведением ресурса.
- Использовать `precondition` для проверки обязательных параметров.
- Игнорировать изменения в `user_data`, `ssh_key_name`, `ssh_key` после первоначального создания (через `lifecycle.ignore_changes`).

Входные параметры определены в `vars.tf` с использованием типа `object`, что делает передачу конфигурации сервера удобной и структурированной.
- [Документация к Terraform провайдеру](https://registry.terraform.io/providers/selectel/selectel/latest/docs/resources/dedicated_server_v1)

## Скрипт `fetch-servers.py`

- Запрашивает публичные эндпоинты Selectel для получения информации о:
    - Доступных локациях (`/pub/location`), фильтруя по `visibility = "everywhere"`.
    - Доступных конфигурациях серверов, фильтруя по `state = "Active"` и `is_hidden = false`, а также проверяя, что суммарная доступность (`count`) больше 0.
    - Доступных тарифных планах (`/pub/plan`).
- Сохраняет результаты в `locations.json` и `servers.json` в удобном для чтения формате.

## Важные замечания

- **Провайдер Selectel:** Используемая версия `selectel/selectel v7.1.0` может иметь особенности и ограничения. Убедитесь, что ваша конфигурация совместима с этой версией.
- **Безопасность:** Файлы `terraform.tfvars` содержат чувствительные данные (учетные данные). Убедитесь, что они **не попадают** в репозиторий Git (добавьте в `.gitignore`).
- **`lifecycle.ignore_changes`:** В модуле `baremetal-servers` установлено `ignore_changes` для `user_data`, `ssh_key_name`, `ssh_key`. Это означает, что изменения в этих параметрах после создания ресурса **не будут отслеживаться** Terraform и не приведут к его пересозданию или обновлению через `apply`. Изменения нужно вносить вручную или через другие средства.
- **Проверки (`precondition`):** Модуль включает проверки, которые останавливают выполнение `plan` или `apply`, если обязательные параметры (например, `location_id`, `configuration_id`, `os_id`) не могут быть разрешены.

