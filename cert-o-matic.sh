#!/bin/bash
#cert-o-matic 1.0.0

# Define color variables
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# Base directory for PKI
PKI_DIR="pki"

# Default parameters
SERVICE_NAME=$2
SERVICE_URL=$3
CERT_DIR="$PKI_DIR/certs"
CSR_DIR="$PKI_DIR/intermediate/csr"
CHAIN_CERT="$PKI_DIR/intermediate/certs/chain.crt"
INTERMEDIATE_KEY="$PKI_DIR/intermediate/private/intermediate.key"
INTERMEDIATE_CERT="$PKI_DIR/intermediate/certs/intermediate.crt"
ROOT_KEY="$PKI_DIR/root/private/root.key"
ROOT_CERT="$PKI_DIR/root/certs/root.crt"
DAYS_VALID=825

# Define the expected directory structure
declare -a REQUIRED_DIRS=(
    "$PKI_DIR/root"
    "$PKI_DIR/root/private"
    "$PKI_DIR/root/certs"
    "$PKI_DIR/root/crl"
    "$PKI_DIR/intermediate"
    "$PKI_DIR/intermediate/private"
    "$PKI_DIR/intermediate/certs"
    "$PKI_DIR/intermediate/crl"
    "$PKI_DIR/intermediate/csr"
    "$PKI_DIR/intermediate/newcerts"
    "$PKI_DIR/certs"
    "$PKI_DIR/newcerts"
    "$PKI_DIR/crl"
)

declare -a REQUIRED_FILES=(
    "$PKI_DIR/root/index.txt"
    "$PKI_DIR/intermediate/index.txt"
    "$PKI_DIR/root/index.txt.attr"
    "$PKI_DIR/intermediate/index.txt.attr"
    "$PKI_DIR/root/serial"
    "$PKI_DIR/intermediate/serial"
)

# Verify and create the PKI structure if it does not exist
check_and_setup_pki_structure() {
    echo "${CYAN}Checking and creating PKI structure if necessary...${RESET}"
    local missing_items=0

    # Check directories
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            echo "${YELLOW}Missing directory:${RESET} $dir. Creating..."
            mkdir -p "$dir"
            missing_items=$((missing_items + 1))
        fi
    done

    # Check files
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            echo "${YELLOW}Missing file:${RESET} $file. Creating..."
            touch "$file"
            missing_items=$((missing_items + 1))
            if [[ "$file" == *"serial" ]]; then
                echo "1000" > "$file"
            fi
        fi
    done

    chmod 700 "$PKI_DIR/root/private" "$PKI_DIR/intermediate/private"

    if [ $missing_items -eq 0 ]; then
        echo "${GREEN}PKI structure is complete.${RESET}"
    else
        echo "${GREEN}PKI structure has been successfully updated.${RESET}"
    fi
}

# Initialize the Root CA and Intermediate CA
init_ca() {
    local ROOT_NAME="root"
    local INTERMEDIATE_NAME="intermediate"
    local KEY_SIZE=4096
    local VALIDITY_DAYS_ROOT=3650
    local VALIDITY_DAYS_INTERMEDIATE=1825

    # Verify and set up the PKI structure if necessary
    check_and_setup_pki_structure

    # Initialize the Root CA
    echo "${CYAN}Creating Root CA...${RESET}"
    openssl genrsa -out "$ROOT_KEY" "$KEY_SIZE"
    openssl req -x509 -new -nodes -key "$ROOT_KEY" \
        -sha256 -days "$VALIDITY_DAYS_ROOT" \
        -out "$ROOT_CERT" \
        -subj "/C=FR/ST=France/L=Paris/O=MyOrganization/CN=$ROOT_NAME"

    # Initialize the Intermediate CA
    echo "${CYAN}Creating Intermediate CA...${RESET}"
    openssl genrsa -out "$INTERMEDIATE_KEY" "$KEY_SIZE"
    openssl req -new -key "$INTERMEDIATE_KEY" \
        -out "$PKI_DIR/intermediate/csr/intermediate.csr" \
        -subj "/C=FR/ST=France/L=Paris/O=MyOrganization/CN=$INTERMEDIATE_NAME"

    # Sign the Intermediate CA certificate with the Root CA
    echo "${CYAN}Signing Intermediate CA with Root CA...${RESET}"
    openssl x509 -req -in "$PKI_DIR/intermediate/csr/intermediate.csr" \
        -CA "$ROOT_CERT" -CAkey "$ROOT_KEY" -CAcreateserial \
        -out "$INTERMEDIATE_CERT" -days "$VALIDITY_DAYS_INTERMEDIATE" -sha256

    # Create the certificate chain
    cat "$INTERMEDIATE_CERT" "$ROOT_CERT" > "$CHAIN_CERT"
    echo "${GREEN}Certificate chain created:${RESET} $CHAIN_CERT"
}

# Generate a certificate
build_certificate() {
    local USE_ROOT=0

    while [ $# -gt 0 ]; do
        case "$1" in
            --use-root)
                USE_ROOT=1
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Verify and set up the PKI structure if necessary
    check_and_setup_pki_structure

    # Generate private key
    echo "${CYAN}Generating private key for $SERVICE_NAME ($SERVICE_URL)...${RESET}"
    openssl genrsa -out "$CERT_DIR/$SERVICE_NAME.key" 2048

    # Generate CSR
    echo "${CYAN}Creating CSR...${RESET}"
    openssl req -new -key "$CERT_DIR/$SERVICE_NAME.key" \
        -out "$CSR_DIR/$SERVICE_NAME.csr" \
        -subj "/C=FR/ST=France/L=Paris/O=MyOrganization/CN=$SERVICE_URL"

    # Determine the CA to use for signing
    if [ $USE_ROOT -eq 1 ]; then
        echo "${CYAN}Signing certificate with Root CA...${RESET}"
        openssl x509 -req -in "$CSR_DIR/$SERVICE_NAME.csr" \
            -CA "$ROOT_CERT" -CAkey "$ROOT_KEY" -CAcreateserial \
            -out "$CERT_DIR/$SERVICE_NAME.crt" -days $DAYS_VALID -sha256
    else
        echo "${CYAN}Signing certificate with Intermediate CA...${RESET}"
        openssl x509 -req -in "$CSR_DIR/$SERVICE_NAME.csr" \
            -CA "$INTERMEDIATE_CERT" -CAkey "$INTERMEDIATE_KEY" -CAcreateserial \
            -out "$CERT_DIR/$SERVICE_NAME.crt" -days $DAYS_VALID -sha256
    fi

    echo "${GREEN}Certificate successfully generated:${RESET} $CERT_DIR/$SERVICE_NAME.crt"
}

# Display script usage
print_help() {
    local COMMAND=$1
    echo "${BLUE}Usage:${RESET} $0 {init-ca|generate-cert} [options]"
    echo
    case "$COMMAND" in
        init-ca)
            echo "${CYAN}Command:${RESET} init-ca"
            echo "  Initialize the Root CA and Intermediate CA."
            echo "  This command sets up a PKI structure and creates both the Root and Intermediate CAs."
            echo
            echo "  ${BLUE}Example:${RESET}"
            echo "    $0 init-ca"
            ;;
        generate-cert)
            echo "${CYAN}Command:${RESET} generate-cert <name> <url> [--use-root]"
            echo "  Generate a certificate for a service. By default, uses the Intermediate CA for signing."
            echo
            echo "  ${CYAN}Options:${RESET}"
            echo "    --use-root      Use Root CA for signing instead of the Intermediate CA."
            echo
            echo "  ${BLUE}Examples:${RESET}"
            echo "    $0 generate-cert myservice myservice.local"
            echo "    $0 generate-cert myservice myservice.local --use-root"
            ;;
        *)
            echo "Available commands:"
            echo "  ${CYAN}init-ca${RESET}         Initialize the Root CA and Intermediate CA."
            echo "  ${CYAN}generate-cert${RESET}   Generate a certificate for a service."
            echo
            echo "Use '${CYAN}$0 <command>${RESET}' for more information on a specific command."
            ;;
    esac
}


# Main function
main() {
    if [ $# -lt 1 ]; then
        print_help
        exit 1
    fi

    case "$1" in
        init-ca)
            init_ca
            ;;
        generate-cert)
            if [ $# -lt 3 ]; then
                echo "${RED}Error: Missing required arguments for generate-cert.${RESET}"
                print_help generate-cert
                exit 1
            fi
            build_certificate "$2" "$3" "${@:4}"
            ;;
        generate-chain)
            generate_chain
            ;;
        help)
            print_help "$2"
            ;;
        *)
            echo "${RED}Error: Unknown command '$1'.${RESET}"
            print_help
            exit 1
            ;;
    esac
}

# Call the main function with all script arguments
main "$@"
