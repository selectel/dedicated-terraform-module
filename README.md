# Управление выделенными серверами Selectel с помощью Terraform

Этот репозиторий содержит конфигурации Terraform для автоматизированного развертывания выделенных серверов (bare metal) в облаке Selectel. Он включает в себя переиспользуемый модуль для создания серверов с поддержкой гибкой разметки дисков, управления приватными сетями и встроенными проверками.

## Структура репозитория

```text
.
├── base_modules/                 
│   ├── baremetal-servers/        # Основной модуль для создания выделенного сервера
│   │   ├── main.tf               # Основная логика и ресурсы
│   │   ├── outputs.tf            # Выводы модуля (ID, IP-адреса, VLAN)
│   │   ├── vars.tf               # Входные переменные и валидации
│   │   └── versions.tf           # Требуемая версия провайдера
│   └── dedicated-private-subnet/ # (Опционально) Отдельный модуль для управления подсетями
├── my-server1.tf                 # Пример конфигурации Terraform для сервера 1
├── my-server2.tf                 # Пример конфигурации Terraform для сервера2
├── provider.tf                   # Конфигурация провайдера Selectel
├── terraform.tfvars              # Файл с переменными (не коммитить в Git!)
├── user-data/                    # Директория с файлами инициализации (cloud-init/bash)
│   ├── my-script.sh              
│   └── my-user-data.yml          
├── variables.tf                  # Объявление переменных для корневого модуля
└── versions.tf                   # Требуемая версия Terraform и провайдеров
```

## Требования

- [Terraform](https://www.terraform.io/downloads.html) >= 1.3 (для корректной работы `optional` в объектах)
- Провайдер `selectel/selectel` >= 8.0.0 (обязательно для поддержки новых параметров дисков и приватных сетей)

## Установка и настройка

1. **Клонируйте репозиторий:**
   ```bash
   git clone https://github.com/selectel/dedicated-terraform-module.git
   cd dedicated-terraform-module
   ```

2. **Настройте аутентификацию:**
   Создайте файл `terraform.tfvars` в корне репозитория и укажите свои учетные данные:
   ```hcl
   project_id  = "ВАШ_PROJECT_ID"       # ID проекта, в котором заказывается сервер
   domain_name = "ВАШ_DOMAIN_NAME"      # ID аккаунта
   username    = "ВАШЕ_ИМЯ_ПОЛЬЗОВАТЕЛЯ" # Пользователь с ролью Member в проекте
   password    = "ВАШ_ПАРОЛЬ"
   auth_region = "ru-9"                 # Регион авторизации
   auth_url    = "https://cloud.api.selcloud.ru/identity/v3/"
   ```
   > **Важно:** Файл `terraform.tfvars` содержит чувствительные данные. Убедитесь, что он добавлен в `.gitignore`.

3. **Инициализируйте Terraform:**
   ```bash
   terraform init
   ```

## Использование

1. **Настройте конфигурацию сервера:**
   Изучите примеры `my-server1.tf` и `my-server2.tf`. Вы можете создать свой файл (например, `my-new-server.tf`) и вызвать модуль `./base_modules/baremetal-servers`.

   Пример конфигурации с приватной подсетью и RAID:
   ```hcl
   module "my_new_server" {
     source = "./base_modules/baremetal-servers"

     server = {
       project_id         = var.project_id
       location_name      = "SPB-2"
       configuration_name = "BL22-NVMe"
       os_name            = "Ubuntu"
       os_version_name    = "24.04"
       price_plan_name    = "1 month"
       os_host_name       = "my-new-server"
       ssh_key_name       = "my-ssh-key"

       # Управление приватной сетью
       private_subnet_cidr   = "10.10.14.0/24"
       private_subnet_ip     = "10.10.14.105"
       private_vlan_id       = "3028"
       create_private_subnet = true # Создать подсеть, если её нет

       # Конфигурация дисков
       partitions_config = {
         soft_raid_configs = [
           {
             name      = "first-raid"
             level     = "raid1"
             disk_type = "SSD NVMe"
             count     = 2
           }
         ]
         disk_partitions = [
           {
             mount = "/boot"
             size  = 1
             raid  = "first-raid"
           },
           {
             mount = "/"
             size  = -1 # Использовать всё оставшееся пространство
             raid  = "first-raid"
           }
         ]
       }
     }
   }
   ```

2. **Проверьте и примените план:**
   ```bash
   terraform plan
   terraform apply
   ```

3. **Просмотр результатов:**
   После успешного применения модуль вернет структурированные данные о созданных серверах:
   ```hcl
   servers = {
     "my_new_server" = {
       "server_id"    = "2853d7ab-4dfe-4f3c-a392-4eb1ac9a5047"
       "server_name"  = "my-new-server"
       "public_ip"    = "95.213.143.162"
       "private_ip"   = "10.10.14.105"
       "private_vlan" = "3028"
     }
   }
   ```

## Параметры модуля (`server` object)

| Параметр | Тип | Описание |
|----------|-----|----------|
| `project_id` | `string` | **(Обязательно)** ID проекта Selectel. |
| `location_name` / `location_id` | `string` | Локация сервера (например, "SPB-2"). Можно указать имя или ID. |
| `configuration_name` / `configuration_id` | `string` | Конфигурация железа (например, "BL22-NVMe"). Можно указать имя или ID. |
| `os_name` / `os_id` | `string` | Операционная система. При использовании `os_name` рекомендуется указать `os_version_name`. |
| `price_plan_name` | `string` | Тарифный план ("1 month", "3 months", "6 months", "12 months"). |
| `os_host_name` | `string` | Hostname сервера. |
| `ssh_key_name` / `ssh_key` | `string` | Имя существующего ключа или содержимое публичного ключа. |
| `user_data` | `string` | Путь к файлу с cloud-config или bash-скриптом. |
| `os_password` | `string` | Пароль ОС (если не указан, будет сгенерирован случайный). |
| `private_subnet_cidr` | `string` | CIDR приватной подсети (например, "10.10.14.0/24"). |
| `private_subnet_ip` | `string` | Конкретный IP-адрес, который нужно выдать серверу в этой подсети. |
| `private_vlan_id` | `string` | ID VLAN для приватной подсети. |
| `create_private_subnet` | `bool` | Если `true`, модуль создаст подсеть, если она не найдена. По умолчанию `false`. |
| `private_subnet_id` | `string` | Явный ID существующей приватной подсети (имеет высший приоритет). |
| `add_private_vlan` | `bool` | Добавить "сырой" приватный VLAN без привязки к подсети. По умолчанию `false`. |
| `partitions_config` | `object` | Конфигурация дисков (см. пример ниже). |
| `force_update_additional_params` | `bool` | Если `true`, при изменении параметров ОС (диски, ключи, user-data) будет инициирована переустановка ОС (Reinstall). По умолчанию `false`. |
| `timeouts` | `object` | Таймауты операций `create`, `update`, `delete` (по умолчанию "60m"). |

### Структура `partitions_config`

```hcl
partitions_config = {
  # Опционально: конфигурация одиночных дисков без RAID
  disk_configs = [
    {
      name      = "system-disk"
      disk_type = "SSD NVMe"
    }
  ]

  # Опционально: конфигурация программных RAID-массивов
  soft_raid_configs = [
    {
      name      = "data-raid"
      level     = "raid1" # raid0, raid1, raid10
      disk_type = "HDD SATA"
      count     = 2       # Количество дисков в массиве
    }
  ]

  # Обязательно (если указан partitions_config): разделы дисков
  disk_partitions = [
    {
      mount        = "/"
      size         = -1          # Размер в GB (-1 = всё пространство)
      raid         = "data-raid" # Имя массива из soft_raid_configs (если используется RAID)
      disk_name    = "system-disk" # Имя диска из disk_configs (если RAID не используется)
      fs_type      = "ext4"      # ext4, ext3, xfs, swap
    }
  ]
}
```

## Выходные значения модуля (Outputs)

| Output | Описание |
|--------|----------|
| `server_id` | UUID созданного сервера в API Selectel. |
| `server_name` | Hostname сервера (`os_host_name`). |
| `public_ip` | Публичный IP-адрес сервера. |
| `private_ip` | Приватный IP-адрес сервера в указанной подсети. |
| `private_vlan` | ID VLAN приватной сети (берется из `private_vlan_id` или из созданной подсети). |

## Важные замечания

1. **Версия провайдера:** Модуль требует `selectel/selectel >= 8.0.0`. Убедитесь, что это указано в вашем `versions.tf`.
2. **`lifecycle.ignore_changes`:** В модуле настроено игнорирование изменений в `partitions_config`, `user_data`, `ssh_key`, `ssh_key_name` и `power_state`. Это сделано для предотвращения ложных срабатываний (дрейфа состояния), так как API Selectel может возвращать дополнительные атрибуты дисков после создания, а изменение этих параметров на работающем baremetal-сервере требует переустановки ОС. Будет исправленно в следующий версия провайдера.
3. **Переустановка ОС (Reinstall):** Если вам необходимо намеренно изменить разметку дисков, ключи или `user_data` на *уже созданном* сервере, установите `force_update_additional_params = true` в конфигурации сервера. Это даст провайдеру команду выполнить переустановку ОС с новыми параметрами.
4. **Приватные сети:** При использовании `private_subnet_cidr` модуль сначала ищет существующую подсеть в указанной локации. Если она не найдена, а `create_private_subnet = false`, выполнение будет остановлено с понятной ошибкой валидации (`precondition`).
5. **Безопасность:** Никогда не коммитьте `terraform.tfvars`, `*.tfstate` или файлы с приватными ключами в публичный репозиторий.

## Документация

- [Terraform Provider Selectel — dedicated_server_v1](https://registry.terraform.io/providers/selectel/selectel/latest/docs/resources/dedicated_server_v1)
- [Selectel API Documentation (Dedicated Servers)](https://docs.selectel.ru/cloud-servers/dedicated-servers/api/)
- [Cloud-init documentation](https://cloudinit.readthedocs.io/)
