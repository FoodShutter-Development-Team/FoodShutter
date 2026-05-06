#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/images"

IDS=(
  "1735190093635-d99b2e43224e"
  "1773005695004-96e8457656df"
  "1659690402718-ea07d943fd42"
  "1771161409360-e07e34e20c1b"
  "1609796570327-f2fe3127cf9a"
  "1731432593596-a4d14cc98a5d"
  "1771161409352-bae2f33a14a0"
  "1772494048070-9fd1d7aa3fde"
  "1770678724766-08268bbc61e2"
  "1746635732995-ab5c6118d5a7"
  "1661600128732-aa6099626b46"
  "1556742524-750f2ab99913"
  "1597490101653-8db754021a89"
  "1676478199790-7132da7bf35f"
  "1656318319598-63f8237c5759"
  "1544621678-f17b5b909559"
  "1770024529936-181df38b1a65"
  "1578727401711-e9fcd2fbf270"
  "1707897748442-cc3a48d31300"
  "1548323164-ea1cb76539e8"
)

i=1
for id in "${IDS[@]}"; do
  num=$(printf "%02d" "$i")
  out="meal_${num}.jpg"
  url="https://images.unsplash.com/photo-${id}?w=1280&q=80&fm=jpg"
  echo "[$num/20] $out"
  curl -sSL -o "$out" "$url"
  i=$((i+1))
done

echo
echo "Downloaded $(ls *.jpg | wc -l | tr -d ' ') images:"
ls -lh *.jpg
