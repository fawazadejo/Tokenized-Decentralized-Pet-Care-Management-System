# Tokenized Decentralized Pet Care Management System

A comprehensive blockchain-based pet care management system built on Stacks using Clarity smart contracts.

## Overview

This system provides a decentralized platform for managing all aspects of pet care through five interconnected smart contracts:

1. **Pet Identification Contract** - Digital pet passports and microchip data management
2. **Veterinary Record Contract** - Comprehensive health history tracking
3. **Breeding Verification Contract** - Lineage and genetic information management
4. **Lost Pet Recovery Contract** - Search and reunion coordination
5. **Care Provider Matching Contract** - Trusted pet sitter connections

## Features

### Pet Identification
- Digital pet passport creation and management
- Microchip data registration and verification
- Owner verification and transfer capabilities
- Pet profile management with metadata

### Veterinary Records
- Comprehensive health history tracking
- Vaccination record management
- Medical procedure documentation
- Veterinarian verification system

### Breeding Verification
- Genetic lineage tracking
- Breeding certificate issuance
- Pedigree verification
- Genetic health screening records

### Lost Pet Recovery
- Missing pet report filing
- Search coordination system
- Reward mechanism for finders
- Reunion verification process

### Care Provider Matching
- Pet sitter registration and verification
- Service booking and payment system
- Rating and review mechanism
- Emergency contact management

## Contract Architecture

Each contract operates independently without cross-contract calls, ensuring modularity and security:

- \`pet-identification.clar\` - Core pet identity management
- \`veterinary-records.clar\` - Health record management
- \`breeding-verification.clar\` - Lineage and breeding data
- \`lost-pet-recovery.clar\` - Missing pet coordination
- \`care-provider-matching.clar\` - Service provider network

## Getting Started

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI tools
- Node.js for testing

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts to testnet/mainnet

### Testing

Tests are written using Vitest and cover all contract functions:

\`\`\`bash
npm test
\`\`\`

## Usage Examples

### Registering a Pet
\`\`\`clarity
(contract-call? .pet-identification register-pet
"Buddy"
"Golden Retriever"
u123456789
"QmHash...")
\`\`\`

### Adding Veterinary Record
\`\`\`clarity
(contract-call? .veterinary-records add-health-record
u1
"Annual Checkup"
'SP1VETERINARIAN
"Healthy condition")
\`\`\`

### Reporting Lost Pet
\`\`\`clarity
(contract-call? .lost-pet-recovery report-lost-pet
u1
"Last seen at Central Park"
u1000000)
\`\`\`

## Security Considerations

- All contracts implement proper access controls
- Owner verification required for sensitive operations
- Data integrity maintained through blockchain immutability
- No cross-contract dependencies reduce attack surface

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License.
