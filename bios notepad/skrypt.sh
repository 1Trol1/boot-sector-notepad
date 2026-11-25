#!/bin/bash

# Sprawdź, czy skrypt został uruchomiony z uprawnieniami root'a
if [ "$EUID" -ne 0 ]; then
  echo "[-] Uruchom ten skrypt z sudo: sudo $0 /dev/sdb"
  exit 1
fi

# Sprawdzanie argumentu (nazwy urządzenia)
if [ -z "$1" ]; then
  echo "[-] Błąd: Nie podano urządzenia!"
  echo "Użycie: sudo $0 /dev/sdb"
  exit 1
fi

DEVICE=$1
OUTPUT_FILE="notatki_z_pendrive.txt"
SECTORS_TO_READ=64   # Liczba sektorów do odczytu (64 * 512 bajtów = 32 KB tekstu)

echo "[*] Odczytuję $SECTORS_TO_READ sektorów z $DEVICE (pomijając MBR)..."

# 1. dd pomija sektor 0 (skip=1) i czyta określoną liczbę sektorów
# 2. tr -d '\0' usuwa bajty zerowe, żeby plik tekstowy był czysty
sudo dd if="$DEVICE" bs=512 skip=1 count="$SECTORS_TO_READ" 2>/dev/null | tr -d '\0' > "$OUTPUT_FILE"

echo "[+] Gotowe! Dane zapisano do pliku: $OUTPUT_FILE"
echo "--- Podgląd zawartości pliku ---"
cat "$OUTPUT_FILE"
echo "--------------------------------"
