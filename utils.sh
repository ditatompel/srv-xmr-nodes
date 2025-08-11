#!/bin/sh
# $HOME/.local/src/srv-xmr-nodes/utils.sh

set -e

SCRIPT_DIR=$(dirname -- "$0")
SCRIPT_DIR=$(cd -- "$SCRIPT_DIR" && pwd)

echo "$SCRIPT_DIR"

print_prog_desc()
{
  echo "Simple helper script to commit server configration to GitHub"
  echo
}

print_help()
{
  echo "Syntax: ${0} [-m 'your commit message'|-s|-h]"
  echo "options:"
  echo "-s                     Only [s]ync changes without commit."
  echo "-m 'Commit message'    Add your custom commit [m]essage."
  echo "-h                     Print this [h]elp."
  echo
}

COMMIT_MESSAGE="sync: $(date +'%Y-%m-%d %H:%M:%S')"

sync() {
  mkdir "${SCRIPT_DIR}/versions" -p
  mkdir "${SCRIPT_DIR}/etc/systemd/system" -p
  mkdir "${SCRIPT_DIR}/etc/monero" -p
  mkdir "${SCRIPT_DIR}/etc/nginx/conf.d" -p

  echo "Syncing monerod configs..."
  cp /etc/systemd/system/monerod-*.service \
    "${SCRIPT_DIR}/etc/systemd/system" --update
  rsync /etc/monero/ \
    "${SCRIPT_DIR}/etc/monero/" -av --delete
  /opt/monero/.local/bin/monerod --version > "${SCRIPT_DIR}/versions/monerod"

  echo "Syncing nginx configs..."
  cp /usr/lib/nginx/sites/*.xmr.ditatompel.com.conf \
    "${SCRIPT_DIR}/etc/nginx/conf.d" --update

  # Crontab
  crontab -l > "${SCRIPT_DIR}/crontab"
}

# `:` means "takes an argument", not "mandatory argument".
# That is, an option character not followed by `:` means a
# flag-style option (no argument), whereas an option
# character followed by `:` means an option with an argument.
# https://stackoverflow.com/questions/18414054/reading-optarg-for-optional-flags
while getopts ":hsm:" option; do
  case $option in
    h) # display Help
      print_prog_desc
      print_help
      exit;;
    s) # sync
      sync
      exit;;
    m) # custom commit message
      COMMIT_MESSAGE="$OPTARG"
      ;;
    \?) # invalid option
      echo "Invalid option!"
      print_help
      exit;;
  esac
done

sync

cd "${SCRIPT_DIR}"

git checkout automation
git add .
git commit -m "${COMMIT_MESSAGE}"
git push -u origin automation

# vim: set ts=2 sw=2 et:
