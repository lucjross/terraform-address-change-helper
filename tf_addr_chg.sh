#!/bin/sh
set -e

current_addr_prefix=$1
new_addr_prefix=$2

ere_quote() {
    echo "$*" | sed 's/[][\.|$(){}?+*^]/\\&/g'
}

if [ -z "$current_addr_prefix" ] || [ -z "$new_addr_prefix" ]; then
  echo "Usage: tf_addr_chg.sh <current address prefix> <new address prefix>"
  exit 1
fi

current_resources=$(terraform state list | grep -E "^$current_addr_prefix")
if [ -z "$current_resources" ]; then
  echo "No resources with address starting with $current_addr_prefix"
  exit 0
fi

plan=$(terraform plan -no-color) # colors add control characters to the output that make it difficult to grep
ere_addr_prefix=$(ere_quote "$current_addr_prefix")
ere_new_addr_prefix=$(ere_quote "$new_addr_prefix")
current_plan_lines=$(echo "$plan" | { grep -E "^[[:space:]]*#[[:space:]]${ere_addr_prefix}(?:\.[A-Za-z0-9_\-]+)+" || test $? = 1; })
if [ -z "$current_plan_lines" ]; then
  echo "The plan doesn't reference any resources starting with $current_addr_prefix"
  exit 1
fi
cmd=""
trap 'rm /tmp/plan_lines' EXIT INT; mkfifo /tmp/plan_lines
echo "$current_plan_lines" > /tmp/plan_lines &
while IFS= read -r line; do
  addr=$(echo "$line" | grep -Eo "${ere_addr_prefix}[A-Za-z0-9_\-\.]+" )
  if echo "$line" | grep -qE 'will be destroyed$'; then
    new_addr=$(echo "$addr" | sed "s/${ere_addr_prefix}/${ere_new_addr_prefix}/")
    new_addr_line=$(echo "$plan" | grep -E "^[[:space:]]*#[[:space:]]${new_addr}")
    if echo "$new_addr_line" | grep -qE 'will be created$'; then
      if [ -n "$cmd" ]; then
        cmd=$(printf "%s \\" "$cmd")
        cmd=$(printf "%s\n  && " "$cmd")
      fi
      cmd=$(printf "%sterraform state mv %s %s" "$cmd" "$addr" "$new_addr")
    else
      echo "The plan doesn't involve creating resource $new_addr"
      exit 1
    fi
  else
    echo "The plan doesn't involve destroying resource $addr"
    exit 1
  fi
done < /tmp/plan_lines

printf "The following command will be run:\n\n%s\n\nEnter 'yes' to continue: " "$cmd"
read ok
printf "\n"
if [ "$ok" != "yes" ]; then
  exit 0
fi

eval "$cmd"
exit 0
