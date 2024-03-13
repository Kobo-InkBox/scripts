#!/bin/bash
icho "Loading remote functions"

function upload_file() {
    local local_file="$1"
    local remote_path="$2"

    if [ -z "$local_file" ] || [ -z "$remote_path" ]; then
        echo "Usage: upload_file <local_file> <remote_path>"
        return 1
    fi

    sshpass -p "$INKBOX_PASSWORD" scp "$local_file" "$INKBOX_USERNAME@$INKBOX_IP:$remote_path"

    if [ $? -eq 0 ]; then
        icho "$local_file successfully uploaded to $INKBOX_IP:$remote_path"
    else
        icho "Error uploading file. Check the credentials (or ssh key conflicts) and try again."
    fi
}

function exec_remote_rootfs() {
    local command_to_execute="$1"

    if [ -z "$command_to_execute" ]; then
        echo "Usage: execute_remote_command <command>"
        return 1
    fi

    sshpass -p "$INKBOX_PASSWORD" ssh -t -q "$INKBOX_USERNAME@$INKBOX_IP" "$command_to_execute"

    if [ $? -eq 0 ]; then
        icho "$command_to_execute executed successfully on $INKBOX_IP for rootfs"
    else
        icho "Error executing $command_to_execute. Check the credentials, syntax and try again."
    fi
}

function exec_remote_gui() {
    local command_to_execute="$1"

    if [ -z "$command_to_execute" ]; then
        echo "Usage: execute_remote_command <command>"
        return 1
    fi

    sshpass -p "$INKBOX_PASSWORD" ssh -t -q "$INKBOX_USERNAME@$INKBOX_IP" "chroot /kobo /bin/sh -c '$command_to_execute'"

    if [ $? -eq 0 ]; then
        icho "$command_to_execute executed successfully on $INKBOX_IP for gui"
    else
        icho "Error executing $command_to_execute. Check the credentials, syntax and try again."
    fi
}

function login_inkbox() {
    sshpass -p "$INKBOX_PASSWORD" ssh "$INKBOX_USERNAME@$INKBOX_IP"
}

function sshfs_inkbox() {
    sshfs_path="/mnt/inkbox"
    if [ -z "$(ls -A $sshfs_path 2>/dev/null)" ]; then
        sudo mkdir -p $sshfs_path
        sudo chown $USER:$USER $sshfs_path
    fi
    # sshpass won't work here
    sshfs "$INKBOX_USERNAME@$INKBOX_IP:/" $sshfs_path
}

function prepare_inkbox() {
    exec_remote_rootfs "echo true > /boot/flags/USBNET_ENABLE"
    exec_remote_rootfs "echo true > /boot/flags/RW_ROOTFS"
    exec_remote_rootfs "echo true > /boot/flags/INITRD_DEBUG"
    exec_remote_rootfs "echo true > /boot/flags/GUI_DEBUG"
    exec_remote_rootfs "echo true > /boot/flags/IPD_DEBUG"
    exec_remote_rootfs "reboot"
}