# LINUX USER CREATION BASH SCRIPT

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)
![Made with Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)

## Introduction
This repository contains a step-by-step walkthrough of a project I recently worked on, where I needed to automate user management in Linux This project was one of the tasks for the HNG 11 internship, a program designed to accelerate learning and development in the tech industry.

[Read the Project Documentation](https://dev.to/databishop/smart-sysadmin-automating-user-management-on-linux-with-bash-scripts-57mc)

## Understanding the Requirements

**Overview:**
- Write a bash script called `create_users.sh`.
- The script reads a text file containing usernames and groups.
- Create users and groups as specified.
- Set up home directories with appropriate permissions and ownership.
- Generate random passwords for the users.
- Log all actions to `/var/log/user_management.log`.
- Store generated passwords securely in `/var/secure/user_passwords.csv`.

**Input Format:**
- Each line in the input file is formatted as `user;groups`.
- Multiple groups are separated by commas `,`.
- Usernames and groups are separated by a semicolon `;`.

**Criteria:**
- Users should be created and assigned to their groups.
- Logging actions to `/var/log/user_management.log`.
- Storing passwords in `/var/secure/user_passwords.csv`.

## Steps

### Step 1: Script Initialization

**Thought Process:**
- The script must be run with superuser (root) privileges to create users and groups.
- Initialize log and password storage files.

**Implementation:**
```bash
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
> "$LOG_FILE"
> "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"
```

### Step 2: Password Generation Function

**Thought Process:**
- We need a secure method to generate random passwords.
- Define a function that generates a random password of a specified length.

**Implementation:**
```bash
# Function to generate random passwords
generate_password() {
  local password_length=12
  tr -dc A-Za-z0-9 </dev/urandom | head -c $password_length
}
```

### Step 3: Reading and Processing the Input File

**Thought Process:**
- Read the input file line by line.
- Extract the username and groups.
- Handle whitespace properly to avoid errors.

**Implementation:**
```bash
# Read the input file line by line
while IFS=';' read -r username groups; do
  # Remove any leading or trailing whitespace
  username=$(echo "$username" | xargs)
  groups=$(echo "$groups" | xargs)

  # Skip empty lines
  [ -z "$username" ] && continue
```

### Step 4: User and Group Creation

**Thought Process:**
- Check if the user already exists. If not, create the user.
- Each user should have a personal group with the same name.
- Add the user to additional groups if specified.

**Implementation:**
```bash
  # Create user with a home directory and personal group
  if id "$username" &>/dev/null; then
    echo "User $username already exists, skipping..." | tee -a "$LOG_FILE"
  else
    useradd -m -s /bin/bash -G "$username" "$username" # Create user with home directory, set default shell, create personal group
    echo "Created user $username with personal group $username" | tee -a "$LOG_FILE"
  fi

  # Add user to additional groups if specified
  if [ -n "$groups" ]; then
    IFS=',' read -ra ADDR <<<"$groups" # Set the IFS to split groups into an array (ADDR)

    # Iterate over each group name in the array
    for group in "${ADDR[@]}"; do
      group=$(echo "$group" | xargs) # Remove leading or trailing whitespace
      if ! getent group "$group" >/dev/null; then
        groupadd "$group" # Create the group
        echo "Created group $group" | tee -a "$LOG_FILE"
      fi
      usermod -aG "$group" "$username" # Add the user to the specified group
      echo "Added user $username to group $group" | tee -a "$LOG_FILE"
    done
  fi
```

### Step 5: Setting Home Directory Permissions

**Thought Process:**
- Set appropriate permissions for the user's home directory.
- Ensure the user owns their home directory.

**Implementation:**
```bash
  # Set home directory permissions
  chmod 700 "/home/$username"
  chown "$username":"$username" "/home/$username"
  echo "Set permissions for /home/$username" | tee -a "$LOG_FILE"
```

### Step 6: Password Management

**Thought Process:**
- Generate a random password for the user.
- Store the password securely in the password file.
- Update the user's password.

**Implementation:**
```bash
  # Generate and store the user's password
  password=$(generate_password)
  echo "$username,$password" >> "$PASSWORD_FILE" # Append the username and password to the password file
  echo "Generated password for $username" | tee -a "$LOG_FILE"
  echo "$username:$password" | chpasswd # Set the paasword for the user to the generated password
done < "$1"

echo "User creation process completed" | tee -a "$LOG_FILE"
```

### Step 7: Finalizing the Script

**Thought Process:**
- Ensure the script handles all scenarios and errors gracefully.
- Test the script to ensure it meets all acceptance criteria.

### Running the Script:

```bash
bash create_users.sh <name-of-text-file>
```

### Note on Running Scripts with `bash`

When executing scripts using `bash`, please ensure to run them with superuser privileges. You can achieve this by either using `sudo` with `bash`, like so:

```bash
sudo bash your_script.sh
```

Or by running the script directly as a superuser:

```bash
su -c "bash your_script.sh"
```

This ensures that the script has the necessary permissions to perform actions that require administrative access.
