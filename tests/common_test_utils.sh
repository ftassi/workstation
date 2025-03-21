#!/bin/bash

log_info() {
  echo -e "\033[0;34m[INFO]\033[0m $1"
}

log_success() {
  echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $1"
}

start_test_container() {
  local image="${1:-ubuntu:24.04}"
  if [ $# -gt 0 ]; then
    shift
    local command="$*"
  else
    local command="sleep infinity"
  fi

  log_info "Avvio container $image con comando: $command"
  docker run --network=host --name test-container --rm -d -v "${REPO_DIR:-$(pwd)}:/workstation" "$image" bash -c "$command"

  export CONTAINER_NAME="test-container"
  export CONTAINER_IMAGE="$image"
}

assert_package_installed() {
  local package=$1
  local container=${2:-$CONTAINER_NAME}
  if docker exec $container dpkg -l "$package" | grep -q "^ii"; then
    log_success "✅ Pacchetto $package è stato installato correttamente"
    return 0
  else
    log_error "❌ Pacchetto $package NON è stato installato"
    return 1
  fi
}

assert_binary_exists() {
  local binary=$1
  local container=${2:-$CONTAINER_NAME}
  if docker exec $container bash -c "command -v $binary &>/dev/null"; then
    log_success "✅ Binario $binary esiste ed è eseguibile"
    return 0
  else
    log_error "❌ Binario $binary NON esiste o non è eseguibile"
    return 1
  fi
}

assert_file_exists() {
  local file=$1
  local container=${2:-$CONTAINER_NAME}
  if docker exec $container bash -c "test -f $file"; then
    log_success "✅ File $file esiste"
    return 0
  else
    log_error "❌ File $file NON esiste"
    return 1
  fi
}

assert_directory_exists() {
  local directory=$1
  local container=${2:-$CONTAINER_NAME}
  if docker exec $container bash -c "test -d $directory"; then
    log_success "✅ Directory $directory esiste"
    return 0
  else
    log_error "❌ Directory $directory NON esiste"
    return 1
  fi
}

assert_file_permissions() {
  local file=$1
  local expected_perms=$2
  local container=${3:-$CONTAINER_NAME}
  local actual_perms
  
  actual_perms=$(docker exec $container bash -c "stat -c '%a' $file")
  
  if [ "$actual_perms" = "$expected_perms" ]; then
    log_success "✅ File $file ha i permessi corretti ($expected_perms)"
    return 0
  else
    log_error "❌ File $file ha permessi errati: $actual_perms invece di $expected_perms"
    return 1
  fi
}

assert_no_duplicate_lines() {
  local file=$1
  local container=${2:-$CONTAINER_NAME}
  local num_lines
  local num_unique_lines
  
  num_lines=$(docker exec $container bash -c "grep -v '^#' $file | grep -v '^$' | wc -l")
  num_unique_lines=$(docker exec $container bash -c "grep -v '^#' $file | grep -v '^$' | sort | uniq | wc -l")
  
  if [ "$num_lines" -eq "$num_unique_lines" ]; then
    log_success "✅ File $file non contiene linee duplicate"
    return 0
  else
    log_error "❌ File $file contiene linee duplicate: $((num_lines - num_unique_lines)) righe doppie"
    docker exec $container bash -c "grep -v '^#' $file | grep -v '^$' | sort | uniq -d" || true
    return 1
  fi
}

assert_apt_repository_added_once() {
  local repo_pattern=$1
  local container=${2:-$CONTAINER_NAME}
  local count
  
  count=$(docker exec $container bash -c "grep -r \"$repo_pattern\" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | wc -l")
  
  if [ "$count" -eq 1 ]; then
    log_success "✅ Repository $repo_pattern è stato aggiunto correttamente (una volta)"
    return 0
  elif [ "$count" -eq 0 ]; then
    log_error "❌ Repository $repo_pattern non è stato aggiunto"
    return 1
  else
    log_error "❌ Repository $repo_pattern è stato aggiunto più volte ($count occorrenze)"
    docker exec $container bash -c "grep -r \"$repo_pattern\" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null" || true
    return 1
  fi
}

