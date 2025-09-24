# 🏠 Smart Contract-based Rental Agreements

A comprehensive blockchain-based rental agreement system built on Stacks blockchain using Clarity smart contracts.

## 🌟 Features

- 🏘️ **Property Management**: List and delist rental properties
- 📋 **Lease Requests**: Submit and manage rental applications  
- ✅ **Lease Approval**: Landlords can approve or reject lease requests
- 💰 **Security Deposits**: Secure deposit handling and refunds
- 🏠 **Rent Payments**: Monthly rent collection with late fee calculation
- ⚖️ **Dispute Resolution**: Built-in dispute filing and resolution system
- 🔄 **Ownership Transfer**: Transfer property ownership
- 📊 **Lease Status Tracking**: Monitor active, expired, and terminated leases

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) for testing

### Installation

```bash
git clone <repository-url>
cd Smart-Contract-based-Rental-Agreements
clarinet check
```

## 📖 Usage

### For Landlords 🏡

#### 1. List a Property
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements list-property u1000 u2000 "123 Main St")
```
- `u1000`: Monthly rent in microSTX
- `u2000`: Security deposit amount
- `"123 Main St"`: Property address

#### 2. Approve Lease Request
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements approve-lease-request u1 'SP1ABC...)
```

#### 3. Reject Lease Request
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements reject-lease-request u1 'SP1ABC...)
```

#### 4. Transfer Property Ownership
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements transfer-ownership u1 'SP1NEW...)
```

### For Tenants 🏠

#### 1. Request a Lease
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements request-lease u1 u4320 u100)
```
- `u1`: Property ID
- `u4320`: Lease duration in blocks (~30 days)
- `u100`: Start block

#### 2. Pay Security Deposit
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements pay-security-deposit u1)
```

#### 3. Pay Monthly Rent
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements pay-rent u1)
```

### For Both Parties ⚖️

#### File a Dispute
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements file-dispute u1 "Property maintenance issue")
```

#### Terminate Lease
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements terminate-lease u1)
```

## 🔍 Read-Only Functions

### Get Property Information
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements get-property u1)
```

### Check Lease Status
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements get-lease-status u1)
```

### Check if Rent is Due
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements is-rent-due u1)
```

### Calculate Late Fee
```clarity
(contract-call? .Smart-Contract-based-Rental-Agreements calculate-late-fee u1)
```

## 💡 Key Concepts

### Property States
- **Available**: Property is listed and accepting lease requests
- **Occupied**: Property has an active lease
- **Unlisted**: Property is not available for rent

### Lease States
- **Active**: Lease is currently valid and ongoing
- **Expired**: Lease term has ended
- **Terminated**: Lease was ended early by landlord or tenant

### Payment System
- Monthly rent is due every 144 blocks (~24 hours)
- Late fees are calculated proportionally based on delay
- Security deposits are held until lease termination

## 🛡️ Security Features

- ✅ Authorization checks for all actions
- ✅ Input validation for amounts and durations  
- ✅ Proper error handling with descriptive error codes
- ✅ Secure STX transfers for deposits and rent payments
- ✅ Dispute resolution system with contract owner mediation

## 📋 Error Codes

| Code | Description |
|------|-------------|
| u100 | Unauthorized action |
| u101 | Resource not found |
| u102 | Resource already exists |
| u103 | Invalid amount |
| u104 | Property not available |
| u105 | Lease not active |
| u106 | Lease expired |
| u107 | Payment not due |
| u108 | Insufficient deposit |
| u109 | Already paid |
| u110 | Invalid duration |

## 🧪 Testing

Run the test suite:
```bash
npm install
npm test
```

## 📜 Contract Architecture

The contract uses four main data structures:

1. **Properties**: Store property details and landlord information
2. **Leases**: Track active lease agreements and payment history
3. **Lease Requests**: Manage tenant applications
4. **Disputes**: Handle conflict resolution

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🆘 Support

For questions and support, please open an issue in the repository.

---

Built with ❤️ on Stacks blockchain
