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
    @State var currentParams: [String: Range<String.Index>] = [:]
    @State var currentRegex: String? = "( message: )"
    @State var commandValid: Bool = true
    @State var currentCommandLength: Int = 0
    @State var textViewHeight: CGFloat = 100
    
    var body: some View {
        Text("message:")
            .background(currentParams.keys.contains("message") ? .blue : .gray)
        Text(commandDisplay)
        /*TextField("", text: $commandInput)
            .textFieldStyle(.roundedBorder)*/
        CustomTextFieldView(text: $commandInput, currentParams: $currentParams)
            .overlay(){
                RoundedRectangle(cornerRadius: 25.0)
                    .stroke()
            }
            
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

struct CustomTextFieldView: View {
    @Binding var text: String
    @Binding var currentParams: [String: Range<String.Index>]
    @State var height: CGFloat = 25
    var body: some View {
        CustomTextField(text: $text, currentParams: $currentParams, currentHeight: $height)
            .frame(height: min(height, 75))
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


struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var currentParams: [String: Range<String.Index>]
    @Binding var currentHeight: CGFloat
    
    func makeUIView(context: Context) -> UITextView {
        let textField = UITextView()
        textField.delegate = context.coordinator
        textField.isEditable = true
        textField.isSelectable = true
        textField.isUserInteractionEnabled = true
        textField.isScrollEnabled = true
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        return textField
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        CustomTextField.recalculateHeight(view: uiView, result: $currentHeight)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, currentParams: $currentParams)
    }
    
    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height // !! must be called asynchronously
            }
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var currentParams: [String: Range<String.Index>]
        var cursorOffset: Int = 0
        
        init(text: Binding<String>, currentParams: Binding<[String: Range<String.Index>]>) {
            _text = text
            _currentParams = currentParams
        }
        
        func textView(_ textField: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
            // Determine the index of deleted character
            let startIndex = text.startIndex
            let changedIndex = text.index(startIndex, offsetBy: range.location)
            
            cursorOffset = textField.offset(from: textField.beginningOfDocument, to: textField.selectedTextRange!.start)
            
            
            // Update the text binding
            if string.isEmpty {
                var deleted = false
                for param in currentParams {
                    if param.value.contains(changedIndex) {
                        text.removeSubrange(param.value)
                        cursorOffset = text.distance(from: text.startIndex, to: param.value.lowerBound)
                        currentParams.removeValue(forKey: param.key)
                        deleted = true
                    }
                }
                if !deleted {
                    if cursorOffset >= 1 {
                        text.removeSubrange(text.index(text.startIndex, offsetBy: range.lowerBound)...text.index(text.startIndex, offsetBy: range.upperBound - 1))
                    }
                    cursorOffset = max(0, cursorOffset - 1)
                }
                if let newPosition = textField.position(from: textField.beginningOfDocument, offset: cursorOffset){
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                }
            } else {
                // Character added or replaced
                let insertIndex = text.index(startIndex, offsetBy: cursorOffset)
                print(range.location)
                text.insert(contentsOf: string, at: insertIndex)
            }
            
            
            // Return false to let the text field handle the change
            return false
        }
    }
}
