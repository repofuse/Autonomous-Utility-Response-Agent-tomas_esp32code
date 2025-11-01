# Aura Protocol Backend - Testing Guide

This guide will walk you through testing all endpoints of the Aura Protocol mock backend server.



Expected output:
```
🚀 Aura Protocol Mock Backend Server
==================================
✅ Server running on port 3001
🔗 Network: https://sepolia.base.org
📄 Contract: 0x...
🤖 AI Agent: 0x...
🔮 Oracle: 0x...

Endpoints:
  GET  /health - Health check
  GET  /grid-status - Get current grid status
  POST /simulate-stress-event - Trigger grid stress event
  POST /report-savings - Submit proof of savings
==================================
```

## Testing Endpoints

### 1. Health Check

**Request:**
```bash
curl https://aura-backend-5hi0.onrender.com/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "wallets": {
    "aiAgent": "0x...",
    "oracle": "0x..."
  },
  "contract": "0x..."
}
```

✅ **Success Criteria:** Status is "healthy" and all addresses are displayed

---

### 2. Get Grid Status (Initial State)

**Request:**
```bash
curl https://aura-backend-5hi0.onrender.com/grid-status
```

**Expected Response:**
```json
{
  "status": "normal"
}
```

✅ **Success Criteria:** Status is "normal" (initial state)

---

### 3. Simulate Grid Stress Event

This endpoint triggers the AI Agent to create a grid stress event on-chain.

**Request:**
```bash
curl -X POST https://aura-backend-5hi0.onrender.com/simulate-stress-event \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Grid stress event triggered on-chain.",
  "transactionHash": "0x...",
  "bountyPerWatt": 100,
  "duration": 300
}
```

**Server Console Output:**
```
🚨 Triggering grid stress event...
Calling triggerEvent(100, 300)...
Transaction sent: 0x...
Waiting for confirmation...
✅ Transaction confirmed: 0x...
```

✅ **Success Criteria:**
- Response has `success: true`
- Transaction hash returned
- Server logs show confirmation
- Grid status should now be "STRESSED"

---

### 4. Verify Grid Status Changed to STRESSED

**Request:**
```bash
curl https://aura-backend-5hi0.onrender.com/grid-status
```

**Expected Response:**
```json
{
  "status": "STRESSED"
}
```

✅ **Success Criteria:** Status changed from "normal" to "STRESSED"

---

### 5. Report Energy Savings

This endpoint allows IoT devices to report their energy savings to the Oracle.

**Request:**
```bash
curl -X POST https://aura-backend-5hi0.onrender.com/report-savings \
  -H "Content-Type: application/json" \
  -d '{
    "deviceAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
    "savings": 50
  }'
```

**Note:** Replace the `deviceAddress` with a valid Ethereum address (preferably your test device address).

**Expected Response:**
```json
{
  "success": true,
  "message": "Proof submitted to oracle.",
  "transactionHash": "0x...",
  "deviceAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
  "savings": 50
}
```

**Server Console Output:**
```
📊 Reporting savings for device 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0: 50 watts
Calling submitProofOfSaving(0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0, 50)...
Transaction sent: 0x...
Waiting for confirmation...
✅ Transaction confirmed: 0x...
```

✅ **Success Criteria:**
- Response has `success: true`
- Transaction hash returned
- Server logs show confirmation
- Grid status should return to "normal"

---

### 6. Verify Grid Status Returned to Normal

**Request:**
```bash
curl https://aura-backend-5hi0.onrender.com/grid-status
```

**Expected Response:**
```json
{
  "status": "normal"
}
```

✅ **Success Criteria:** Status changed back to "normal"

---

## Complete Demo Flow Test

Run these commands in sequence to test the complete flow:

```bash
# 1. Check server health
curl https://aura-backend-5hi0.onrender.com/health

# 2. Check initial grid status (should be "normal")
curl https://aura-backend-5hi0.onrender.com/grid-status

# 3. Trigger stress event
curl -X POST https://aura-backend-5hi0.onrender.com/simulate-stress-event

# 4. Verify grid is now stressed
curl https://aura-backend-5hi0.onrender.com/grid-status

# 5. Wait a few seconds for the blockchain transaction to confirm...
sleep 5

# 6. Report savings (replace address with your test device address)
curl -X POST https://aura-backend-5hi0.onrender.com/report-savings \
  -H "Content-Type: application/json" \
  -d '{"deviceAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0", "savings": 50}'

# 7. Verify grid is back to normal
curl https://aura-backend-5hi0.onrender.com/grid-status
```

---

## Error Testing

### Test Missing Fields in /report-savings

**Request:**
```bash
curl -X POST https://aura-backend-5hi0.onrender.com/report-savings \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Missing required fields: deviceAddress and savings"
}
```

---

## Testing with Postman

If you prefer using Postman:

### Collection Import

Create these requests:

1. **GET Health Check**
   - URL: `https://aura-backend-5hi0.onrender.com/health`
   - Method: GET

2. **GET Grid Status**
   - URL: `https://aura-backend-5hi0.onrender.com/grid-status`
   - Method: GET

3. **POST Simulate Stress Event**
   - URL: `https://aura-backend-5hi0.onrender.com/simulate-stress-event`
   - Method: POST
   - Headers: `Content-Type: application/json`

4. **POST Report Savings**
   - URL: `https://aura-backend-5hi0.onrender.com/report-savings`
   - Method: POST
   - Headers: `Content-Type: application/json`
   - Body (raw JSON):
     ```json
     {
       "deviceAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
       "savings": 50
     }
     ```

---

## Verifying On-Chain

To verify transactions actually made it to the blockchain:

1. Copy the transaction hash from any response
2. Visit the block explorer for your network:
   - Base Sepolia: `https://sepolia.basescan.org/tx/0x...`
3. Verify the transaction shows:
   - ✅ Success status
   - Correct "From" address (AI Agent or Oracle)
   - Correct "To" address (Contract)
   - Correct function call

---

## Troubleshooting

### "Insufficient funds for gas"
- Ensure both wallets have ETH for gas fees
- Get testnet ETH from a faucet

### "Invalid address"
- Check that CONTRACT_ADDRESS in .env is correct
- Verify the contract is deployed on the network specified by RPC_URL

### "Cannot read properties of undefined"
- Verify all required variables in .env are set
- Check for typos in variable names

### Connection timeout
- Verify RPC_URL is accessible
- Try a different RPC endpoint

### Transaction reverted
- Check that the AI Agent has permission to call triggerEvent
- Verify the Oracle has permission to call submitProofOfSaving
- Ensure contract is properly initialized

---

## Next Steps

After successful testing:

1. ✅ Integrate with frontend (Person 2)
2. ✅ Connect IoT device simulator
3. ✅ Test full end-to-end flow
4. ✅ Prepare for demo presentation

---

## Quick Test Script

Save this as `test.sh` for quick testing:

```bash
#!/bin/bash

echo "🧪 Testing Aura Protocol Backend"
echo "================================"

echo -e "\n1️⃣ Health Check..."
curl -s https://aura-backend-5hi0.onrender.com/health | jq

echo -e "\n2️⃣ Initial Grid Status..."
curl -s https://aura-backend-5hi0.onrender.com/grid-status | jq

echo -e "\n3️⃣ Triggering Stress Event..."
curl -s -X POST https://aura-backend-5hi0.onrender.com/simulate-stress-event | jq

echo -e "\n4️⃣ Grid Status (Should be STRESSED)..."
curl -s https://aura-backend-5hi0.onrender.com/grid-status | jq

echo -e "\n⏳ Waiting 5 seconds for transaction confirmation..."
sleep 5

echo -e "\n5️⃣ Reporting Savings..."
curl -s -X POST https://aura-backend-5hi0.onrender.com/report-savings \
  -H "Content-Type: application/json" \
  -d '{"deviceAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0", "savings": 50}' | jq

echo -e "\n6️⃣ Grid Status (Should be normal)..."
curl -s https://aura-backend-5hi0.onrender.com/grid-status | jq

echo -e "\n✅ Testing Complete!"
```

Make it executable:
```bash
chmod +x test.sh
./test.sh
```

(Requires `jq` for JSON formatting: `brew install jq` on macOS)

