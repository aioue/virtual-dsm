#!/bin/bash

# Docker environment variabeles
: ${HOST_SERIAL:=''}
: ${GUEST_SERIAL:=''}

permanent="DSM"
serialstart="2000"

IMG="/storage"
[ ! -d "$IMG" ] && echo "Storage folder (${IMG}) not found!" && exit 69

#If environment variabele not set fall back to file
if [ -z "$HOST_SERIAL" ]; then
  FILE="${IMG}/host.serial"
  if [ ! -f "$FILE" ]; then
    SERIAL="$(echo "$serialstart" | tr ' ' '\n' | sort -R | tail -1)$permanent"$(printf "%06d" $((RANDOM % 30000 + 1)))
    echo $SERIAL > "$FILE"
  fi
  HOST_SERIAL=$(cat "${FILE}")
fi

#If environment variabele not set fall back to file
if [ -z "$GUEST_SERIAL" ]; then
  FILE="${IMG}/guest.serial"
  if [ ! -f "$FILE" ]; then
    SERIAL="$(echo "$serialstart" | tr ' ' '\n' | sort -R | tail -1)$permanent"$(printf "%06d" $((RANDOM % 30000 + 1)))
    echo $SERIAL > "$FILE"
  fi
  GUEST_SERIAL=$(cat "${FILE}")
fi

CPU=$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) @ .*/\1/p' | sed ':a;s/  / /;ta' | sed s/"(R)"//g | sed s/"-"//g | sed 's/[^[:alnum:] ]\+//g')

if [ -n "$CPU" ]; then
  CPU="$CPU,,"
else
  CPU="QEMU, Virtual CPU, X86_64"
fi

./run/serial.bin -cpu="${CPU_CORES}" \
                -cpu_arch="${CPU}" \
                -buildnumber=42962 \
                -vmmts=1679863686 \
                -hostsn="${HOST_SERIAL}" \
                -guestsn="${GUEST_SERIAL}" \
                -vmmversion="2.6.1-12139" \
                -guestuuid="ba13a19a-c0c1-4fef-9346-915ed3b98341" > /dev/null 2>&1 &

KVM_SERIAL_OPTS="\
    -serial mon:stdio \
    -device virtio-serial-pci,id=virtio-serial0,bus=pcie.0,addr=0x3 \
    -chardev pty,id=charserial0 \
    -device isa-serial,chardev=charserial0,id=serial0 \
    -chardev socket,id=charchannel0,host=127.0.0.1,port=12345,reconnect=10 \
    -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=charchannel0,id=channel0,name=vchannel"
