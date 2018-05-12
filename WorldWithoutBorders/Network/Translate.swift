//
//  Translate.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 3/12/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import Foundation

/* The translate capability in this app */
class Translate {
    
    func translate(inputLang: String, outputLang: String, text: String, completion: @escaping (String) -> Void) {
        let sentences = text.characters.split{$0 == "."}.map(String.init)
        var newSentences: [String] = Array(repeating: "", count: sentences.count)
        var num = 0
        for i in 0..<sentences.count {
            int_translatePhrase(il: inputLang, ol: outputLang, phrase: sentences[i], index: i, completion: {
                (translated: String, index: Int) in
                    num += 1
                    newSentences[i] = translated
                    if num == sentences.count {
                        var result = "";
                        for sentence in newSentences {
                            result += "\(sentence). "
                        }
                        completion(result)
                    }
            })
        }
    }

    // Function translates and calls completion when done
    func int_translatePhrase(il: String, ol: String, phrase: String, index: Int, completion: @escaping (String, Int) -> Void) {
        
        let pushCall = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(il)&tl=\(ol)&dt=t&q=\(phrase.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
        if let functioning = URL(string: pushCall) {
            let task = URLSession.shared.dataTask(with: functioning) {(data, response, error) in
                if let data = data {
                    let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? ""
                    let str2 = str as String
                    let start = str2.index(str2.startIndex, offsetBy: 4)
                    let start2 = str2[start...].index(of: "\"") // + startIndex
                    let demo = "Testing my functions"
                    let resulting = str2[start..<start2!]
                    completion(String(resulting), index);
                } else {
                    print("Unsuccessful")
                }
            }
            task.resume()
        } else {
            print("error: \(pushCall)")
        }
    }
}

