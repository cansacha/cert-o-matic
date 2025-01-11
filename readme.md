# 🔐 Cert-o-matic Script

## Overview
This script provides a streamlined way to manage a Public Key Infrastructure (PKI). It allows you to:
- 🛠️ Initialize Root and Intermediate Certificate Authorities (CA).
- 📜 Generate certificates for services.

### Features
- Initialize a Root CA and an Intermediate CA.
- Generate certificates for services.
- Automatic directory structure creation.
- Support for signing certificates with either the Root CA or Intermediate CA.

## Prerequisites
Ensure the following tools are installed on your system:
- `openssl`
- `bash`

## Installation
1. Clone this repository or download the script.
2. Make the script executable:
   ```bash
   chmod +x cert-o-matic.sh
   ```
3. Ensure the script is placed in a directory with the required permissions.

## Usage
The script supports the following commands:

### 1️⃣ `init-ca`
Initializes the PKI structure, creates the Root CA, and signs an Intermediate CA certificate with the Root CA.

**Command:**
```bash
./pki_management.sh init-ca
```

**Example Output:**
- Root CA and Intermediate CA certificates are created.
- The directory structure is verified and updated if necessary.

### 2️⃣ `generate-cert`
Generates a certificate for a service.

**Command:**
```bash
./pki_management.sh generate-cert <service_name> <service_url> [--use-root]
```

**Options:**
- `<service_name>`: Name of the service (used for file naming).
- `<service_url>`: URL or Common Name (CN) for the service.
- `--use-root` (optional): Sign the certificate with the Root CA instead of the Intermediate CA.

**Examples:**
```bash
./pki_management.sh generate-cert myservice myservice.local
./pki_management.sh generate-cert myservice myservice.local --use-root
```

### `help`
Displays detailed usage information for all commands.

**Command:**
```bash
./pki_management.sh help
```

**Command-Specific Help:**
```bash
./pki_management.sh help <command>
```

## Directory Structure
The script creates and manages the following directory structure:

```
../pki/
├── root/
│   ├── certs/
│   ├── crl/
│   ├── private/
│   ├── index.txt
│   ├── index.txt.attr
│   ├── serial
├── intermediate/
│   ├── certs/
│   ├── crl/
│   ├── csr/
│   ├── private/
│   ├── newcerts/
│   ├── index.txt
│   ├── index.txt.attr
│   ├── serial
├── certs/
├── crl/
├── newcerts/
```

## 🔄 Example Workflow
1. **Initialize the PKI:**
   ```bash
   ./pki_management.sh init-ca
   ```

2. **Generate a certificate for a service:**
   ```bash
   ./pki_management.sh generate-cert myservice myservice.local
   ```

## Troubleshooting
- **Missing Commands:** Ensure the script is executed with the correct syntax. Use `./pki_management.sh help` for guidance.
- **Missing Dependencies:** Verify `openssl` is installed and available in your `PATH`.
- **Permission Issues:** Ensure the script and PKI directories have appropriate permissions.

## 🤝 Contributing
Contributions are welcome! Feel free to fork the repository and submit pull requests.
