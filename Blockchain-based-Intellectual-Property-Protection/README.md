# Blockchain-based Intellectual Property Protection Smart Contract

## Overview

This smart contract provides a comprehensive solution for intellectual property protection on the Stacks blockchain. It enables users to register, verify, transfer, and license various types of intellectual property including patents, trademarks, copyrights, and trade secrets.

## Features

### Core Functionality
- **IP Registration**: Register intellectual property with immutable blockchain records
- **Ownership Verification**: Cryptographically verify IP ownership
- **Transfer Management**: Secure transfer of IP rights between parties  
- **Licensing System**: Create and manage IP licenses with customizable terms
- **Dispute Tracking**: Record and track IP disputes
- **User Profiles**: Maintain user reputation and IP portfolios

### Supported IP Types
- **Patents**: 20-year protection period
- **Trademarks**: 10-year protection period (renewable)
- **Copyrights**: 70-year protection period
- **Trade Secrets**: 50-year protection period

## Contract Architecture

### Data Structures

#### Intellectual Properties Map
```clarity
{
  owner: principal,
  title: (string-ascii 100),
  description: (string-ascii 500),
  ip-type: (string-ascii 20),
  hash: (buff 32),
  registration-date: uint,
  expiry-date: uint,
  is-active: bool,
  license-terms: (string-ascii 200)
}
```

#### User Profiles Map
```clarity
{
  name: (string-ascii 50),
  reputation-score: uint,
  total-ips: uint,
  verification-status: bool
}
```

#### Licenses Map
```clarity
{
  licensor: principal,
  license-type: (string-ascii 20),
  start-date: uint,
  end-date: uint,
  royalty-rate: uint,
  is-active: bool
}
```

## Public Functions

### Registration Functions

#### `register-ip`
Registers a new intellectual property on the blockchain.

**Parameters:**
- `title`: IP title (max 100 characters)
- `description`: Detailed description (max 500 characters)
- `ip-type`: Type of IP ("patent", "trademark", "copyright", "trade-secret")
- `content-hash`: SHA-256 hash of the IP content
- `license-terms`: Default licensing terms (max 200 characters)

**Returns:** `(ok ip-id)` on success

**Fees:** Requires payment of registration fee (default: 1 STX)

### Ownership Functions

#### `transfer-ip`
Transfers ownership of an IP to a new owner.

**Parameters:**
- `ip-id`: Unique identifier of the IP
- `new-owner`: Principal address of the new owner

**Authorization:** Only current IP owner

#### `verify-ownership`
Verifies if a principal owns a specific IP (read-only).

**Parameters:**
- `ip-id`: Unique identifier of the IP
- `claimed-owner`: Principal to verify ownership for

**Returns:** `true` if ownership is verified, `false` otherwise

### Licensing Functions

#### `create-license`
Creates a license agreement for an IP.

**Parameters:**
- `ip-id`: Unique identifier of the IP
- `licensee`: Principal receiving the license
- `license-type`: "exclusive" or "non-exclusive"
- `duration-days`: License duration in days
- `royalty-rate`: Royalty percentage * 100 (e.g., 500 = 5%)

**Authorization:** Only IP owner

### Query Functions

#### `get-ip-details`
Retrieves complete information about an IP (read-only).

#### `is-ip-valid`
Checks if an IP is currently valid and not expired (read-only).

#### `get-user-ips`
Retrieves user profile and IP statistics (read-only).

#### `get-license`
Retrieves license details for a specific IP and licensee (read-only).

## Installation & Deployment

### Prerequisites
- Stacks CLI installed
- Stacks wallet with sufficient STX for deployment
- Node.js and npm for testing

### Deployment Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd blockchain-ip-protection
   ```

2. **Configure deployment**
   ```bash
   # Set up your Stacks configuration
   stx make_keychain -t > keychain.json
   ```

3. **Deploy to testnet**
   ```bash
   stx deploy_contract ip-protection contract/ip-protection.clar --testnet
   ```

4. **Deploy to mainnet**
   ```bash
   stx deploy_contract ip-protection contract/ip-protection.clar --mainnet
   ```

## Usage Examples

### Register a Patent
```clarity
(contract-call? .ip-protection register-ip 
  "Revolutionary Widget Design"
  "A new approach to widget manufacturing that increases efficiency by 300%"
  "patent"
  0x1234567890abcdef1234567890abcdef12345678
  "Commercial use requires licensing agreement"
)
```

### Transfer IP Ownership
```clarity
(contract-call? .ip-protection transfer-ip 
  u1 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
)
```

### Create a License
```clarity
(contract-call? .ip-protection create-license
  u1
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
  "non-exclusive"
  u365  ;; 1 year
  u500  ;; 5% royalty
)
```

## Security Considerations

### Access Control
- Only IP owners can transfer or license their properties
- Contract owner has administrative privileges for fee setting and emergency functions
- All ownership changes are recorded in immutable blockchain history

### Data Integrity
- Content hashes ensure IP authenticity
- Timestamps prevent backdating of registrations
- Expiry dates automatically enforce IP validity periods

### Economic Security
- Registration fees prevent spam registrations
- Reputation system encourages good behavior
- License terms are immutable once created

## Gas Optimization

The contract is optimized for gas efficiency through:
- Minimal storage operations
- Efficient data structures
- Read-only functions for queries
- Batched operations where possible

## Testing

### Unit Tests
```bash
npm install
npm run test
```

### Integration Tests
```bash
npm run test:integration
```

## Error Codes

- `u100`: Owner only function
- `u101`: IP not found
- `u102`: IP already exists
- `u103`: Unauthorized access
- `u104`: Invalid input parameters
- `u105`: IP expired
- `u106`: Insufficient payment

## Roadmap

### Phase 1 (Current)
- ✅ Basic IP registration and verification
- ✅ Ownership transfer functionality
- ✅ Simple licensing system

### Phase 2 (Planned)
- [ ] Advanced dispute resolution
- [ ] Royalty payment automation
- [ ] Multi-signature ownership
- [ ] IP marketplace integration

### Phase 3 (Future)
- [ ] Cross-chain IP verification
- [ ] AI-powered prior art detection
- [ ] Decentralized IP valuation
- [ ] Legal framework integration

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:
- Create an issue on GitHub
- Join our Discord community
- Email: support@ip-protection.com

## Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Community contributors and testers
- Legal advisors for compliance guidance