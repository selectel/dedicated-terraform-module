#!/usr/bin/env python3
"""
Скрипт для получения данных о доступных локациях и конфигурациях серверов Selectel.

Запрашивает публичное API и сохраняет результаты в JSON-файлы:
- locations.json
- servers.json
"""

import json
import requests
from typing import List, Dict, Any

# URL API
LOCATION_URL = "https://api.selectel.ru/servers/v2/pub/location"
SERVICE_URL_SERVER = "https://api.selectel.ru/servers/v2/pub/service/server"
SERVICE_URL_SERVERCHIP = "https://api.selectel.ru/servers/v2/pub/service/serverchip"
PLAN_URL = "https://api.selectel.ru/servers/v2/pub/plan"

PLAN_UUID_TO_NAME = {}
LOCATION_UUID_MAP = {}

def fetch_locations() -> List[Dict[str, Any]]:
    print("Получаю список локаций...")
    response = requests.get(LOCATION_URL)
    response.raise_for_status()
    data = response.json()

    locations = []
    for item in data.get("result", []):
        # Фильтруем по visibility
        if item.get("visibility") != "everywhere":
            continue
        location = {
            "uuid": item["uuid"],
            "name": item["name"]
        }
        locations.append(location)
        LOCATION_UUID_MAP[item["uuid"]] = item["name"]

    print(f"Найдено {len(locations)} локаций (с visibility=everywhere).")
    return locations

def fetch_plans() -> Dict[str, str]:
    response = requests.get(PLAN_URL)
    response.raise_for_status()
    data = response.json()

    plans = {}
    for item in data.get("result", []):
        uuid = item["uuid"]
        name = item["name"]
        if item.get("not_available_for_a_reason") is not None:
            continue
        plans[uuid] = name

    return plans

def fetch_servers_from_url(url: str, model_filter: str) -> List[Dict[str, Any]]:
    headers = {
        "X-Filter-is_hidden": "false",
        "X-Filter-state": "Active",
    }

    response = requests.get(url, headers=headers)
    response.raise_for_status()
    data = response.json()

    servers = []
    for item in data.get("result", []):
        if item.get("is_hidden") or item.get("state") != "Active" or item.get("model") != model_filter:
            continue

        available_map = {}
        total_count = 0  # Для проверки, есть ли хоть где-то доступность

        for avail in item.get("available", []):
            loc_uuid = avail["location"]
            loc_name = LOCATION_UUID_MAP.get(loc_uuid)
            if loc_name and avail["count"] > 0:
                available_map[loc_name] = avail["count"]
                total_count += avail["count"]

        if total_count == 0:
            continue

        # Собираем цены RUB из price_collection
        price_rub_map = {}
        rub_prices = item.get("price_collection", {}).get("RUB", {})

        # Сопоставление ключей из price_collection.RUB с именами планов
        price_key_to_plan_name = {
            "day": "1 day",
            "month": "1 month",
            "year": "1 year",
            "hour": "1 hour",
        }

        for price_key, plan_name in price_key_to_plan_name.items():
            if plan_name in PLAN_UUID_TO_NAME.values():
                price = rub_prices.get(price_key)
                if price is not None:
                    price_rub_map[plan_name] = price

        # Собираем hardware
        hardware = {
            "cpu": item.get("cpu"),
            "ram": item.get("ram"),
            "disk": item.get("disk"),
            "gpu": item.get("gpu")
        }

        server = {
            "uuid": item["uuid"],
            "name": item["name"],
            "available": available_map,
            "price_RUB": price_rub_map,
            "harware": hardware  # Оставлено как в ТЗ
        }
        servers.append(server)

    return servers

def fetch_all_servers() -> List[Dict[str, Any]]:
    """Объединяет результаты fetch_servers_from_url для 'server' и 'serverchip'."""
    servers_server = fetch_servers_from_url(SERVICE_URL_SERVER, "server")
    servers_serverchip = fetch_servers_from_url(SERVICE_URL_SERVERCHIP, "serverchip")
    all_servers = servers_server + servers_serverchip
    print(f"Всего серверов (server + serverchip): {len(all_servers)}")
    return all_servers

def save_json(data: Any, filename: str):
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Файл {filename} сохранён.")

def main():
    global PLAN_UUID_TO_NAME
    try:
        locations = fetch_locations()
        save_json(locations, "locations.json")

        PLAN_UUID_TO_NAME = fetch_plans()

        servers = fetch_all_servers()
        save_json(servers, "servers.json")

    except requests.exceptions.RequestException as e:
        print(f"Ошибка при запросе к API: {e}")
    except Exception as e:
        print(f"Ошибка: {e}")

if __name__ == "__main__":
    main()
