//
//  TokenSession.swift
//  EkkTokenExtension
//
//  Created by Furkan Duman on 11.05.2020.
//

import CryptoTokenKit
import os

class TokenSession: TKSmartCardTokenSession, TKTokenSessionDelegate {
    private var authOperation: TKTokenSmartCardPINAuthOperation
    
    override init(token: TKToken) {
        authOperation = TKTokenSmartCardPINAuthOperation()
        
        super.init(token: token)
        
        authOperation.pinFormat.charset = TKSmartCardPINFormat.Charset.numeric
        authOperation.pinFormat.encoding = TKSmartCardPINFormat.Encoding.ascii
        authOperation.pinFormat.minPINLength = 6
        authOperation.pinFormat.maxPINLength = 16
    }
    
    func tokenSession(_ session: TKTokenSession, beginAuthFor operation: TKTokenOperation, constraint: Any) throws -> TKTokenAuthOperation {
        return authOperation
    }
    
    func tokenSession(_ session: TKTokenSession, supports operation: TKTokenOperation, keyObjectID: Any, algorithm: TKTokenKeyAlgorithm) -> Bool {
        let result = (operation == TKTokenOperation.readData || operation == TKTokenOperation.signData) &&
            algorithm.isAlgorithm(SecKeyAlgorithm.rsaSignatureDigestPSSSHA256)
        return result
    }
    
    func tokenSession(_ session: TKTokenSession, sign dataToSign: Data, keyObjectID: Any, algorithm: TKTokenKeyAlgorithm) throws -> Data {
        // Verify PIN
        var result = try smartCard.send(ins: 0x20, p1: 0, p2: 1, data: self.authOperation.pin?.data(using: String.Encoding.ascii))
        if result.sw != 0x9000 {
            throw NSError(domain: TKErrorDomain, code: TKError.Code.authenticationFailed.rawValue, userInfo: nil)
        }
        
        // Select application
        result = try smartCard.send(ins: 0xA4, p1: 0, p2: 1, data: Data(_:[0x3D, 0x00]), le: 0)
        if result.sw != 0x9000 {
            throw NSError(domain: TKErrorDomain, code: TKError.Code.communicationError.rawValue, userInfo: nil)
        }
        
        // Select private key for RSA-PSS/SHA256
        result = try smartCard.send(ins: 0x22, p1: 0x41, p2: 0xB6, data: Data(_:[0x80, 0x01, 0x91, 0x84, 0x01, 0x81]), le: 0)
        if result.sw != 0x9000 {
            throw NSError(domain: TKErrorDomain, code: TKError.Code.communicationError.rawValue, userInfo: nil)
        }
        
        // Sign
        result = try smartCard.send(ins: 0x2A, p1: 0x9E, p2: 0x9A, data: dataToSign, le: 0)
        if result.sw != 0x9000 {
            throw NSError(domain: TKErrorDomain, code: TKError.Code.communicationError.rawValue, userInfo: nil)
        }
        
        return result.response
    }
    
    func tokenSession(_ session: TKTokenSession, decrypt ciphertext: Data, keyObjectID: Any, algorithm: TKTokenKeyAlgorithm) throws -> Data {
        throw NSError(domain: TKErrorDomain, code: TKError.Code.notImplemented.rawValue, userInfo: nil)
    }
    
    func tokenSession(_ session: TKTokenSession, performKeyExchange otherPartyPublicKeyData: Data, keyObjectID objectID: Any, algorithm: TKTokenKeyAlgorithm, parameters: TKTokenKeyExchangeParameters) throws -> Data {
        throw NSError(domain: TKErrorDomain, code: TKError.Code.notImplemented.rawValue, userInfo: nil)
    }
}
