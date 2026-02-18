#!/usr/bin/env bash
set -euo pipefail

CUPS_URL="http://localhost:631"
AIRPRINT_SERVICE="/etc/avahi/services/airprint.service"

open_cups() {
  echo
echo "CUPS is available at: http://localhost:631"
echo "Open this URL in your browser when ready."
}

restart_services() {
  sudo systemctl restart cups avahi-daemon
}

prompt_continue() {
  echo
  echo "CUPS is open at $CUPS_URL"
  echo "Press ENTER when finished in the browser..."
  read -r
}

prompt_printer_name() {
  echo
  read -rp "Enter your exact CUPS printer queue name: " PRINTER_NAME
  if [[ -z "$PRINTER_NAME" ]]; then
    echo "Printer name cannot be empty."
    exit 1
  fi
}

create_airprint_service() {
  sudo tee "$AIRPRINT_SERVICE" >/dev/null <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">AirPrint %h</name>
  <service>
    <type>_ipp._tcp</type>
    <subtype>_universal._sub._ipp._tcp</subtype>
    <port>631</port>
    <txt-record>txtvers=1</txt-record>
    <txt-record>qtotal=1</txt-record>
    <txt-record>Transparent=T</txt-record>
    <txt-record>URF=none</txt-record>
    <txt-record>rp=printers/${PRINTER_NAME}</txt-record>
  </service>
</service-group>
EOF
}

main() {
  open_cups
  prompt_continue

  restart_services

  open_cups
  prompt_continue

  prompt_printer_name

  echo "Writing AirPrint service for printer: $PRINTER_NAME"
  create_airprint_service

  restart_services
  echo "Done."
}

main "$@"