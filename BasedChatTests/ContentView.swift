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
    @State var currentCommand: (any Command)? = nil
    //will later be used to delete a param name
    @State var currentParams: [String: Range<String.Index>] = [:]
    @State var currentCommandLength: Int = 0
    @State var textViewHeight: CGFloat = 100
    @State var paramDuplicates: [String] = []
    @State var relevantCommands: [any Command] = []
    
    var body: some View {
        if currentCommand == nil {
            ForEach(relevantCommands, id: \.id) { command in
                CommandPreview(command: command, currentCommand: $currentCommand, commandInput: $commandInput)
            }
        }
        CommandDetailView(commandInput: $commandInput, currentCommand: $currentCommand, collection: $collection, relevantCommands: $relevantCommands)
        Text(commandDisplay)
        TextField("", text: $commandInput)
            .textFieldStyle(.roundedBorder)
        Button{
            
        } label: {
            Text("send")
        }
        Text(resultDisplay)
            .onAppear(){
                collection = CommandCollection(commands: [Bababa(completion: complete), Daddy(completion: comp)])
            }
    }
    
    func comp(_ params: [String: Any])-> Void {
        resultDisplay = "ioi"
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

struct CommandDetailView: View {
    @Binding var commandInput: String
    @State var currentParam: CommandParameter? = nil
    @State var setParams: [String] = ["message"]
    @Binding var currentCommand: (any Command)?
    @State var currentRegex: String? = "( message:)"
    @State var commandValid: Bool = true
    @Binding var collection: CommandCollection
    @Binding var relevantCommands: [any Command]
    @State var prefixWrong = false
    
    var body: some View {
        VStack {
            if currentCommand != nil {
                ScrollView(.horizontal){
                    HStack{
                        Image("Image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 11.2, style: .continuous))
                            .padding(.horizontal, 10)
                        Text("/ \(currentCommand!.command)")
                            .font(.subheadline)
                            .bold()
                            .padding(5)
                            .background(){
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(prefixWrong ? .red : .clear)
                            }
                        Spacer()
                        ForEach(currentCommand!.parameters, id: \.self){ param in
                            Text(param.name)
                                .padding(5)
                                .font(.subheadline)
                                .background(){
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .background(param, current: currentParam, set: setParams)
                                    
                                }
                                .onTapGesture {
                                    currentParam = param
                                    if !setParams.contains(param.name) {
                                        if commandInput.last == " " {
                                            commandInput.append("\(param.name):")
                                            return
                                        }
                                        commandInput.append(" \(param.name):")
                                    }
                                }
                        }
                    }
                }
                HStack{
                    Text(currentParam?.description ?? currentCommand!.description)
                        .font(.footnote)
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
        }
        .onChange(of: commandInput){
            if commandInput.first != "/" {
                currentCommand = nil
                relevantCommands = []
                return
            }
            
            let lastIndex = {
                if let index = commandInput.firstIndex(of: " ") {
                    return commandInput.index(before: index)
                }
                return commandInput.index(before: commandInput.endIndex)
            }()
            
            let commandprefix = String(commandInput[commandInput.startIndex...lastIndex])
            
            relevantCommands = collection.commands(for: commandprefix, highestPermission: .none)
            
            if commandprefix == "/" {
                currentCommand = nil
            }
            else if currentCommand != nil && commandprefix.dropFirst() != currentCommand!.command {
                prefixWrong = true
            }
            else {
                prefixWrong = false
            }
            
            if !relevantCommands.contains(where: {$0.command == currentCommand?.command && $0.commandOwner == currentCommand?.commandOwner}){
                currentCommand = nil
            }
            
            if currentCommand != nil {
                do{
                    let matches = try commandInput.matches(of: Regex(currentRegex!))
                    var paramNames: [String] = []
                    
                    for match in matches {
                        let name = commandInput[match.range].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ":", with: "")
                        if paramNames.contains(name) {
                            commandValid = false
                            return
                        }
                        paramNames.append(name)
                    }
                    setParams = paramNames
                    if !setParams.contains(currentParam?.name ?? ""){
                        currentParam = nil
                    }
                } catch let error {
                    print(error)
                }
                return
            }
        }
    }
    
}

extension RoundedRectangle {
    func background(_ param: CommandParameter, current: CommandParameter?, set: [String])-> some View {
        if param == current {
            return self.fill(.blue)
        }
        if set.contains(param.name) {
            return self.fill(Color("Color"))
        }
        return self.fill(.clear)
    }
}

enum CommandParamBackgroundState {
    case selected
    case set
    case none
}

struct CommandPreview: View {
    let command: any Command
    @Binding var currentCommand: (any Command)?
    @Binding var commandInput: String
    
    var body: some View {
        HStack {
            Image("Image")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .padding(.horizontal, 10)
            VStack (alignment: .leading) {
                Text("/ \(command.command)")
                    .font(.subheadline)
                    .bold()
                Text(command.description)
                    .font(.caption)
            }
            Spacer()
        }
        .onTapGesture {
            currentCommand = command
            commandInput = "/\(command.command) "
        }
        .overlay(alignment: .trailing){
            HStack{
                Text(command.commandOwner.uppercased())
                    .padding(3)
                    .bold()
                    .font(.footnote)
                    .background(){
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.thinMaterial)
                    }
            }
            .padding(.horizontal, 5)
            .allowsHitTesting(false)
        }
        
    }
}

class Bababa: Command{
    var id: UUID = UUID()
    
    var command: String = "bababa"
    
    var description: String = "Attaches talking cat to your message"
    
    var parameters: [CommandParameter] = [
        CommandParameter(id: 0, name: "message", description: "Your message", datatype: .string, required: false)
    ]
    
    var minPermissions: Permission = .none
    
    var commandOwner: String = "integrated"
    
    var completion: ([String : Any]) -> Void
    
    init(completion: @escaping ([String : Any]) -> Void) {
        self.completion = completion
    }
}


class Daddy: Command{
    var id: UUID = UUID()
    
    var command: String = "daddy"
    
    var description: String = "daddy"
    
    var parameters: [CommandParameter] = []
    
    var minPermissions: Permission = .none
    
    var commandOwner: String = "integrated"
    
    var completion: ([String : Any]) -> Void
    
    init(completion: @escaping ([String : Any]) -> Void) {
        self.completion = completion
    }
    
}
