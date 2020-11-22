//
//  ScriptSig.swift
//  LibWally
//
//  Created by Wolf McNally on 11/22/20.
//

import Foundation
import CLibWally

public struct ScriptSig : Equatable {
    public static func == (lhs: ScriptSig, rhs: ScriptSig) -> Bool {
        return lhs.type == rhs.type
    }

    let type: ScriptSigType

    public enum ScriptSigType : Equatable {
        case payToPubKeyHash(PubKey) // P2PKH (legacy)
        case payToScriptHashPayToWitnessPubKeyHash(PubKey) // P2SH-P2WPKH (wrapped SegWit)
    }

    public typealias Signature = Data

    // When used in a finalized transaction, scriptSig usually includes a signature:
    var signature: Signature?

    public init (_ type: ScriptSigType) {
        self.type = type
    }

    public enum ScriptSigPurpose {
        case signed
        case feeWorstCase
    }

    public func render(_ purpose: ScriptSigPurpose) -> Data? {
        switch self.type {
        case .payToPubKeyHash(let pubKey):
            switch purpose {
            case .feeWorstCase:
                // DER encoded signature
                let dummySignature = Data([UInt8].init(repeating: 0, count: Int(EC_SIGNATURE_DER_MAX_LOW_R_LEN)))
                let sigHashByte = Data([UInt8(WALLY_SIGHASH_ALL)])
                let lengthPushSignature = Data([UInt8(dummySignature.count + 1)]) // DER encoded signature + sighash byte
                let lengthPushPubKey = Data([UInt8(pubKey.data.count)])
                return lengthPushSignature + dummySignature + sigHashByte + lengthPushPubKey + pubKey.data
            case .signed:
                if let signature = self.signature {
                    let lengthPushSignature = Data([UInt8(signature.count + 1)]) // DER encoded signature + sighash byte
                    let sigHashByte = Data([UInt8(WALLY_SIGHASH_ALL)])
                    let lengthPushPubKey = Data([UInt8(pubKey.data.count)])
                    return lengthPushSignature + signature + sigHashByte + lengthPushPubKey + pubKey.data
                } else {
                    return nil
                }
            }
        case .payToScriptHashPayToWitnessPubKeyHash(let pubKey):
            let pubkey_bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: pubKey.data.count)
            pubKey.data.copyBytes(to: pubkey_bytes, count: pubKey.data.count)
            let pubkey_hash_bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(HASH160_LEN))
            defer {
                pubkey_hash_bytes.deallocate()
            }
            precondition(wally_hash160(pubkey_bytes, pubKey.data.count, pubkey_hash_bytes, Int(HASH160_LEN)) == WALLY_OK)
            let redeemScript = try! Data(hex: "0014") + Data(bytes: pubkey_hash_bytes, count: Int(HASH160_LEN))
            return Data([UInt8(redeemScript.count)]) + redeemScript
        }
    }
}