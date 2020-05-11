//
//  TokenDriver.swift
//  EkkTokenExtension
//
//  Created by Furkan Duman on 11.05.2020.
//

import CryptoTokenKit
import os

class TokenDriver: TKSmartCardTokenDriver, TKSmartCardTokenDriverDelegate {

    func tokenDriver(_ driver: TKSmartCardTokenDriver, createTokenFor smartCard: TKSmartCard, aid AID: Data?) throws -> TKSmartCardToken {
        os_log("Token driver initializing")
        return try Token(smartCard: smartCard, aid: AID, tokenDriver: self)
    }
}
