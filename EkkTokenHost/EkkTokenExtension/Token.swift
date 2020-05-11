//
//  Token.swift
//  EkkTokenExtension
//
//  Created by Furkan Duman on 11.05.2020.
//

import CryptoTokenKit
import CoreServices
import os

class Token: TKSmartCardToken, TKTokenDelegate {
    // Kimlik doğrulama AID: A000000063504B43532D3135
    init(smartCard: TKSmartCard, aid AID: Data?, tokenDriver: TKSmartCardTokenDriver) throws {
        os_log("Token initalizing")
        let instanceID = UUID().uuidString // Fill in a unique persistent identifier of the token instance.
        super.init(smartCard: smartCard, aid:AID, instanceID:instanceID, tokenDriver: tokenDriver)
        
        smartCard.cla = 0
        smartCard.allowedProtocols = TKSmartCardProtocol.t1
        smartCard.useCommandChaining = true
        smartCard.useExtendedLength = false
        
        try smartCard.withSession {
            try self.getTokens(smartCard: smartCard)
        }
    }
    
    func getTokens(smartCard: TKSmartCard) throws {
        var result: (sw: UInt16, response: Data)
        
        // Select MF
        result = try smartCard.send(ins: 0xA4, p1: 0x00, p2: 0x00, le: 0)
        if (result.sw != 0x9000) {
            throw NSError(domain: TKErrorDomain, code: TKError.Code.communicationError.rawValue, userInfo: nil)
        }
        
        // Select identity verification application
        result = try smartCard.send(ins: 0xA4, p1: 0x01, p2: 0x00, data: Data(_:[0x3D, 0x00]), le: 0)
        if (result.sw != 0x9000) {
            throw NSError(domain: TKErrorDomain, code: TKError.Code.communicationError.rawValue, userInfo: nil)
        }
        
        // Select identity x509 certificate
        result = try smartCard.send(ins: 0xA4, p1: 0x02, p2: 0x00, data: Data(_:[0x2F, 0x10]), le: 0)
        if (result.sw != 0x9000) {
            throw NSError(domain: TKErrorDomain, code: TKError.Code.communicationError.rawValue, userInfo: nil)
        }
        
        let lengthSource: [UInt8] = [result.response[5], result.response[4]]
        let length = Int(lengthSource.withUnsafeBytes { $0.load(as: UInt16.self) })
    
        var certificateData = Data()
        
        // Read certificate
        var offset = 0
        
        repeat {
            var size = length - offset > 196 ? 196 : length - offset
            result = try smartCard.send(ins: 0xB0, p1: UInt8((offset >> 8) & 0xFF), p2: UInt8(offset & 0x00FF), le:size)
            if (result.sw != 0x9000) {
                throw NSError(domain: TKErrorDomain, code: TKError.Code.communicationError.rawValue, userInfo: nil)
            }
            certificateData.append(result.response)
            offset = offset + size
        }while( offset != length)
        
        let dataArray = [UInt8](certificateData);
        let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, CFDataCreate(kCFAllocatorDefault, dataArray, dataArray.count))!
    
        
        let tokenKey = TKTokenKeychainKey(certificate: certificate, objectID: "1")!
        tokenKey.canDecrypt = false
        tokenKey.canPerformKeyExchange = false
        tokenKey.canSign = true
        tokenKey.isSuitableForLogin = true
        tokenKey.label = "TCKK Kimlik Doğrulama Sertifikası"

        //let tokenCertificate = TKTokenKeychainCertificate(certificate: certificate, objectID: "1")!
        
        var items = [TKTokenKeychainItem]()
        //items.append(tokenCertificate)
        items.append(tokenKey)
        self.keychainContents!.fill(with: items)
    }
    
    func createSession(_ token: TKToken) throws -> TKTokenSession {
        return TokenSession(token:self)
    }
}
