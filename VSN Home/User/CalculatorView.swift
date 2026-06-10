import SwiftUI

struct CalculatorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var displayText = "0"
    @State private var currentOperator: String?
    @State private var storedValue: Double?
    @State private var isEnteringNewNumber = false
    
    let buttons: [[String]] = [
        ["C", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["0", ".", "⌫", "="]
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Business Calculator")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            // Display
            VStack(alignment: .trailing, spacing: 8) {
                Text(displayText)
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 30)
            
            // Keypad
            VStack(spacing: 12) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            CalculatorButton(
                                label: button,
                                color: buttonColor(button),
                                textColor: buttonTextColor(button),
                                action: { handleButtonPress(button) }
                            )
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .background(AppBackground())
    }
    
    private func buttonColor(_ label: String) -> Color {
        if ["C", "±", "%", "⌫"].contains(label) {
            return Color.gray.opacity(0.2)
        } else if ["÷", "×", "−", "+", "="].contains(label) {
            return AppColors.primary
        } else {
            return AppColors.surfaceLight
        }
    }
    
    private func buttonTextColor(_ label: String) -> Color {
        if ["÷", "×", "−", "+", "="].contains(label) {
            return .white
        } else {
            return AppColors.textPrimary
        }
    }
    
    private func handleButtonPress(_ label: String) {
        HapticManager.shared.trigger(.light)
        
        switch label {
        case "0"..."9":
            if displayText == "0" || isEnteringNewNumber {
                displayText = label
                isEnteringNewNumber = false
            } else {
                displayText += label
            }
        case ".":
            if !displayText.contains(".") {
                displayText += "."
            }
        case "C":
            displayText = "0"
            storedValue = nil
            currentOperator = nil
            isEnteringNewNumber = false
        case "±":
            if let value = Double(displayText) {
                displayText = formatResult(-value)
            }
        case "%":
            if let value = Double(displayText) {
                displayText = formatResult(value / 100)
            }
        case "⌫":
            if displayText.count > 1 {
                displayText.removeLast()
            } else {
                displayText = "0"
            }
        case "÷", "×", "−", "+":
            if let value = Double(displayText) {
                storedValue = value
                currentOperator = label
                isEnteringNewNumber = true
            }
        case "=":
            if let op = currentOperator, let stored = storedValue, let current = Double(displayText) {
                var result: Double = 0
                switch op {
                case "+": result = stored + current
                case "−": result = stored - current
                case "×": result = stored * current
                case "÷": result = current != 0 ? stored / current : 0
                default: break
                }
                displayText = formatResult(result)
                storedValue = nil
                currentOperator = nil
                isEnteringNewNumber = true
            }
        default:
            break
        }
    }
    
    private func formatResult(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

struct CalculatorButton: View {
    let label: String
    let color: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(color)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                if label == "⌫" {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(textColor)
                } else {
                    Text(label)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        }
    }
}
