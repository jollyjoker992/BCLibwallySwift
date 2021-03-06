# BCLibWallySwift

Opinionated Swift wrapper around [LibWally](https://github.com/ElementsProject/libwally-core), a collection of useful primitives for cryptocurrency wallets.

This is a fork of [LibWally Swift](https://github.com/blockchain/libwally-swift). It has a new build system for building XCFrameworks for use with MacOSX, Mac Catalyst, iOS devices, and the iOS simulator.

Also supports particular enhancements used by Blockchain Commons from our fork of libwally-core: [bc-libwally-core](https://github.com/blockchaincommons/bc-libwally-core), in the [bc-maintenance](https://github.com/BlockchainCommons/bc-libwally-core/tree/bc-maintenance) branch.

## Build

```
$ git clone https://github.com/blockchaincommons/BCLibWallySwift.git
$ cd BCLibWallySwift
$ ./build.sh
```

The resulting frameworks are `build/CLibwally.xcframework` and `build/LibWally.xcframework`. Add both to your project.

## Usage

Derive address from a seed:

```swift
import LibWally

let mnemonic = BIP39Mnemonic("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")
let masterKey = HDKey(mnemonic.seedHex("bip39 passphrase"))!
masterKey.fingerprint.hexString
let path = BIP32Path("m/44'/0'/0'")!
let account = try! masterKey.derive(path)
account.xpub
account.address(.payToWitnessPubKeyHash)
```

Derive address from an xpub:

```swift
let account = HDKey("xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ")
let receivePath = BIP32Path("0/0")!
key = account.derive(receivePath)
key.address(.payToPubKeyHash) # => 1JQheacLPdM5ySCkrZkV66G2ApAXe1mqLj
```

Parse an address:

```swift
var address = Address("bc1q6zwjfmhdl4pvhvfpv8pchvtanlar8hrhqdyv0t")
address?.scriptPubKey # => 0014d09d24eeedfd42cbb12161c38bb17d9ffa33dc77
address?.scriptPubKey.type # => .payToWitnessPubKeyHash
```

Create and sign a transaction:

```swift
let txId = "400b52dab0a2bb5ce5fdf5405a965394b43a171828cd65d35ffe1eaa0a79a5c4"
let vout: UInt32 = 1
let amount: Satoshi = 10000
let witness = Witness(.payToWitnessPubKeyHash(key.pubKey))
let input = TxInput(Transaction(txId)!, vout, amount, nil, witness, scriptPubKey)!
transaction = Transaction([input], [TxOutput(destinationAddress.scriptPubKey, amount - 110)])
transaction.feeRate // Satoshi per byte
let accountPriv = HDKey("xpriv...")
let privKey = try! accountPriv.derive(BIP32Path("0/0")!)
transaction.sign([privKey])
transaction.description # transaction hex
```
