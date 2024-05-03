//
//  ContentView.swift
//  BasedChatTests
//
//  Created by Mia Koring on 01.05.24.
//

import SwiftUI
import SlashCommands
import UIKit

struct ContentView: View {
    @State var commandDisplay: String = ""
    @State var commandInput: String = ""
    @State var resultDisplay = ""
    @State var collection: CommandCollection = CommandCollection(commands: [])
    @State var currentCommand: Command? = nil
    //will later be used to delete a param name
    @State var currentParams: [String: Range<String.Index>] = [:]
    @State var currentRegex: String? = "( message:)"
    @State var commandValid: Bool = true
    @State var currentCommandLength: Int = 0
    @State var textViewHeight: CGFloat = 100
    @State var paramDuplicates: [String] = []
    
    var body: some View {
        Text("message:")
            .background(currentParams.keys.contains("message") ? .blue : .gray)
        Text(commandDisplay)
        TextField("", text: $commandInput)
            .textFieldStyle(.roundedBorder)
        Button{
            
        } label: {
            Text("send")
        }
        Text(resultDisplay)
            .onAppear(){
                collection = CommandCollection(commands: [Bababa(completion: complete)])
                currentCommand = collection.commands.first!
            }
            .onChange(of: commandInput){
                if commandInput.first != "/" {
                    currentCommand = nil
                    return
                }
                
                if currentCommand != nil {
                    do{
                        let matches = try commandInput.matches(of: Regex(currentRegex!))
                        var paramNames: [String: Range<String.Index>] = [:]
                        
                        for match in matches {
                            let name = commandInput[match.range].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ":", with: "")
                            if paramNames.keys.contains(name) {
                                commandValid = false
                                return
                            }
                            paramNames[name] = match.range
                        }
                           
                        currentCommandLength = commandInput.count
                        currentParams = paramNames
                    } catch let error {
                        print(error)
                    }
                    return
                }
            }
    }
    
    func complete(_ params: [String: Any])-> Void {
        if params.isEmpty {
            resultDisplay = "bababa"
            return
        }
        resultDisplay = "\(params["message"] as! String) bababa"
    }
}

#Preview {
    ContentView()
}

struct CommandDisplay: View {
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}

class Bababa: Command{
    var command: String = "bababa"
    
    var parameters: [CommandParameter] = [
        CommandParameter(id: 0, name: "message", datatype: .string, required: false)
    ]
    
    var minPermissions: Permission = .none
    
    var commandOwner: String = "test"
    
    var completion: ([String : Any]) -> Void
    
    init(completion: @escaping ([String : Any]) -> Void) {
        self.completion = completion
    }
    
}


