#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script requires superuser privileges. Please run with sudo or as root."
  exit 1
fi

# Log file
LOG_FILE="/var/log/user_management.log"
SECURE_DIR="/var/secure"
PASSWORD_FILE="$SECURE_DIR/user_passwords.csv"

# Create secure directory if it doesn't exist
mkdir -p "$SECURE_DIR"
chmod 700 "$SECURE_DIR"

# Clear the log and password files
true > "$LOG_FILE"
true > "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Function to generate random passwords for users
generate_random_password() {
    local password_length=15
    tr -dc A-Za-z0-9 </dev/urandom | head -c "$password_length" #Double quotes to prevent globbing and word splitting
}

# Read the Input file line by line
while IFS=';' read -r username groups; do

    # Remove leading or trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Skip empty lines
    [ -z "$username" ] && continue

    # Create user with home directory and personal group
    if id "$username" &>/dev/null; then
        echo "User $username already exists, skipping..." | tee -a "$LOG_FILE"
    else
        useradd -m -s /bin/bash "$username" # Create user with home directory, set default shell, create personal group
        echo "Created user $username with personal group $username" | tee -a "$LOG_FILE"
    fi

    # Add user to additional groups if specified
    if [ -n "$groups" ]; then
        IFS=',' read -ra ADDR <<<"$groups" # Set the IFS to split groups into an array (ADDR)

        # Iterate over each group name in the array
        for group in "${ADDR[@]}"; do
            group=$(echo "$group" | xargs) # Removes leading or trailing whitespace

            # Check if a group does not exist, creates it if it doesn't
            if ! getent group "$group" >/dev/null; then
                groupadd "$group" # Create the group
                echo "Created group $group" | tee -a "$LOG_FILE"
            fi

            usermod -aG "$group" "$username" # Add the user to the specified group
            echo "Added user $username to group $group" | tee -a "$LOG_FILE"
        done
    fi

    # Set home directory permissions
    chmod 700 "/home/$username"
    chown "$username":"$username" "/home/$username"
    echo "Set permissions for /home/$username" | tee -a "$LOG_FILE"

    # Generate and store the user's password
    password=$(generate_random_password)
    echo "$username,$password" >> "$PASSWORD_FILE" # Append the username and password to the password file
    echo "Generated password for user $username" | tee -a "$LOG_FILE"
    echo "$username:$password" | chpasswd # Set the paasword for the user to the generated password

done < "$1"

echo "User creation process completed" | tee -a "$LOG_FILE"